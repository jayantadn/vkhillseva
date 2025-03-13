import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhgaruda/home/landing.dart';
import 'package:vkhgaruda/home/notification.dart';
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
