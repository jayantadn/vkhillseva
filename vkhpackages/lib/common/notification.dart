import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:vkhpackages/common/toaster.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Notifications {
  static final Notifications _instance = Notifications._internal();

  factory Notifications() {
    return _instance;
  }

  Notifications._internal() {
    // init
  }

  Future<String?> setupFirebaseMessaging() async {
    print("Setting up Firebase Messaging...");
    // Explicitly enable FCM auto-init
    FirebaseMessaging.instance.setAutoInitEnabled(true);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false, // actively asks the user to enable notifications
      sound: true,
    );

    // Get the FCM token
    String? fcmToken;
    if (kIsWeb) {
      fcmToken = await FirebaseMessaging.instance.getToken(
        vapidKey:
            "BN_4zt5SxVFHklPyCjAgba14nCWGI3sJC4x_EZZ4b8LfVAtsabkkIFz4Vqr_uF39Xh_lq7HDLqmHsH0vR1ZYXPc",
      );
    } else {
      // For Apple platforms, ensure the APNS token is available before making any FCM plugin API calls
      if (Platform.isIOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          // APNS token is available, make FCM plugin API requests...
        }
      }

      fcmToken = await FirebaseMessaging.instance.getToken();
    }

    // Listen for FCM token refresh but ignore first call at startup
    bool isFirstRun = true;
    FirebaseMessaging.instance.onTokenRefresh
        .listen((newToken) {
          if (isFirstRun) {
            isFirstRun = false;
            return; // Ignore first token refresh event since we already fetched it
          }
          // Send the updated token to your backend server if needed
        })
        .onError((err) {
          Toaster().error("Error refreshing FCM token: $err");
        });

    // Listen for foreground incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        Toaster().notify(
          header: '${message.notification?.title}',
          body: '${message.notification?.body}',
        );
      }
    });

    // Listen for background incoming messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    return fcmToken;
  }

  Future<String> getFcmToken() async {
    String? fcmToken;
    if (kIsWeb) {
      fcmToken = await FirebaseMessaging.instance.getToken(
        vapidKey:
            "BN_4zt5SxVFHklPyCjAgba14nCWGI3sJC4x_EZZ4b8LfVAtsabkkIFz4Vqr_uF39Xh_lq7HDLqmHsH0vR1ZYXPc",
      );
    } else {
      // For Apple platforms, ensure the APNS token is available before making any FCM plugin API calls
      if (Platform.isIOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          // APNS token is available, make FCM plugin API requests...
        }
      }

      fcmToken = await FirebaseMessaging.instance.getToken();
    }

    return fcmToken ?? "";
  }

  Future<void> sendPushNotification({
    required String fcmToken,
    required title,
    required String body,
    String? imageUrl,
  }) async {
    const String functionUrl =
        "https://us-central1-garuda-1ba07.cloudfunctions.net/sendNotification";

    try {
      final Map<String, dynamic> payload = {
        "fcmToken": fcmToken,
        "title": title,
        "body": body,
      };

      if (imageUrl != null) {
        payload["image"] = imageUrl;
      }

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
      } else {
        Toaster().error("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      Toaster().error("Error sending notification: $e");
    }
  }

  Future<void> sendPushNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    const String functionUrl =
        "https://us-central1-garuda-1ba07.cloudfunctions.net/sendNotificationToTopic";

    try {
      final Map<String, dynamic> payload = {
        "topic": topic,
        "title": title,
        "body": body,
      };

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
      } else {
        Toaster().error("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      Toaster().error("Error sending notification: $e");
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    // do something
  }
}
