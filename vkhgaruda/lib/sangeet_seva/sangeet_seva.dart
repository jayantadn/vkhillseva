import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/calendar_slots.dart';
import 'package:vkhgaruda/sangeet_seva/pending_requests.dart';
import 'package:vkhgaruda/sangeet_seva/profiles.dart';
import 'package:vkhpackages/vkhpackages.dart';

class SangeetSeva extends StatefulWidget {
  final String title;
  final String? splashImagePath;

  const SangeetSeva({super.key, required this.title, this.splashImagePath});

  @override
  // ignore: library_private_types_in_public_api
  _SangeetSevaState createState() => _SangeetSevaState();
}

class _SangeetSevaState extends State<SangeetSeva> {
  // global keys
  final GlobalKey<CalendarState> _calendarKey = GlobalKey<CalendarState>();

  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  int _pendingRequests = 0;
  DateTime _lastCallbackInvoked = DateTime.now();

  // lists

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    // listen to database events
    FB().listenForChange(
        "${Const().dbrootSangeetSeva}/PendingRequests",
        FBCallbacks(
          // add
          add: (data) {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();
            }

            // process the received data
            _incrementPendingRequests();
          },

          // edit
          edit: () {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              refresh();
            }
          },

          // delete
          delete: (data) async {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              // process the received data
              _decrementPendingRequests();

              var eventRaw = await FB().getValue(path: data['path']);
              EventRecord event =
                  Utils().convertRawToDatatype(eventRaw, EventRecord.fromJson);
              if (mounted) {
                _calendarKey.currentState!
                    .fillAvailabilityIndicators(date: event.date);
              }
            }
          },

          // get listeners
          getListeners: (listeners) {
            _listeners = listeners;
          },
        ));

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes
    for (var element in _listeners) {
      element.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    // perform async operations here
    _pendingRequests = await _getPendingRequestsCount();

    await _lock.synchronized(() async {
      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    // perform any remaining async operations here

    setState(() {
      _isLoading = false;
    });
  }

  void _decrementPendingRequests() {
    setState(() {
      _pendingRequests--;
    });
  }

  Future<int> _getPendingRequestsCount() async {
    List<dynamic> pendingRequestsRaw = await FB()
        .getList(path: "${Const().dbrootSangeetSeva}/PendingRequests");
    return pendingRequestsRaw.length;
  }

  void _incrementPendingRequests() {
    setState(() {
      _pendingRequests++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // registered users
              IconButton(
                icon: Icon(Icons.group),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profiles(
                        title: 'Performer Profiles',
                        icon: widget.splashImagePath,
                      ),
                    ),
                  );
                },
              ),

              // calendar
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarSlots(
                        title: "Sangeet seva",
                        icon: widget.splashImagePath,
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

                      Widgets().createResponsiveTopLevelContainer(context, [
                        // your widgets here

                        // welcome banner
                        Widgets().createTopLevelCard(context, SSWelcome()),

                        Widgets().createTopLevelCard(
                            context,
                            Center(
                                child: Column(children: [
                              // register event
                              Stack(children: [
                                // button
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Widgets().createImageButton(
                                      context: context,
                                      image:
                                          "assets/images/LauncherIcons/Register.png",
                                      text: "View pending requests",
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PendingRequests(
                                              title: "Pending requests",
                                            ),
                                          ),
                                        );
                                      },
                                      fixedWidth: 250),
                                ),

                                // count
                                if (_pendingRequests > 0)
                                  Positioned(
                                    left: 10,
                                    top: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(
                                        //     builder: (context) =>
                                        //         PendingRequests(
                                        //       title: 'Pending requests',
                                        //       icon: widget.icon,
                                        //     ),
                                        //   ),
                                        // );
                                      },
                                      child: Container(
                                        padding:
                                            EdgeInsets.only(left: 4, right: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 10,
                                          minHeight: 10,
                                        ),
                                        child: Text(
                                          '$_pendingRequests',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  )
                              ]),

                              // view registered events
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Widgets().createImageButton(
                                    onPressed: () {
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) => RegisteredEvents(
                                      //         title: "Registered Events",
                                      //         icon: widget.icon),
                                      //   ),
                                      // );
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
                                    onPressed: () {},
                                    text: 'View past events',
                                    image:
                                        "assets/images/LauncherIcons/PastEvents.png",
                                    context: context,
                                    fixedWidth: 250),
                              ),
                            ])))
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
            image: widget.splashImagePath ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
