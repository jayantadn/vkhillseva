import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhgaruda/home/landing.dart';
import 'package:vkhgaruda/sangeet_seva/pending_requests.dart';
import 'package:vkhgaruda/sangeet_seva/sangeet_seva.dart';
import 'firebase_options.dart';
import 'package:vkhpackages/vkhpackages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setupFirebaseMessaging();

  runApp(MyApp());
}

Future<void> setupFirebaseMessaging() async {
  // Explicitly enable FCM auto-init
  FirebaseMessaging.instance.setAutoInitEnabled(true);

  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false, // actively asks the user to enable notifications
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

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
  print("FCM Token: $fcmToken");

  // Listen for FCM token refresh but ignore first call at startup
  bool isFirstRun = true;
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    if (isFirstRun) {
      isFirstRun = false;
      return; // Ignore first token refresh event since we already fetched it
    }
    print("Updated FCM Token: $newToken");
    // Send the updated token to your backend server if needed
  }).onError((err) {
    Toaster().error("Error refreshing FCM token: $err");
  });

  // Listen for foreground incoming messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      Toaster().info('${message.notification?.body}');
    }
  });

  // Listen for background incoming messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    print('Background Notification body: ${message.notification?.body}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final Widget home = const Landing(title: "Hare Krishna");
  final Widget test = const PendingRequests(title: "testing");

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garuda',
      theme: themeDefault,
      home: home,
    );
  }
}
