import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhgaruda/common/theme.dart';
import 'package:vkhgaruda/home/landing.dart';
import 'package:vkhgaruda/nitya_seva/festival.dart';
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
  final Widget test = const FestivalRecord(
      title: "Festival record",
      icon: 'assets/images/LauncherIcons/NityaSeva.png');

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "ISKCON VK Hill Seva", theme: themeDefault, home: home);
  }
}
