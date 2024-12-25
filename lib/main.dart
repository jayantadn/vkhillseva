import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:vkhillseva/common/toaster.dart';
import 'package:vkhillseva/home/home.dart';
import 'package:vkhillseva/nitya_seva/nitya_seva.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
}

void _requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // nothing to do
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    Toaster().error('User granted provisional permission');
  } else {
    Toaster().error('User declined or has not accepted permission');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  _requestPermission();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Widget home = const HomePage(title: "Hare Krishna");
  final Widget test = NityaSeva(title: "testing");
  // final Widget test = TicketPage(
  //     session: Session(
  //         name: "Morning Nitya Seva",
  //         defaultAmount: 400,
  //         defaultPaymentMode: "UPI",
  //         icon: "assets/images/Common/morning.png",
  //         sevakarta: "Guest",
  //         timestamp: DateTime.parse("2024-12-24T12:21:18.348")));

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "ISKCON VK Hill Seva", theme: themeDefault, home: home);
  }
}
