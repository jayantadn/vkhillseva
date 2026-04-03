import { setGlobalOptions } from "firebase-functions";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import type { Request, Response } from "express";

setGlobalOptions({ maxInstances: 10 });

admin.initializeApp();

/**
 * Request body contract
 */
interface SendNotificationRequest {
    token: string;
    title: string;
    body: string;
    data?: Record<string, string>;
}

interface SendTopicNotificationRequest {
    topic: string; // e.g. "admins"
    title: string;
    body: string;
    data?: Record<string, string>;
}


/**
 * HTTPS callable function
 */
export const sendNotification = functions.https.onRequest(
    async (req: Request, res: Response) => {
        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }

        const { token, title, body, data }: SendNotificationRequest = req.body;

        if (!token || !title || !body) {
            res.status(400).send("Missing token, title, or body");
            return;
        }

        const message: admin.messaging.Message = {
            token,
            notification: {
                title,
                body,
            },
            ...(data && Object.keys(data).length > 0 ? { data } : {}),
        };

        try {
            const response = await admin.messaging().send(message);
            res.status(200).json({
                success: true,
                messageId: response,
            });
        } catch (error) {
            console.error("FCM send error", error);
            res.status(500).json({
                success: false,
                error: String(error),
            });
        }
    }
);

export const sendTopicNotification = functions.https.onRequest(
    async (req: Request, res: Response) => {
        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }

        const { topic, title, body, data }: SendTopicNotificationRequest = req.body;

        if (!topic || !title || !body) {
            res.status(400).send("Missing topic, title, or body");
            return;
        }

        const message: admin.messaging.Message = {
            topic,
            notification: {
                title,
                body,
            },
            ...(data && Object.keys(data).length > 0 ? { data } : {}),
        };

        try {
            const response = await admin.messaging().send(message);
            res.status(200).json({
                success: true,
                messageId: response,
            });
        } catch (error) {
            console.error("FCM topic send error", error);
            res.status(500).json({
                success: false,
                error: String(error),
            });
        }
    }
);
