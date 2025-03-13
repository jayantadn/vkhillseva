const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Cloud Function to send a notification
exports.sendNotification = functions.https.onRequest(async (req, res) => {
    try {
        // Extract FCM token and message from request body
        const { fcmToken, title, body } = req.body;

        if (!fcmToken || !title || !body) {
            return res.status(400).json({ error: "Missing required fields" });
        }

        // Create the FCM message
        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                id: "1",
                status: "done",
            },
        };

        // Send notification
        await admin.messaging().send(message);

        console.log("Notification sent successfully!");
        return res.status(200).json({ success: true, message: "Notification sent!" });

    } catch (error) {
        console.error("Error sending notification:", error);
        return res.status(500).json({ error: error.message });
    }
});
