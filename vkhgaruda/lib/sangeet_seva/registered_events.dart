import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/request_details.dart';
import 'package:vkhpackages/vkhpackages.dart';

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
  final Map<String, PerformerProfile> _mainPerformers = {};

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
    _mainPerformers.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    // perform async operations here

    // populate events list
    _events.clear();
    _mainPerformers.clear();
    String dbpath = "${Const().dbrootSangeetSeva}/BookedEvents";
    Map<String, dynamic> kvs = await FB()
        .getValuesByDateRange(path: dbpath, startDate: DateTime.now());
    if (kvs.isNotEmpty) {
      for (var kv in kvs.entries) {
        List eventLinksRaw = kv.value;
        for (var eventLinkRaw in eventLinksRaw) {
          var eventRaw = await FB().getValue(path: eventLinkRaw['path']);
          EventRecord event =
              Utils().convertRawToDatatype(eventRaw, EventRecord.fromJson);
          _events.add(event);

          var mainPerformer =
              await SSUtils().getPerformerProfile(event.mainPerformerMobile);
          if (mainPerformer != null) {
            _mainPerformers[mainPerformer.mobile] = mainPerformer;
          }
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

    // refresh all child widgets

    await _lock.synchronized(() async {
      // fetch form values

      // perform sync operations here
    });

    // perform any remaining async operations here

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createEventCard(index) {
    String title = DateFormat("dd MMM, yyyy").format(_events[index].date);
    title += " (${_events[index].slot.from} - ${_events[index].slot.to})";
    String mobile = _events[index].mainPerformerMobile;
    if (_mainPerformers[mobile] == null) {
      Toaster().error("Could not find user");
      return const SizedBox();
    }
    String performer = _mainPerformers[mobile]!.name;
    String profilePicUrl = _mainPerformers[mobile]!.profilePicUrl;

    return Card(
        child: ListTile(
      title: Text(
        title,
      ),
      leading: CircleAvatar(backgroundImage: NetworkImage(profilePicUrl)),
      subtitle: Row(
        children: [
          Icon(Icons.person),
          Text(performer),
          SizedBox(width: 10),
          Icon(Icons.phone),
          Text(mobile),
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

                      Widgets().createTopLevelResponsiveContainer(context, [
                        // your widgets here
                        ...List.generate(_events.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return RequestDetails(
                                  title: "Request Details",
                                  eventRecord: _events[index],
                                );
                              }));
                            },
                            child: _createEventCard(index),
                          );
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
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
