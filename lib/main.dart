import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:vkhillseva/home/home.dart';
import 'package:vkhillseva/nitya_seva/nitya_seva.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISKCON VK Hill Seva',
      theme: themeDefault,
      home: const NityaSeva(title: "Nitya Seva"),
      // home: const MyHomePage(title: 'Hare Krishna'),
    );
  }
}
