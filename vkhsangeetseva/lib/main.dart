import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhsangeetseva/profile.dart';
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

  final Widget home = const HomePage(
    title: "Hare Krishna",
    icon: "assets/images/Logo/SangeetSeva.png",
  );
  // final Widget test = RegistrationPage2(
  //     title: "test",
  //     selectedDate: DateTime.now(),
  //     slot:
  //         Slot(avl: true, from: "10:00 AM", to: "11:00 AM", name: "Test Slot"));
  final Widget test = const Profile(
    title: "test",
    self: true,
  );

  final ThemeData themeSangeetSeva = ThemeCreator(
    primaryColor: Color(0xFF6A0DAD),
  ).create();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sangeet Seva',
      theme: themeSangeetSeva,
      home: test,
    );
  }
}
