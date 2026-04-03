import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/notification_page.dart';
import 'package:vkhsangeetseva/profile.dart';
import 'package:vkhsangeetseva/registered_events.dart';
import 'package:vkhsangeetseva/slot_selection.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // nothing to do here
}

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
  late FirebaseMessaging _firebaseMessaging;
  String _fcmToken = "";
  int _newNotificationCount = 0;

  // lists and maps
  final List<NotificationEntry> _notifications = [];
  final Set _loadedKeys = {};

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    Utils().checkForNewVersion(context, "sangeetseva");

    // setup notifications
    _firebaseMessaging = FirebaseMessaging.instance;
    _firebaseMessaging.requestPermission().then((settings) async {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _fcmToken = await _firebaseMessaging.getToken() ?? "";
      } else {
        _fcmToken = "";
        // Optionally show a message to the user
        print("Notification permission denied");
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // nothing to do
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // on notification clicked
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationPage(
            title: "Notifications",
          ),
        ),
      );
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // database listeners
    Utils().fetchOrGetUserBasics().then(
      (basics) {
        // caveat: for the very first launch of the app, notification counter will not be visible.
        // this is done to keep the code simple
        if (basics != null) {
          String dbpath =
              "${Const().dbrootSangeetSeva}/Notifications/Performers/${basics.mobile}";
          _addListeners(dbpath);
        }
      },
    );

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _notifications.clear();
    _loadedKeys.clear();

    // clear all controllers and focus nodes
    for (var listener in _listeners) {
      listener.cancel();
    }

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
                fcmToken: _fcmToken,
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
      if (basics != null) {
        _notifications.clear();
        String dbpath =
            "${Const().dbrootSangeetSeva}/Notifications/Performers/${basics.mobile}";
        Map<String, dynamic> notificationsRaw =
            await FB().getJson(path: dbpath, silent: true);
        _notifications.addAll(notificationsRaw.entries.map(
          (entry) {
            return Utils()
                .convertRawToDatatype(entry.value, NotificationEntry.fromJson);
          },
        ));

        // filter the list for unread notifications
        _newNotificationCount =
            _notifications.where((notif) => notif.isRead == false).length;
      }

      // perform sync operations here
    });

    setState(() {
      _username = Utils().getUsername();
      _isLoading = false;
    });
  }

  void _addListeners(String dbpath) {
    for (var listener in _listeners) {
      listener.cancel();
    }
    FB().listenForChange(
      dbpath,
      FBCallbacks(
        // add
        add: (data) {
          // workaround to avoid duplicate entries during initial load
          if (_loadedKeys.contains(data['timestamp'])) {
            return;
          }
          _loadedKeys.add(data['timestamp']);

          // process the received data
          setState(() {
            _newNotificationCount++;
          });
        },

        // edit
        edit: () {
          refresh();
        },

        // delete
        delete: (data) async {
          // workaround to avoid duplicate entries during initial load
          if (_loadedKeys.contains(data['timestamp'])) {
            _loadedKeys.remove(data['timestamp']);

            // process the received data
            // nothing to do
          }
        },

        // get listeners
        getListeners: (listeners) {
          _listeners = listeners;
        },
      ),
    );
  }

  Future<void> _logout() async {
    await LS().delete("userbasics");
    await refresh();

    setState(() {
      _username = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveScaffold(
          title: widget.title,
          toolbarActions: [
            // notifications button
            if (_username.isNotEmpty)
              ResponsiveToolbarAction(
                icon: Badge(
                  label: Text('$_newNotificationCount'),
                  isLabelVisible: _newNotificationCount > 0,
                  child: Icon(Icons.notifications),
                ),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationPage(
                        title: "Notifications",
                      ),
                    ),
                  );
                },
              ),

            // profile button
            if (_username.isNotEmpty)
              ResponsiveToolbarAction(
                icon: Icon(Icons.person),
                tooltip: 'Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profile(
                        title: "Profile",
                        self: true,
                        fcmToken: _fcmToken,
                      ),
                    ),
                  );
                },
              ),

            // logout button
            if (_username.isNotEmpty)
              ResponsiveToolbarAction(
                icon: Icon(Icons.logout),
                tooltip: 'Log out',
                onPressed: () async {
                  Widgets().showConfirmDialog(
                      context, "Are you sure to log out?", "Log out", _logout);
                },
              ),

            // support
            ResponsiveToolbarAction(
              icon: Icon(Icons.help),
              tooltip: 'Support',
              onPressed: () {
                Navigator.push(
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
                              // Padding(
                              //   padding: const EdgeInsets.all(8.0),
                              //   child: Widgets().createImageButton(
                              //       onPressed: () {
                              //         Toaster()
                              //             .error("Feature not available yet");
                              //       },
                              //       text: 'View past events',
                              //       image:
                              //           "assets/images/LauncherIcons/PastEvents.png",
                              //       context: context,
                              //       fixedWidth: 250),
                              // ),
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
