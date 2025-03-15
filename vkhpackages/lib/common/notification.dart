import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:vkhpackages/common/toaster.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> setupFirebaseMessaging() async {
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
      Toaster().info('${message.notification?.body}');
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

  return fcmToken!;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    // do something
  }
}

Future<void> sendPushNotification(
  String fcmToken,
  String title,
  String body,
) async {
  const String functionUrl = "https://sendnotification-26lx7cfwtq-uc.a.run.app";

  try {
    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"fcmToken": fcmToken, "title": title, "body": body}),
    );

    if (response.statusCode == 200) {
      print("Notification sent successfully!");
    } else {
      print("Failed to send notification: ${response.body}");
    }
  } catch (e) {
    print("Error sending notification: $e");
  }
}
