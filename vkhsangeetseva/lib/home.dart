import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:vkhsangeetseva/profile.dart';
import 'package:vkhsangeetseva/registration.dart';
import 'package:vkhsangeetseva/widgets/common_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // scalars
  bool _isLoading = true;
  String _username = "";
  final int _maxEvents = 5;
  static bool _isFcmSetup = false;
  String _version = "";

  // lists
  final List<EventRecord> _events = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    FB().listenForChange(
        "${Const().dbrootSangeetSeva}/PendingRequests",
        FBCallbacks(
            add: (data) {},
            edit: () {},
            delete: (deletedData) async {
              await refresh(); // full refresh is required because the index is jumbled
            }));

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _events.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // async operations

    // check for updates
    final packageInfo = await PackageInfo.fromPlatform();
    _version = packageInfo.version;

    // get username from local storage
    await Utils().fetchUserBasics();
    UserBasics? basics = Utils().getUserBasics();

    // set profile if not set
    if (basics != null) {
      Map<String, dynamic> userdetailsMap = await FB().getJson(
          path: "${Const().dbrootSangeetSeva}/Users/${basics.mobile}",
          silent: true);

      if (userdetailsMap.isEmpty || userdetailsMap['name'].isEmpty) {
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
        // profile is already set
        // setup firebase messaging
        // this should be done only once per app startup
        if (_isFcmSetup == false) {
          _isFcmSetup = true;
          await _setupFirebaseMessaging(Utils()
              .convertRawToDatatype(userdetailsMap, UserDetails.fromJson));
        }
      }
    }

    // fetch all events
    if (basics != null) {
      _events.clear();
      List eventsRaw = await FB().getList(
          path: "${Const().dbrootSangeetSeva}/Events/${basics.mobile}");
      for (var eventRaw in eventsRaw) {
        Map<String, dynamic> eventMap = Map<String, dynamic>.from(eventRaw);
        EventRecord event = EventRecord.fromJson(eventMap);
        _events.add(event);
      }
      _events.sort((a, b) => b.date.compareTo(a.date));
    }

    // sync operations
    setState(() {
      _username = Utils().getUsername();
      _isLoading = false;
    });
  }

  Widget _createEventCard(int index) {
    String date = DateFormat("dd MMM yyyy").format(_events[index].date);
    return Card(
        color: _events[index].date.isBefore(DateTime.now())
            ? Colors.grey[200]
            : (_events[index].status == "Pending"
                ? Colors.yellow[50]
                : (_events[index].status == "Approved"
                    ? Colors.green[50]
                    : Colors.red[50])),
        child: ListTile(
          title: Text(
              "$date, ${_events[index].slot.from} - ${_events[index].slot.to}"),
          leading: _events[index].status == "Pending"
              ? Icon(Icons.question_mark)
              : (_events[index].status == "Approved"
                  ? Icon(Icons.check)
                  : Icon(Icons.close)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_events[index].status == "Pending"
                  ? "Waiting for approval"
                  : (_events[index].status == "Approved"
                      ? "Request is approved"
                      : "Request is rejected")),
              if (_events[index].noteTemple.isNotEmpty)
                Text("Temple remarks: ${_events[index].noteTemple}"),
            ],
          ),
          trailing:
              Utils().createContextMenu(["Edit", "Delete"], (String action) {
            // common validations
            if (_events[index].date.isBefore(DateTime.now())) {
              Toaster().error("Cannot edit past events");
              return;
            }

            switch (action) {
              case "Edit":
                // validations
                if (_events[index].status == "Approved") {
                  Toaster().error("Cannot edit approved events");
                  return;
                }
                break;
              case "Delete":
                // handle delete action
                print('Delete action for item $index');
                break;
              case "":
                // nothing to do
                break;
              default:
                Toaster().error('Unknown action for item $index');
                break;
            }
          }),
        ));
  }

  Widget _createWelcome() {
    return Column(children: [
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
              'assets/images/Logo/SangeetSeva.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
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
      Text('Govinda Sangeet Seva',
          style: Theme.of(context).textTheme.headlineLarge),
      if (_version.isNotEmpty)
        Text(
          "version $_version",
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(color: Colors.grey),
        ),
    ]);
  }

  Future<void> _logout() async {
    await LS().delete("userbasics");
    await refresh();

    setState(() {
      _username = "";
    });

    Navigator.pop(context);
  }

  Future<void> _setupFirebaseMessaging(UserDetails details) async {
    String? fcmToken = await Notifications().setupFirebaseMessaging();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      if (fcmToken != details.fcmToken) {
        details.fcmToken = fcmToken;
        Utils().setUserDetails(details);
      }
    }

    // register for FCM token changes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      UserBasics? basics = Utils().getUserBasics();
      if (basics != null) {
        UserDetails? details = await Utils().getUserDetails(basics.mobile);
        if (details != null) {
          details.fcmToken = newToken;
          Utils().setUserDetails(details);
        }
      }
    }).onError((err) {
      Toaster().error("Error refreshing FCM token: $err");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Stack(
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

                        // welcome banner
                        _createWelcome(),

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
                                // auth complete
                                await refresh();
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

                        // registered events
                        SizedBox(
                          height: 10,
                        ),
                        if (_username.isNotEmpty)
                          // clip number of events to display
                          ...List.generate(
                              _events.length > _maxEvents
                                  ? _maxEvents
                                  : _events.length, (index) {
                            return _createEventCard(index);
                          }),

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
