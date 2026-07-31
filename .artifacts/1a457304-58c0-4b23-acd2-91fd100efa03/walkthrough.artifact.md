# Walkthrough - Unified "One Key" Backend Proxy Architecture

I have implemented your requested "Single Key" architecture. All sensitive data operations (Search, Geocoding, Directions) are now handled exclusively by your Firebase backend, while the map UI uses your provided key for rendering.

## 🔑 Security Architecture

### 1. The Backend (Safe House)
- **[functions/index.js](file:///C:/Users/cetin/Projects/TripBook/functions/index.js)**: Now uses **Firebase Secret Manager** (`defineSecret`).
- The key is **NEVER** written in the code. It is pulled from a secure vault at runtime.
- **Service Name:** All data requests now go to `us-central1-tripbook-68238.cloudfunctions.net`.

### 2. The Frontend (Zero Secret Services)
- **[directions_service.dart](file:///C:/Users/cetin/Projects/TripBook/lib/services/directions_service.dart)**: All platform-specific API key logic has been removed.
- The app no longer "knows" any API keys for retrieving addresses or routes. It simply asks the backend.

### 3. Map Rendering (UI Only)
- **Android**: Updated [build.gradle.kts](file:///C:/Users/cetin/Projects/TripBook/android/app/build.gradle.kts) to use the provided key for map display.
- **Web**: Updated [main.dart](file:///C:/Users/cetin/Projects/TripBook/lib/main.dart) to use the same key for map loading.

---

## 🚀 ACTION REQUIRED: Finalizing the Transition

Please follow these steps exactly to make the app work again:

### Step 1: Set the Backend Secret
Run this in your terminal to tell Firebase which key to use:
```bash
firebase functions:secrets:set GOOGLE_MAPS_API_KEY
```
When prompted, paste your key: `AIzaSyC-wXmwQoc_Dxv_D61zq7ehJOgL_xY92uQ`

### Step 2: Deploy to Firebase
```bash
cd functions
firebase deploy --only functions
```
*(If it asks for permission to access the secret, type **y**)*

### Step 3: Local Cleanup
You can now safely **DELETE** these files from your computer:
1. `assets/.env`
2. `android/secrets.properties`
3. `functions/.env`

---

## 🛡️ Critical: Cloud Console Setup

Since you are using the same key for both backend (unrestricted) and frontend (rendering), you **MUST** ensure the following in [Google Cloud Console](https://console.cloud.google.com/apis/credentials):

1. **Application Restrictions:** Leave as **"None"** (Otherwise the backend will fail).
2. **API Restrictions:** Select **"Restrict key"** and check **ONLY** these:
   - Maps SDK for Android
   - Maps JavaScript API
   - Geocoding API
   - Directions API
   - Places API (New)

This setup is the most professional way to handle Maps keys in a Flutter project.
