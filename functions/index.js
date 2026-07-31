const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const axios = require("axios");

// Initialize Admin SDK
initializeApp();

// Access the API Key from Firebase Secret Manager
// Renamed to avoid conflict with old environment variables
const MAPS_PROXY_KEY = defineSecret("MAPS_PROXY_KEY");

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
    const auth = getAuth();
    const decodedToken = await auth.verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    console.error(`Auth failed: Token verification error: ${error.message}`);
    return null;
  }
}

/**
 * Helper to proxy Google Maps requests with logging
 */
async function proxyGoogleMaps(url, req, res, serviceName) {
  const decodedToken = await validateAuth(req);
  if (!decodedToken) {
    res.status(401).send("Unauthorized");
    return;
  }

  try {
    // We access the secret value using .value()
    const apiKey = MAPS_PROXY_KEY.value();

    if (!apiKey) {
      console.error(`Secret MAPS_PROXY_KEY is not defined in Secret Manager.`);
      res.status(500).send("Configuration Error");
      return;
    }

    const response = await axios.get(url, {
      params: {
        ...req.query,
        key: apiKey,
      },
    });

    if (response.data.status && response.data.status !== "OK" && response.data.status !== "ZERO_RESULTS") {
      console.error(`Google API Error (${serviceName}): ${response.data.status} - ${response.data.error_message || "No message"}`);
    }

    res.status(200).send(response.data);
  } catch (error) {
    console.error(`${serviceName} Proxy Error:`, error.message);
    res.status(500).send(`Internal Proxy Error: ${error.message}`);
  }
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
