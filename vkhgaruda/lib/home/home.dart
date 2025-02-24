// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:vkhgaruda/sangeet_seva/sangeet_seva.dart';
import 'package:vkhgaruda/nitya_seva/nitya_seva.dart';
import 'package:vkhgaruda/widgets/launcher_tile.dart';
import 'package:vkhgaruda/widgets/welcome.dart';
import 'package:vkhpackages/vkhpackages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  bool _isLoading = true;

  // late FirebaseMessaging _firebaseMessaging;

  @override
  void initState() {
    super.initState();

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
        actions: [],
      ),
      body: Stack(children: [
        Center(
            child: Column(
          children: [
            //welcome message
            Welcome(),

            // row of launchers
            SizedBox(height: 50),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: LauncherTile(
                        image: 'assets/images/LauncherIcons/NityaSeva.png',
                        title: "Nitya\nSeva",
                        callback: LauncherTileCallback(onClick: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const NityaSeva(title: "Nitya Seva")),
                          );
                        })),
                  ),
                  LauncherTile(
                    image: 'assets/images/LauncherIcons/Harinaam.png',
                    title: "Harinaam\nMantapa",
                  ),
                  LauncherTile(
                      image: 'assets/images/Logo/SangeetSeva.png',
                      title: "Sangeet\nSeva",
                      callback: LauncherTileCallback(onClick: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const SangeetSeva(title: "Sangeet Seva")),
                        );
                      })),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: LauncherTile(
                      image: 'assets/images/LauncherIcons/Deepotsava.png',
                      title: "Karthika\nDeepotsava",
                    ),
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
