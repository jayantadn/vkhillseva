/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendApprovalNotification = functions.database
    .ref('/SANGEETSEVA_01/PendingRequests')
    .onUpdate(async (change, context) => {
      
        const tokensRef = admin.database().ref('/SANGEETSEVA_01/FCMTokens');
        const tokensSnapshot = await tokensRef.once('value');
        const tokens = tokensSnapshot.val();
        const token = tokens ? Object.values(tokens)[0] : null;

        if (token) {
          const payload = {
            notification: {
              title: 'Registration Approved!',
              body: 'Your registration request has been approved.',
            },
            token: token,
          };

          return admin.messaging().send(payload)
              .then((response) => {
                console.log('Successfully sent message:', response);
                return { success: true };
              })
              .catch((error) => {
                console.log('Error sending message:', error);
                return { error: error };
              });
        } else {
          console.log('No token found for user:', userId);
          return { error: 'No token found' };
        }
      });
      return null;
