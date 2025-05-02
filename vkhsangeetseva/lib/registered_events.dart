import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/registration_page2.dart';

class RegisteredEvents extends StatefulWidget {
  final String title;
  final String? splashImage;

  const RegisteredEvents({super.key, required this.title, this.splashImage});

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

    await _lock.synchronized(() async {
      // fetch user basic data
      await Utils().fetchUserBasics();
      UserBasics? userBasics = Utils().getUserBasics();
      if (userBasics == null) {
        Toaster().error(
          "Unable to fetch user data.",
        );
        return;
      }

      // populate registered events list
      _events.clear();
      String dbpath =
          "${Const().dbrootSangeetSeva}/Events/${userBasics.mobile}";
      var kvs = await FB()
          .getValuesByDateRange(path: dbpath, startDate: DateTime.now());
      if (kvs.isNotEmpty) {
        for (var kv in kvs.entries) {
          var eventsRaw = kv.value;
          for (var eventMap in eventsRaw.entries) {
            var eventRaw = eventMap.value;
            EventRecord event =
                Utils().convertRawToDatatype(eventRaw, EventRecord.fromJson);
            _events.add(event);
          }
        }
      }

      // sort events by date
      _events.sort((a, b) {
        if (a.date.isBefore(b.date)) {
          return -1;
        } else if (a.date.isAfter(b.date)) {
          return 1;
        } else {
          return 0;
        }
      });
    });

    // perform any remaining async operations here

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createEventCard(int index) {
    String title = DateFormat("dd MMM, yyyy").format(_events[index].date);
    title += " (${_events[index].slot.from} - ${_events[index].slot.to})";

    EventRecord event = _events[index];

    return Card(
      child: ListTile(
        onTap: () {
          if (event.status == "Approved") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegistrationPage2(
                  selectedDate: event.date,
                  slot: event.slot,
                  title: "Update event",
                  icon: widget.splashImage,
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
                  icon: widget.splashImage,
                  oldEvent: event,
                ),
              ),
            );
          }
        },
        title: Text(
          title,
        ),
        leading: Icon(event.status == "Approved"
            ? Icons.check_circle
            : event.status == "Pending"
                ? Icons.pending
                : Icons.cancel),
        subtitle: Widgets().createResponsiveRow(
          context,
          [
            Text("Status: "),
            Text(
              event.status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: event.status == "Approved"
                    ? Colors.green
                    : event.status == "Pending"
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
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

                      Widgets().createTopLevelResponsiveContainer(context, [
                        // your widgets here
                        ...List.generate(_events.length, (index) {
                          return _createEventCard(index);
                        }),
                      ]),

                      // empty message
                      if (_events.isEmpty)
                        Center(
                          child: Text("No events found"),
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
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
