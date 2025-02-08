import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhgaruda/common/theme.dart';
import 'package:vkhgaruda/home/landing.dart';
import 'package:vkhgaruda/nitya_seva/festival.dart';
import 'package:vkhgaruda/nitya_seva/nitya_seva.dart';
import 'package:vkhgaruda/sangeet_seva/profiles.dart';
import 'package:vkhgaruda/sangeet_seva/sangeet_seva.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final Widget home = const Landing(title: "Hare Krishna");
  final Widget test = const SangeetSeva(
    title: "Testing",
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "Garuda", theme: themeDefault, home: test);
  }
}
