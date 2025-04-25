import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class RegisteredEvents extends StatefulWidget {
  final String title;
  final String? icon;

  const RegisteredEvents({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _RegisteredEventsState createState() => _RegisteredEventsState();
}

class _RegisteredEventsState extends State<RegisteredEvents> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists
  final List<EventRecord> _events = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

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

    // access control

    // perform async operations here
    await Utils().fetchUserBasics();
    UserBasics? basics = Utils().getUserBasics();
    if (basics == null) {
      Toaster().error("Could not fetch user info");
      return;
    }
    String dbpath = "${Const().dbrootSangeetSeva}/Events/${basics.mobile}";
    List eventsRaw = await FB().getList(path: dbpath);
    _events.clear();
    List<EventRecord> pastEvents = [];

    await _lock.synchronized(() async {
      // fetch form values

      // refresh all child widgets

      // perform sync operations here

      // populate events
      for (var eventRaw in eventsRaw) {
        EventRecord event =
            Utils().convertRawToDatatype(eventRaw, EventRecord.fromJson);
        if (event.date.isBefore(DateTime.now())) {
          pastEvents.add(event);
        } else {
          _events.add(event);
        }
      }
    });

    // Spawn a thread to write pastEvents in the database

    // write past events
    String year = DateTime.now().year.toString();
    dbpath = "${Const().dbrootSangeetSeva}/PastEvents/$year/${basics.mobile}";
    await FB().addListToList(path: dbpath, list: pastEvents);

    // delete past events from the current database
    dbpath = "${Const().dbrootSangeetSeva}/Events/${basics.mobile}";
    await FB().setValue(path: dbpath, value: _events);

    setState(() {
      _isLoading = false;
    });
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
                        // your widgets here
                        Widgets().createTopLevelCard(
                          context,
                          ListTile(
                            title: Text("Hello World"),
                            subtitle: Text("This is a sample card"),
                          ),
                        ),
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
            image:
                widget.icon ?? "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
