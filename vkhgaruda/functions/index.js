const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });  // Allow CORS

admin.initializeApp();

// Add your Firebase cloud functions here
