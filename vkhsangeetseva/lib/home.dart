import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/profile.dart';
import 'package:vkhsangeetseva/registered_events.dart';
import 'package:vkhsangeetseva/slot_selection.dart';

class HomePage extends StatefulWidget {
  final String title;
  final String? icon;

  const HomePage({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // global keys
  final GlobalKey<SSWelcomeState> _welcomeKey = GlobalKey<SSWelcomeState>();

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
    UserBasics? basics = Utils().getUserBasics();
    if (basics != null) {
      {
        PerformerProfile? profile =
            await SSUtils().getPerformerProfile(basics.mobile);
        if (profile == null) {
          await Widgets().showMessage(context,
              "No profile found for this mobile. You will be redirected to create a profile.");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Profile(
                title: "Create Profile",
                icon: widget.icon,
                self: true,
              ),
            ),
          );
        }
      }
    }

    // refresh child widgets
    await _welcomeKey.currentState?.refresh();

    await _lock.synchronized(() async {
      // fetch form values

      // perform sync operations here
    });

    setState(() {
      _username = Utils().getUsername();
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await LS().delete("userbasics");
    await refresh();

    setState(() {
      _username = "";
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // profile button
              if (_username.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.person),
                  onPressed: () {
                    Navigator.push(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profile(
                          title: "Profile",
                          self: true,
                        ),
                      ),
                    );
                  },
                ),

              // logout button
              if (_username.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    Widgets().showConfirmDialog(context,
                        "Are you sure to log out?", "Log out", _logout);
                  },
                ),

              // support
              IconButton(
                icon: Icon(Icons.help),
                onPressed: () {
                  Navigator.push(
                    // ignore: use_build_context_synchronously
                    context,
                    MaterialPageRoute(
                      builder: (context) => Support(
                        title: "Support",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
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

                      // welcome banner with signup button
                      Widgets().createTopLevelCard(
                          context: context,
                          child: SSWelcome(
                              key: _welcomeKey, onAuthComplete: refresh)),

                      // event buttons
                      if (_username.isNotEmpty)
                        Widgets().createTopLevelCard(
                          context: context,
                          child: Center(
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
                                          builder: (context) => SlotSelection(
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
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RegisteredEvents(
                                            title: "Registered Events",
                                          ),
                                        ),
                                      );
                                    },
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
                                    onPressed: () {
                                      Toaster()
                                          .error("Feature not available yet");
                                    },
                                    text: 'View past events',
                                    image:
                                        "assets/images/LauncherIcons/PastEvents.png",
                                    context: context,
                                    fixedWidth: 250),
                              ),
                            ]),
                          ),
                        ),

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
            image:
                widget.icon ?? "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
