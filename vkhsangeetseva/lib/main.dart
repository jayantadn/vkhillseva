import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhsangeetseva/registration.dart';
import 'firebase_options.dart';
import 'package:vkhsangeetseva/common/theme.dart';
import 'package:vkhsangeetseva/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final Widget home = const HomePage();
  final Widget test = const Registration(title: "Testing");

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
