const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const axios = require("axios");

// Initialize Admin SDK
initializeApp();
const db = getFirestore();

// Access the API Key from Firebase Secret Manager
// Renamed to avoid conflict with old environment variables
const MAPS_PROXY_KEY = defineSecret("MAPS_PROXY_KEY");

// Simple in-memory rate limiting (per function instance). This is a coarse
// deterrent against abuse (e.g. driving up Maps API costs); it is NOT a full
// DoS defense. Note each instance keeps its own counters.
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const RATE_LIMIT_MAX = 60; // requests per user per window
const rateBuckets = new Map();

function checkRateLimit(uid) {
  const now = Date.now();
  const bucket = rateBuckets.get(uid);
  if (!bucket || now > bucket.resetAt) {
    rateBuckets.set(uid, {count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS});
    return true;
  }
  bucket.count += 1;
  return bucket.count <= RATE_LIMIT_MAX;
}

/**
 * Helper to verify Firebase ID Token from request headers
 */
async function validateAuth(req) {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader) {
    console.error("Auth failed: Missing Authorization header.");
    return null;
  }

  if (!authHeader.startsWith("Bearer ")) {
    console.error("Auth failed: Invalid header format.");
    return null;
  }

  const idToken = authHeader.split("Bearer ")[1];
  try {
    return await getAuth().verifyIdToken(idToken);
  } catch (error) {
    console.error(`Auth failed: Token verification error: ${error.message}`);
    return null;
  }
}

function sendError(res, status, message) {
  res.status(status).send(message);
}

/**
 * Helper to proxy Google Maps requests with logging
 */
async function proxyGoogleMaps(url, req, res, serviceName) {
  const decodedToken = await validateAuth(req);
  if (!decodedToken) {
    sendError(res, 401, "Unauthorized");
    return;
  }

  if (!checkRateLimit(decodedToken.uid)) {
    sendError(res, 429, "Too Many Requests");
    return;
  }

  try {
    const apiKey = MAPS_PROXY_KEY.value();

    if (!apiKey) {
      console.error(`Secret MAPS_PROXY_KEY is not defined in Secret Manager.`);
      sendError(res, 500, "Configuration Error");
      return;
    }

    const response = await axios.get(url, {
      params: {
        ...req.query,
        key: apiKey,
      },
    });

    if (response.data.status && response.data.status !== "OK" && response.data.status !== "ZERO_RESULTS") {
      console.error(`Google API Error (${serviceName}): ${response.data.status}`);
    }

    res.status(200).send(response.data);
  } catch (error) {
    // Do NOT leak internal error details (URLs, key names, etc.) to clients.
    console.error(`${serviceName} Proxy Error:`, error.message);
    sendError(res, 500, "Internal Proxy Error");
  }
}

/**
 * Replicates UserProfile.getPublicDisplayName() so the comment author name
 * respects the user's public-visibility preferences.
 */
function getPublicDisplayName(data) {
  if (!data) return "Anonim";
  const displayNameInPublic = data.displayNameInPublic || "nickname";
  if (displayNameInPublic === "fullName") {
    if (data.showFullNameInPublic !== false &&
        typeof data.fullName === "string" && data.fullName.trim()) {
      return data.fullName.trim();
    }
    const firstName = typeof data.firstName === "string" ? data.firstName.trim() : "";
    const lastName = typeof data.lastName === "string" ? data.lastName.trim() : "";
    if (firstName && lastName) return `${firstName} ${lastName}`;
    if (firstName) return firstName;
    if (lastName) return lastName;
  } else {
    if (data.showNicknameInPublic !== false &&
        typeof data.nickname === "string" && data.nickname.trim()) {
      return data.nickname.trim();
    }
  }
  return "Anonim";
}

// Map the functions to use the secret
const requestOptions = {
  cors: true,
  secrets: [MAPS_PROXY_KEY],
};

exports.getDirections = onRequest(requestOptions, (req, res) => {
  proxyGoogleMaps("https://maps.googleapis.com/maps/api/directions/json", req, res, "Directions");
});

exports.getAutocomplete = onRequest(requestOptions, (req, res) => {
  proxyGoogleMaps("https://maps.googleapis.com/maps/api/place/autocomplete/json", req, res, "Autocomplete");
});

exports.getPlaceDetails = onRequest(requestOptions, (req, res) => {
  proxyGoogleMaps("https://maps.googleapis.com/maps/api/place/details/json", req, res, "PlaceDetails");
});

exports.getGeocode = onRequest(requestOptions, (req, res) => {
  proxyGoogleMaps("https://maps.googleapis.com/maps/api/geocode/json", req, res, "Geocode");
});

/**
 * Atomically upserts a user's rating (1-5) and recomputes the route's average.
 * Ratings are only ever written here (admin SDK), never by clients, so the
 * counter values cannot be forged and concurrent writes cannot corrupt them.
 */
exports.rateRoute = onRequest(requestOptions, async (req, res) => {
  const decodedToken = await validateAuth(req);
  if (!decodedToken) {
    sendError(res, 401, "Unauthorized");
    return;
  }
  if (!checkRateLimit(decodedToken.uid)) {
    sendError(res, 429, "Too Many Requests");
    return;
  }

  const routeId = typeof req.query.routeId === "string" ? req.query.routeId : null;
  const rating = req.query.rating !== undefined ? Number(req.query.rating) : NaN;
  if (!routeId || !Number.isFinite(rating) || rating < 1 || rating > 5) {
    sendError(res, 400, "Bad Request");
    return;
  }

  const uid = decodedToken.uid;
  const routeRef = db.collection("community_routes").doc(routeId);
  const ratingRef = routeRef.collection("ratings").doc(uid);

  try {
    const result = await db.runTransaction(async (txn) => {
      const routeSnap = await txn.get(routeRef);
      if (!routeSnap.exists) {
        throw new Error("NOT_FOUND");
      }

      const ratingsSnap = await txn.get(ratingRef.parent);
      let sum = 0;
      let count = 0;
      ratingsSnap.forEach((doc) => {
        if (doc.id === uid) return; // Will be replaced by the new value below
        const value = doc.data().rating;
        if (typeof value === "number" && Number.isFinite(value)) {
          sum += value;
          count += 1;
        }
      });
      sum += rating;
      count += 1;

      txn.set(ratingRef, {
        rating,
        userId: uid,
        updatedAt: FieldValue.serverTimestamp(),
      });
      txn.update(routeRef, {
        averageRating: sum / count,
        ratingCount: count,
      });

      return {averageRating: sum / count, ratingCount: count};
    });

    res.status(200).send(result);
  } catch (error) {
    if (error.message === "NOT_FOUND") {
      sendError(res, 404, "Route not found");
    } else {
      console.error("rateRoute error:", error.message);
      sendError(res, 500, "Internal Error");
    }
  }
});

async function deleteSubcollection(collectionRef) {
  // Delete in chunks of 500 to stay under Firestore's write-batch limit.
  while (true) {
    const snapshot = await collectionRef.limit(500).get();
    if (snapshot.empty) break;
    const batch = db.batch();
    snapshot.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }
}

/**
 * Removes a community route plus its comments/ratings subcollections.
 * Runs as admin (bypasses rules) so it can clean up other users' comments and
 * ratings that a client would not be allowed to delete directly.
 */
exports.unshareRoute = onRequest(requestOptions, async (req, res) => {
  const decodedToken = await validateAuth(req);
  if (!decodedToken) {
    sendError(res, 401, "Unauthorized");
    return;
  }
  if (!checkRateLimit(decodedToken.uid)) {
    sendError(res, 429, "Too Many Requests");
    return;
  }

  const routeId = typeof req.query.routeId === "string" ? req.query.routeId : null;
  if (!routeId) {
    sendError(res, 400, "Bad Request");
    return;
  }

  const routeRef = db.collection("community_routes").doc(routeId);
  try {
    const routeSnap = await routeRef.get();
    if (!routeSnap.exists) {
      sendError(res, 404, "Route not found");
      return;
    }
    if (routeSnap.data().sharedBy !== decodedToken.uid) {
      sendError(res, 403, "Forbidden");
      return;
    }

    await deleteSubcollection(routeRef.collection("comments"));
    await deleteSubcollection(routeRef.collection("ratings"));
    await routeRef.delete();

    res.status(200).send({success: true});
  } catch (error) {
    console.error("unshareRoute error:", error.message);
    sendError(res, 500, "Internal Error");
  }
});

/**
 * Creates a comment and atomically increments commentCount.
 * Server-side validation + sanitization; only this function may create comments.
 */
exports.addComment = onRequest(requestOptions, async (req, res) => {
  const decodedToken = await validateAuth(req);
  if (!decodedToken) {
    sendError(res, 401, "Unauthorized");
    return;
  }
  if (!checkRateLimit(decodedToken.uid)) {
    sendError(res, 429, "Too Many Requests");
    return;
  }

  const routeId = typeof req.query.routeId === "string" ? req.query.routeId : null;
  const comment = typeof req.query.comment === "string" ? req.query.comment.trim() : "";
  if (!routeId || comment.length === 0 || comment.length > 1000) {
    sendError(res, 400, "Bad Request");
    return;
  }
  if (/[<>]/.test(comment)) {
    sendError(res, 400, "Invalid comment");
    return;
  }

  const uid = decodedToken.uid;
  const routeRef = db.collection("community_routes").doc(routeId);

  let userName = "Anonim";
  try {
    const profileSnap = await db.collection("users").doc(uid).get();
    if (profileSnap.exists) {
      userName = getPublicDisplayName(profileSnap.data());
    }
  } catch (error) {
    console.error("Failed to load profile name:", error.message);
  }

  try {
    await db.runTransaction(async (txn) => {
      const routeSnap = await txn.get(routeRef);
      if (!routeSnap.exists) {
        throw new Error("NOT_FOUND");
      }
      const commentRef = routeRef.collection("comments").doc();
      txn.set(commentRef, {
        userId: uid,
        userName,
        comment,
        timestamp: FieldValue.serverTimestamp(),
      });
      txn.update(routeRef, {
        commentCount: FieldValue.increment(1),
      });
    });

    res.status(200).send({success: true});
  } catch (error) {
    if (error.message === "NOT_FOUND") {
      sendError(res, 404, "Route not found");
    } else {
      console.error("addComment error:", error.message);
      sendError(res, 500, "Internal Error");
    }
  }
});
