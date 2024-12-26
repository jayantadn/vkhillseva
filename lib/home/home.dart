import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/home/settings.dart';
import 'package:vkhillseva/nitya_seva/nitya_seva.dart';
import 'package:vkhillseva/widgets/launcher_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  bool _isLoading = true;

  late FirebaseMessaging _firebaseMessaging;

  @override
  void initState() {
    super.initState();

    // initialize firebase messaging
    _firebaseMessaging = FirebaseMessaging.instance;
    _firebaseMessaging.requestPermission();
    _firebaseMessaging.getToken().then((token) {
      // print("FCM Token: $token");
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message received: ${message.notification?.title}");
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message clicked: ${message.notification?.title}");
    });
    FirebaseMessaging.onBackgroundMessage((message) async {
      print("Message in background: ${message.notification?.title}");
      return Future<void>.value();
    });

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Settings(title: 'Settings')),
              );
            },
          ),
        ],
      ),
      body: Stack(children: [
        Center(
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Logo/KrishnaLilaPark_circle.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Text(
              'Welcome',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              'Guest',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              'ISKCON Vaikuntha Hill',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text('Seva App v${Const().version}',
                style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 50),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  LauncherTile(
                      image: 'assets/images/LauncherIcons/NityaSeva.png',
                      title: "Nitya Seva",
                      callback: LauncherTileCallback(onClick: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const NityaSeva(title: "Nitya Seva")),
                        );
                      })),
                  LauncherTile(
                    image: 'assets/images/LauncherIcons/Harinaam.png',
                    title: "Harinaam",
                  ),
                  LauncherTile(
                    image: 'assets/images/LauncherIcons/Deepotsava.png',
                    title: "Deepotsava",
                  ),
                ],
              ),
            )
          ],
        )),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(image: 'assets/images/Logo/KrishnaLilaPark_square.png')
      ]),
    );
  }
}
