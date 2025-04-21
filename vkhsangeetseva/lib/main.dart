import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhsangeetseva/landing.dart';
import 'package:vkhsangeetseva/registration_page2.dart';
import 'package:vkhsangeetseva/theme_new.dart';
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

  final Widget home = const HomePage(title: "Hare Krishna");
  final Widget test = RegistrationPage2(
    title: "test",
    selectedDate: DateTime.now(),
    slot: Slot(name: "name", avl: true, from: "10:00 AM", to: "12:00 PM"),
  );

  ThemeData themeSangeetSeva = createTheme(
    primaryColor: Colors.black,
    secondaryColor: Colors.green,
    scaffoldBackgroundColor: Colors.grey[100]!,
    secondaryBackgroundColor: Colors.white,
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sangeet Seva',
      theme: themeSangeetSeva,
      home: LandingPage(title: "Sangeet Seva"),
    );
  }
}
