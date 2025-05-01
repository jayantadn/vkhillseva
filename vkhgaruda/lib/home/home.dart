import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/sangeet_seva.dart';
import 'package:vkhgaruda/nitya_seva/nitya_seva.dart';
import 'package:vkhgaruda/widgets/launcher_tile.dart';
import 'package:vkhgaruda/widgets/welcome.dart';
import 'package:vkhpackages/vkhpackages.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    await _lock.synchronized(() async {
      // perform async operations here

      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeGaruda,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Column(
                      children: [
                        // leave some space at top
                        SizedBox(height: 10),

                        // your widgets here
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
                                    image:
                                        'assets/images/LauncherIcons/NityaSeva.png',
                                    title: "Nitya\nSeva",
                                    callback:
                                        LauncherTileCallback(onClick: () async {
                                      bool perm = await Utils()
                                          .checkPermission("Nitya Seva");
                                      if (perm) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const NityaSeva(
                                                      title: "Nitya Seva")),
                                        );
                                      } else {
                                        Toaster().error("Access Denied");
                                      }
                                    })),
                              ),
                              LauncherTile(
                                image:
                                    'assets/images/LauncherIcons/Harinaam.png',
                                title: "Harinaam\nMantapa",
                              ),
                              LauncherTile(
                                  image: 'assets/images/Logo/SangeetSeva.png',
                                  title: "Sangeet\nSeva",
                                  callback:
                                      LauncherTileCallback(onClick: () async {
                                    bool perm = await Utils()
                                        .checkPermission("Sangeet Seva");
                                    if (perm) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SangeetSeva(
                                                  title: "Sangeet Seva",
                                                  splashImage:
                                                      'assets/images/Logo/SangeetSeva.png',
                                                )),
                                      );
                                    } else {
                                      Toaster().error("Access Denied");
                                    }
                                  })),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: LauncherTile(
                                  image:
                                      'assets/images/LauncherIcons/Deepotsava.png',
                                  title: "Karthika\nDeepotsava",
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 100),

                        // leave some space at bottom
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(
              image: "assets/images/Logo/KrishnaLilaPark_circle.png",
            ),
        ],
      ),
    );
  }
}
