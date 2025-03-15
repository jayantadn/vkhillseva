const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });  // Allow CORS

admin.initializeApp();

exports.sendNotification = functions.https.onRequest((req, res) => {
    
    
    cors(req, res, async () => {  // Enable CORS
        try {
            const { fcmToken, title, body, image } = req.body;

            if (!fcmToken || !title || !body) {
                return res.status(400).json({ error: "Missing required fields" });
            }

            console.log(`Sending notification: ${body}`);

            const message = {
                token: fcmToken,
                notification: {
                    title: title,
                    body: body,
                    image: image || undefined, 
                },
                webpush: {
                    notification: {
                        icon: image
                    },
                },
                android: {
                    notification: {
                        image: image || undefined,
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            "mutable-content": 1, 
                        },
                    },
                    fcm_options: {
                        image: image || undefined,
                    },
                },
            };

            await admin.messaging().send(message);
            return res.status(200).json({ success: true, message: "Notification sent!" });

        } catch (error) {
            return res.status(500).json({ error: error.message });
        }
    });
});
