import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhsangeetseva/registration.dart';
import 'package:vkhsangeetseva/registration_page2.dart';
import 'firebase_options.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setupFirebaseMessagingSS();

  runApp(MyApp());
}

Future<void> setupFirebaseMessagingSS() async {
  // set FCM token
  UserBasics? basics = Utils().getUserBasics();
  if (basics != null) {
    UserDetails? details = await Utils().getUserDetails(basics.mobile);
    if (details != null) {
      // set the FCM token
      String? fcmToken = await setupFirebaseMessaging();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        if (fcmToken != details.fcmToken) {
          details.fcmToken = fcmToken;
          Utils().setUserDetails(details);
        }
      }
    }
  }

  // register for FCM token changes
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    UserBasics? basics = Utils().getUserBasics();
    if (basics != null) {
      UserDetails? details = await Utils().getUserDetails(basics.mobile);
      if (details != null) {
        details.fcmToken = newToken;
        Utils().setUserDetails(details);
      }
    }
  }).onError((err) {
    Toaster().error("Error refreshing FCM token: $err");
  });
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Widget home = const HomePage();
  final Widget test = RegistrationPage2(
      title: "Testing",
      selectedDate: DateTime.now(),
      slot: Slot(
          avl: true, from: "10:00 AM", to: "01:00 PM", name: "Morning Slot"));

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sangeet Seva',
      theme: themeDefault,
      home: home,
    );
  }
}
