import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:vkhillseva/home/pin_page.dart';
import 'package:vkhillseva/nitya_seva/laddu/laddu.dart';
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

  final Widget home = const PinPage(title: "Hare Krishna");
  final Widget test = const LadduMain();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "ISKCON VK Hill Seva", theme: themeDefault, home: home);
  }
}
