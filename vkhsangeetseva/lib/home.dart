import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/registration.dart';

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
  String _username = "";

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

    // access control

    // perform async operations here

    // get username from local storage
    await Utils().fetchUserBasics();

    await _lock.synchronized(() async {
      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    setState(() {
      _username = Utils().getUsername();
      _isLoading = false;
    });
  }

  Widget _createWelcome() {
    return Column(children: [
      // image
      Container(
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
            'assets/images/Logo/SangeetSeva.png',
            fit: BoxFit.cover,
          ),
        ),
      ),

      // all text
      SizedBox(
        height: 10,
      ),
      Text(
        'Welcome',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(
        _username.isEmpty ? 'Guest' : _username,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      SizedBox(
        height: 8,
      ),
      Text(
        'ISKCON Vaikuntha Hill',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      Text(
        'Govinda Sangeet Seva',
        style: GoogleFonts.pacifico(
          textStyle: Theme.of(context).textTheme.headlineLarge,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),

      // signup button
      SizedBox(
        height: 10,
      ),
      if (_username.isEmpty)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.deepOrange, // Change the background color here
          ),
          onPressed: () {
            smsAuth(context, () async {
              // auth complete
              await refresh();
            });
          },
          child: Text('Signup / Login'),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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

                      Widgets().createResponsiveTopLevelContainer(context, [
                        // welcome banner with signup button
                        Widgets().createTopLevelCard(context, _createWelcome()),

                        // event buttons
                        if (_username.isNotEmpty)
                          Widgets().createTopLevelCard(
                            context,
                            Center(
                              child: Column(children: [
                                // register event
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Widgets().createImageButton(
                                      context: context,
                                      image:
                                          "assets/images/LauncherIcons/Register.png",
                                      text: "Register for an event",
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Registration(
                                              title: "Event Registration",
                                            ),
                                          ),
                                        );
                                      },
                                      fixedWidth: 250),
                                ),

                                // view registered events
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Widgets().createImageButton(
                                      onPressed: () {},
                                      text: "View registered events",
                                      image:
                                          "assets/images/LauncherIcons/RegisteredEvents.png",
                                      context: context,
                                      imageOnRight: true,
                                      fixedWidth: 250),
                                ),

                                // view past events
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Widgets().createImageButton(
                                      onPressed: () {},
                                      text: 'View past events',
                                      image:
                                          "assets/images/LauncherIcons/PastEvents.png",
                                      context: context,
                                      fixedWidth: 250),
                                ),
                              ]),
                            ),
                          )
                      ]),

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
    );
  }
}
