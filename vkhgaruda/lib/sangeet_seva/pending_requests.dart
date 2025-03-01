import 'dart:async';

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

  // lists
  final List<Map<String, dynamic>> _pendingRequests = [];
  final List<EventRecord> _linkedEventRecords = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _linkedEventRecords.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here

    // fetch pending requests
    _linkedEventRecords.clear();
    List<dynamic> pendingRequestLinks = await FB()
        .getList(path: "${Const().dbrootSangeetSeva}/PendingRequests");
    for (var pendingRequestLinkRaw in pendingRequestLinks) {
      Map<String, dynamic> pendingRequestLink =
          Map<String, dynamic>.from(pendingRequestLinkRaw);
      String path = pendingRequestLink['path'];
      int index = pendingRequestLink['index'];
      _pendingRequests.add({'path': path, 'index': index});

      List pendingRequestsPerUserRaw = await FB().getList(path: path);
      var pendingRequestPerUserRaw = pendingRequestsPerUserRaw[index];
      EventRecord pendingRequest = EventRecord.fromJson(
          Utils().convertRawToJson(pendingRequestPerUserRaw));

      _linkedEventRecords.add(pendingRequest);
    }

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createPendingRequestCard(EventRecord pendingRequest) {
    String title = DateFormat("dd MMM, yyyy").format(pendingRequest.date);
    title += " (${pendingRequest.slot.from} - ${pendingRequest.slot.to})";
    String performer =
        "${pendingRequest.mainPerformer.salutation} ${pendingRequest.mainPerformer.name}";
    return Card(
        child: ListTile(
      title: Text(title),
      leading: CircleAvatar(
          backgroundImage:
              NetworkImage(pendingRequest.mainPerformer.profilePicUrl)),
      subtitle: Text(performer),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
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
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return RequestDetails(
                                title: "Request Details",
                                pendingRequest: _pendingRequests[index],
                                eventRecord: _linkedEventRecords[index],
                              );
                            }));
                          },
                          child: _createPendingRequestCard(
                              _linkedEventRecords[index]),
                        );
                      }),

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
