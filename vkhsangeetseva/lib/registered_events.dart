import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/registration_page2.dart';

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
        DateTime today = DateTime.now();
        today = DateTime(today.year, today.month, today.day);
        if (event.date.isBefore(today)) {
          pastEvents.add(event);
        } else {
          _events.add(event);
        }
      }
    });

    // write past events
    if (pastEvents.isNotEmpty) {
      String year = DateTime.now().year.toString();
      dbpath = "${Const().dbrootSangeetSeva}/PastEvents/$year/${basics.mobile}";
      await FB().addListToList(path: dbpath, list: pastEvents);
    }

    // delete past events from the current database
    // this is done by saving just the future events
    if (_events.isNotEmpty) {
      dbpath = "${Const().dbrootSangeetSeva}/Events/${basics.mobile}";
      await FB().setList(
        path: dbpath,
        list: _events,
        toJson: (e) => e.toJson(),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createEventCard(int index) {
    EventRecord event = _events[index];
    return Widgets().createTopLevelCard(
        context,
        ListTile(
          onTap: () {
            if (event.status == "Approved") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegistrationPage2(
                    selectedDate: event.date,
                    slot: event.slot,
                    title: "Update event",
                    icon: widget.icon,
                    oldEvent: event,
                    readOnly: true,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegistrationPage2(
                    selectedDate: event.date,
                    slot: event.slot,
                    title: "Update event",
                    icon: widget.icon,
                    oldEvent: event,
                  ),
                ),
              );
            }
          },
          leading: Icon(event.status == "Pending"
              ? Icons.question_mark
              : (event.status == "Approved" ? Icons.check : Icons.close)),
          title: Row(
            children: [
              Text(DateFormat("dd MMM, yyyy").format(event.date)),
              const SizedBox(width: 10),
              if (event.noteTemple.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.0),
                    color: Colors.yellow,
                  ),
                  child: Text(
                    "Note",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          subtitle: Widgets().createResponsiveRow(
            context,
            [
              Text(("${event.slot.from} - ${event.slot.to}, ")),
              Text("Request is "),
              Text(
                event.status,
                style: TextStyle(
                  color: event.status == "Approved"
                      ? Colors.green
                      : (event.status == "Rejected"
                          ? Colors.red
                          : Colors.black),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ));
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
                        ...List.generate(_events.length, (index) {
                          return _createEventCard(index);
                        }),
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
