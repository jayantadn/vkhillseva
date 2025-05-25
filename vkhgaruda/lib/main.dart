import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhgaruda/home/landing.dart';
import 'package:vkhgaruda/home/user_management.dart';
import 'firebase_options.dart';
import 'package:vkhpackages/vkhpackages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!kIsWeb) {
      Toaster().error("Error initializing Firebase: $e");
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final Widget home = const Landing(title: "Hare Krishna");
  final Widget test = const UserManagement(
    title: "Testing",
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garuda',
      theme: themeGaruda,
      home: home,
    );
  }
}
