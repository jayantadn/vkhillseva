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

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendApprovalNotification = functions.firestore
    .document('registrations/{registrationId}')
    .onUpdate(async (change, context) => {
      const newValue = change.after.data();
      const previousValue = change.before.data();

      if (newValue.status === 'approved' && previousValue.status !== 'approved') {
        const userId = newValue.userId;
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        const user = userDoc.data();
        const token = user.fcmToken;

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
      }
      return null;
    });
