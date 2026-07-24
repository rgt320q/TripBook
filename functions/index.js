const {onRequest} = require("firebase-functions/v2/https");
const {defineString} = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const GOOGLE_MAPS_API_KEY = defineString("GOOGLE_MAPS_API_KEY");

/**
 * Helper to verify Firebase ID Token from request headers
 */
async function validateAuth(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return null;
  }
  const idToken = authHeader.split("Bearer ")[1];
  try {
    return await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    console.error("Auth verification failed:", error);
    return null;
  }
}

exports.getDirections = onRequest({cors: true}, async (req, res) => {
  // SECURITY: Verify user identity before processing expensive API calls
  const decodedToken = await validateAuth(req);
  if (!decodedToken) {
    res.status(401).send("Unauthorized: Authentication required.");
    return;
  }

  const {origin, destination} = req.query;
  if (!origin || !destination) {
    res.status(400).send("Missing 'origin' or 'destination' query parameters.");
    return;
  }

  const url = "https://maps.googleapis.com/maps/api/directions/json";

  try {
    const response = await axios.get(url, {
      params: {
        ...req.query,
        key: GOOGLE_MAPS_API_KEY.value(),
      },
    });

    res.status(200).send(response.data);
  } catch (error) {
    console.error("Error calling Google Directions API:", error.response ? error.response.data : error.message);
    if (error.response) {
      res.status(error.response.status).send(error.response.data);
    } else {
      res.status(500).send("Internal Server Error");
    }
  }
});
