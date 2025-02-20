import 'package:flutter/material.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/common/local_storage.dart';
import 'package:vkhsangeetseva/events.dart';
import 'package:vkhsangeetseva/profile.dart';
import 'package:vkhsangeetseva/registration.dart';
import 'package:vkhsangeetseva/widgets/auth.dart';
import 'package:vkhsangeetseva/common/utils.dart';
import 'package:vkhsangeetseva/widgets/common_widgets.dart';
import 'package:vkhsangeetseva/widgets/loading_overlay.dart';
import 'package:vkhsangeetseva/widgets/welcome.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  bool _isLoading = true;
  String _username = "";

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
    // async operations
    // get username from local storage
    await Utils().fetchUserBasics();

    // refresh all child widgets
    if (welcomeKey.currentState != null) {
      await welcomeKey.currentState!.refresh();
    }
    if (eventsKey.currentState != null) await eventsKey.currentState!.refresh();

    // sync operations
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Hare Krishna'),
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
                CommonWidgets().confirm(
                    context: context,
                    msg: "Are you sure you want to logout?",
                    callbacks: ConfirmationCallbacks(
                        onConfirm: _logout,
                        onCancel: () {
                          Navigator.pop(context);
                        }));
              },
            ),
        ],
      ),
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: refresh,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // welcome banner
                  Welcome(key: welcomeKey),

                  SizedBox(
                    height: 10,
                  ),

                  // sms authentication
                  if (_username.isEmpty)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .deepOrange, // Change the background color here
                      ),
                      onPressed: () {
                        smsAuth(context, () async {
                          // get the user details
                          await Utils().fetchUserBasics();
                          UserBasics? basics = Utils().getUserBasics();
                          if (basics != null) {
                            Map<String, dynamic> userdetailsMap = await FB()
                                .getJson(
                                    path: "Users/${basics.mobile}",
                                    silent: true);

                            if (userdetailsMap['name'].isEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Profile(
                                    title: "Profile",
                                    self: true,
                                  ),
                                ),
                              );
                            } else {
                              await refresh();
                            }
                          }

                          refresh();
                        });
                      },
                      child: Text('Signup / Login'),
                    ),

                  // register for events
                  if (_username.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (context) => Registration(
                              title: "Event Registration",
                            ),
                          ),
                        );
                      },
                      child: Text('Register for an Event'),
                    ),

                  // view registered events
                  SizedBox(
                    height: 10,
                  ),
                  if (_username.isNotEmpty) Events(key: eventsKey),
                ],
              ),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(image: 'assets/images/Logo/SangeetSeva.png'),

        // version number at top right corner
        Positioned(
          top: 10,
          right: 10,
          child: Text(
            "v${Const().version}",
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Colors.grey),
          ),
        ),
      ]),
    );
  }
}
