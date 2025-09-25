const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const cors = require("cors")({origin: true});

admin.initializeApp();

// IMPORTANT: For production, it's highly recommended to store your API key in a secure way,
// for example, using Firebase environment variables:
// firebase functions:config:set google.maps_api_key="YOUR_API_KEY"
// Then, you can access it like this: functions.config().google.maps_api_key
const GOOGLE_MAPS_API_KEY = "AIzaSyCFQGLeeVXkaI7WzVzOqe9KVZLHR7Sd_B8";

exports.getDirections = functions.https.onRequest((req, res) => {
  // Use the cors middleware to automatically handle CORS preflight requests
  cors(req, res, async () => {
    // Check for required query parameters
    const {origin, destination} = req.query;
    if (!origin || !destination) {
      res.status(400).send("Missing 'origin' or 'destination' query parameters.");
      return;
    }

    // Build the Google Directions API URL
    const url = `https://maps.googleapis.com/maps/api/directions/json`;

    try {
      const response = await axios.get(url, {
        params: {
          ...req.query, // Pass all original query params
          key: GOOGLE_MAPS_API_KEY,
        },
      });

      // Send the response from Google Maps API back to the client
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
});
