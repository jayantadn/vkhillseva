import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/profile.dart';
import 'package:vkhsangeetseva/registration.dart';
import 'package:vkhsangeetseva/version.dart';
import 'package:vkhsangeetseva/widgets/common_widgets.dart';
import 'package:vkhsangeetseva/widgets/welcome.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  // scalars
  bool _isLoading = true;
  String _username = "";

  // lists
  List<EventRecord> _events = [];

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _events.clear();

    // clear all controllers

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // async operations

    // get username from local storage
    await Utils().fetchUserBasics();
    UserBasics? basics = Utils().getUserBasics();

    // set profile if not set
    if (basics != null) {
      Map<String, dynamic> userdetailsMap =
          await FB().getJson(path: "Users/${basics.mobile}", silent: true);

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
      }
    }

    // fetch all events
    if (basics != null) {
      List eventsRaw = await FB().getList(path: "Events/${basics.mobile}");
      for (var eventRaw in eventsRaw) {
        Map<String, dynamic> eventMap = Map<String, dynamic>.from(eventRaw);
        EventRecord event = EventRecord.fromJson(eventMap);
        _events.add(event);
      }
      _events.sort((a, b) => b.date.compareTo(a.date));
      if (_events.length > 10) {
        _events = _events.sublist(0, 10);
      }
    }

    // refresh all child widgets
    if (welcomeKey.currentState != null) {
      await welcomeKey.currentState!.refresh();
    }

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

                  // view registered events
                  SizedBox(
                    height: 10,
                  ),
                  if (_username.isNotEmpty)
                    ...List.generate(_events.length, (index) {
                      String date =
                          DateFormat("dd MMM yyyy").format(_events[index].date);
                      String performers = _events[index].mainPerformer.name;
                      for (UserDetails performer
                          in _events[index].supportTeam) {
                        performers += ", ${performer.name}";
                      }

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
                                    : Icon(Icons.cancel)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Performers: $performers"),
                                if (_events[index].noteTemple.isNotEmpty)
                                  Text(
                                      "Temple remarks: ${_events[index].noteTemple}"),
                              ],
                            )),
                      );
                    }),
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
            "v$version",
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
