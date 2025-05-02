import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/request_details.dart';
import 'package:vkhpackages/vkhpackages.dart';

class PendingRequests extends StatefulWidget {
  final String title;
  final String? icon;

  const PendingRequests({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _PendingRequestsState createState() => _PendingRequestsState();
}

class _PendingRequestsState extends State<PendingRequests> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _lastCallbackInvoked = DateTime.now();

  // lists
  final List<EventRecord> _linkedEventRecords = [];
  final Map<String, PerformerProfile> _mainPerformers = {};

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    // listen for changes in the database
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
            // directly refreshing, because there are two lists involved, which is difficult to manage
            refresh();
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
              // directly refreshing, because there are two lists involved, which is difficult to manage
              refresh();
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
    _linkedEventRecords.clear();

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

    // perform async operations here

    await _lock.synchronized(() async {
      // fetch pending requests
      _linkedEventRecords.clear();
      List<Map<String, dynamic>> pendingRequests = [];
      List<dynamic> pendingRequestLinks = await FB()
          .getList(path: "${Const().dbrootSangeetSeva}/PendingRequests");
      for (var pendingRequestLinkRaw in pendingRequestLinks) {
        Map<String, dynamic> pendingRequestLink =
            Map<String, dynamic>.from(pendingRequestLinkRaw);
        String path = pendingRequestLink['path'];

        var pendingRequestPerUserRaw = await FB().getValue(path: path);
        EventRecord pendingRequest = Utils().convertRawToDatatype(
            pendingRequestPerUserRaw, EventRecord.fromJson);

        // discard if pending request is in the past
        if (pendingRequest.date.isAfter(DateTime.now())) {
          pendingRequests.add({'path': path});
          _linkedEventRecords.add(pendingRequest);
        }
      }
      if (pendingRequests.length != pendingRequestLinks.length) {
        // outdated requests detected
        await FB().setValue(
            path: "${Const().dbrootSangeetSeva}/PendingRequests",
            value: pendingRequests);
      }

      // fetch main performers

      for (EventRecord pendingRequest in _linkedEventRecords) {
        PerformerProfile? mainPerformer = await SSUtils()
            .getPerformerProfile(pendingRequest.mainPerformerMobile);
        if (mainPerformer != null) {
          _mainPerformers[mainPerformer.mobile] = mainPerformer;
        }
      }

      // sort the linked event records
      _linkedEventRecords.sort((a, b) {
        if (a.date.isBefore(b.date)) {
          return -1;
        } else if (a.date.isAfter(b.date)) {
          return 1;
        } else {
          return 0;
        }
      });

      // refresh all child widgets
    });

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createPendingRequestCard(int index) {
    EventRecord pendingRequest = _linkedEventRecords[index];
    String title = DateFormat("dd MMM, yyyy").format(pendingRequest.date);
    title += " (${pendingRequest.slot.from} - ${pendingRequest.slot.to})";
    String performer =
        _mainPerformers[pendingRequest.mainPerformerMobile]!.name;
    String profilePicUrl =
        _mainPerformers[pendingRequest.mainPerformerMobile]!.profilePicUrl;

    return Widgets().createTopLevelCard(
        context: context,
        child: ListTile(
          title: Text(title),
          leading: CircleAvatar(backgroundImage: NetworkImage(profilePicUrl)),
          subtitle: Row(
            children: [
              Icon(Icons.person),
              Text(performer),
              SizedBox(width: 10),
              Icon(Icons.phone),
              Text(_mainPerformers[pendingRequest.mainPerformerMobile]!.mobile),
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeGaruda,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // leave some space at top
                      SizedBox(height: 10),

                      // your widgets here
                      ...List.generate(_linkedEventRecords.length, (index) {
                        // get the path of the pending request
                        EventRecord event = _linkedEventRecords[index];
                        String mobile = event.mainPerformerMobile;
                        String date =
                            DateFormat("yyyy-MM-dd").format(event.date);
                        String slot = event.slot.name;
                        String path =
                            "${Const().dbrootSangeetSeva}/Events/$mobile/$date/$slot";
                        Map<String, dynamic> pendingRequest = {
                          'path': path,
                        };

                        // create the card
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return RequestDetails(
                                title: "Request Details",
                                pendingRequest: pendingRequest,
                                eventRecord: _linkedEventRecords[index],
                                callbackDelete: (String action) {},
                              );
                            }));
                          },
                          child: _createPendingRequestCard(index),
                        );
                      }),

                      // empty message
                      if (_linkedEventRecords.isEmpty)
                        Center(
                          child: Text("No pending requests"),
                        ),

                      // leave some space at bottom
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon),
        ],
      ),
    );
  }
}
