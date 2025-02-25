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

  runApp(MyApp());
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
      title: 'Hare Krishna',
      theme: themeDefault,
      home: home,
    );
  }
}
