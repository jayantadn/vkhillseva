import 'package:flutter/foundation.dart' hide Summary;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vkhgaruda/deepotsava/accounting/accounting.dart';
import 'package:vkhgaruda/home/landing.dart';
import 'firebase_options.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (!kIsWeb) {
      Toaster().error("Error loading .env file: $e");
    }
  }

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
  MyApp({super.key});

  final Widget home = const Landing(title: "Hare Krishna");
  final Widget test = Accounting(title: "Accounting");

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
