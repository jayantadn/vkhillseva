import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/profile_details.dart';
import 'package:vkhpackages/vkhpackages.dart';

class RequestDetails extends StatefulWidget {
  final String title;
  final String? icon;
  final Map<String, dynamic>? pendingRequest;
  final EventRecord eventRecord;
  final void Function(String action)? callbackDelete;

  const RequestDetails(
      {super.key,
      required this.title,
      this.icon,
      this.pendingRequest,
      required this.eventRecord,
      this.callbackDelete});

  @override
  // ignore: library_private_types_in_public_api
  _RequestDetailsState createState() => _RequestDetailsState();
}

class _RequestDetailsState extends State<RequestDetails> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  PerformerProfile? _eventRequester;

  // lists

  // controllers, listeners and focus nodes
  final TextEditingController _noteController = TextEditingController();

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes
    _noteController.dispose();

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here
    _eventRequester = await SSUtils()
        .getPerformerProfile(widget.eventRecord.eventRequesterMobile);

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
  }

  // action = Approve or Reject
  Future<void> _performAction(String action) async {
    if (widget.pendingRequest == null) {
      // event is already booked

      if (action == "Approve") {
        Toaster().error("Event is already approved");
        return;
      } else {
        // reject an approved event

        // delete from booked events
        String dbdate =
            DateFormat("yyyy-MM-dd").format(widget.eventRecord.date);
        String slotName = widget.eventRecord.slot.name;
        String bookedEventPath =
            "${Const().dbrootSangeetSeva}/BookedEvents/$dbdate";
        String eventPath =
            "${Const().dbrootSangeetSeva}/Events/${widget.eventRecord.eventRequesterMobile}/$dbdate/$slotName";
        List bookedEventsRaw = await FB().getList(path: bookedEventPath);
        List bookedEventsOutput = [];
        for (var bookedEventRaw in bookedEventsRaw) {
          Map<String, dynamic> bookedEvent =
              Map<String, dynamic>.from(bookedEventRaw);
          if (bookedEvent['path'] != eventPath) {
            bookedEventsOutput.add({"path": bookedEvent['path']});
          }
        }
        await FB().setValue(path: bookedEventPath, value: bookedEventsOutput);

        // change status of event
        widget.eventRecord.status = "Rejected";
        widget.eventRecord.noteTemple = _noteController.text;
        widget.eventRecord.slot.avl = true;
        await FB().setJson(path: eventPath, json: widget.eventRecord.toJson());

        // mark the availability of the slot
        String slotPath =
            "${Const().dbrootSangeetSeva}/Slots/$dbdate/$slotName";
        await FB()
            .setJson(path: slotPath, json: widget.eventRecord.slot.toJson());

        // notify the user
        String mobile = widget.eventRecord.eventRequesterMobile;
        String fcmToken = await Utils().getFcmToken(mobile);
        Notifications().sendPushNotification(
            fcmToken: fcmToken,
            title:
                action == "Approve" ? "Request approved" : "Request rejected",
            body:
                "Request for ${DateFormat("EEE, dd MMM, yyyy").format(widget.eventRecord.date)} is ${action == 'Approve' ? 'approved' : 'rejected'}",
            imageUrl:
                "https://firebasestorage.googleapis.com/v0/b/garuda-1ba07.firebasestorage.app/o/SANGEETSEVA_01%2FAppIcons%2FSangeetSeva_64x64.png?alt=media&token=9e6777cc-014b-4c15-85e4-8c5c0a5282d1");
      }
    } else {
      // event is pending approval

      String path = widget.pendingRequest!['path'];

      // set the availability flag in Event
      var eventRaw = await FB().getValue(path: path);
      EventRecord event =
          Utils().convertRawToDatatype(eventRaw, EventRecord.fromJson);
      event.status = action == "Approve" ? "Approved" : "Rejected";
      event.noteTemple = _noteController.text;
      eventRaw = event.toJson();
      await FB().setValue(path: path, value: eventRaw);

      // notify the user
      String mobile = widget.eventRecord.eventRequesterMobile;
      String fcmToken = await Utils().getFcmToken(mobile);
      Notifications().sendPushNotification(
          fcmToken: fcmToken,
          title: action == "Approve" ? "Request approved" : "Request rejected",
          body:
              "Request for ${DateFormat("EEE, dd MMM, yyyy").format(widget.eventRecord.date)} is ${action == 'Approve' ? 'approved' : 'rejected'}",
          imageUrl:
              "https://firebasestorage.googleapis.com/v0/b/garuda-1ba07.firebasestorage.app/o/SANGEETSEVA_01%2FAppIcons%2FSangeetSeva_64x64.png?alt=media&token=9e6777cc-014b-4c15-85e4-8c5c0a5282d1");

      // append to booked events
      String dbdate = DateFormat("yyyy-MM-dd").format(widget.eventRecord.date);
      String dbpath = "${Const().dbrootSangeetSeva}/BookedEvents/$dbdate";
      await FB().addToList(listpath: dbpath, data: widget.pendingRequest!);

      // mark the availability of the slot
      if (action == "Approve") {
        widget.eventRecord.slot.avl = false;
        String dbdate =
            DateFormat("yyyy-MM-dd").format(widget.eventRecord.date);
        String dbpath = "${Const().dbrootSangeetSeva}/Slots/$dbdate";
        if (await FB().pathExists(dbpath)) {
          List slotsRaw = await FB().getList(path: dbpath);
          String dbpathNew =
              "${Const().dbrootSangeetSeva}/Slots/$dbdate/Slot${slotsRaw.length + 1}";
          await FB()
              .setJson(path: dbpathNew, json: widget.eventRecord.slot.toJson());
        } else {
          if (Utils().isDateWeekend(widget.eventRecord.date)) {
            await FB().setJson(path: dbpath, json: {
              widget.eventRecord.slot.name: widget.eventRecord.slot.toJson()
            });
          } else {
            Toaster().error("Invalid slot");
          }
        }
      }

      // loop through all pending requests, remove the matching one
      List pendingRequestsRaw = await FB()
          .getList(path: "${Const().dbrootSangeetSeva}/PendingRequests");
      for (var pendingRequestRaw in pendingRequestsRaw) {
        Map<String, dynamic> pendingRequest =
            Map<String, dynamic>.from(pendingRequestRaw);
        if (pendingRequest['path'] == path) {
          pendingRequestsRaw.remove(pendingRequestRaw);
          break;
        }
      }
      await FB().setValue(
          path: "${Const().dbrootSangeetSeva}/PendingRequests",
          value: pendingRequestsRaw);

      // callbackDelete
      if (widget.callbackDelete != null) {
        widget.callbackDelete!(action);
      }
    }
  }

  void _showActionDialog(String action) {
    _noteController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("$action request"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Are you sure you want to $action this request?"),
                SizedBox(height: 10),
                Text("Note:", style: themeGaruda.textTheme.headlineSmall),
                TextField(
                  maxLines: 2,
                  controller: _noteController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(action),
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                if (action == "Approve") {
                  await _performAction("Approve");
                } else {
                  await _performAction("Reject");
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeGaruda,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                // reject button
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    _showActionDialog("Reject");
                  },
                ),

                // approve button
                if (widget.pendingRequest != null)
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      _showActionDialog("Approve");
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

                        Text(
                            DateFormat("EEE, dd MMM, yyyy")
                                .format(widget.eventRecord.date),
                            style: themeGaruda.textTheme.headlineLarge),

                        // slot
                        Text(
                            "${widget.eventRecord.slot.from} - ${widget.eventRecord.slot.to}",
                            style: themeGaruda.textTheme.headlineMedium),

                        Column(children: [
                          // your widgets here

                          // event requester
                          Widgets().createTopLevelCard(
                            context: context,
                            title: "Event requester",
                            child: Column(
                              children: [
                                ListTile(
                                  onTap: () async {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileDetails(
                                            title: "Profile",
                                            icon: widget.icon,
                                            userdetails: _eventRequester!),
                                      ),
                                    );
                                  },
                                  leading: _eventRequester == null
                                      ? Text("")
                                      : CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              _eventRequester!.profilePicUrl),
                                        ),
                                  title: _eventRequester == null
                                      ? Text("")
                                      : Text(
                                          "${_eventRequester!.salutation} ${_eventRequester!.name}"),
                                  subtitle: _eventRequester == null
                                      ? Text("")
                                      : Row(
                                          children: [
                                            Icon(Icons.phone),
                                            Text(_eventRequester!.mobile),
                                            SizedBox(width: 10),
                                            Icon(Icons.workspace_premium),
                                            Text(_eventRequester!.credentials),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),

                          // performers
                          if (widget.eventRecord.supportTeam.isNotEmpty)
                            Widgets().createTopLevelCard(
                              context: context,
                              title: "Performers",
                              child: Column(
                                children: [
                                  ...List.generate(
                                      widget.eventRecord.supportTeam.length,
                                      (index) {
                                    var member =
                                        widget.eventRecord.supportTeam[index];
                                    return ListTile(
                                      leading: Text(
                                        "${index + 1}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      title: Text(
                                          "${member.salutation} ${member.name}"),
                                      subtitle: Row(
                                        children: [
                                          Icon(Icons.workspace_premium),
                                          Text(member.specialization),
                                        ],
                                      ),
                                    );
                                  }),

                                  // guests
                                  if (widget.eventRecord.guests > 0)
                                    ListTile(
                                      title: Text(
                                          "Number of guests: ${widget.eventRecord.guests}"),
                                    ),
                                ],
                              ),
                            ),

                          // list of songs
                          Widgets().createTopLevelCard(
                              context: context,
                              title: "List of songs",
                              child: Widgets()
                                  .createTopLevelResponsiveContainer(
                                      context,
                                      List.generate(
                                          widget.eventRecord.songs.length,
                                          (index) {
                                        String song =
                                            widget.eventRecord.songs[index];
                                        String title = song.split(":")[0];
                                        String raaga = song.split(":")[1];
                                        String taala = song.split(":")[2];
                                        return ListTile(
                                          leading: Text(
                                            "${index + 1}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                          title: Text(title),
                                          subtitle: (raaga.isEmpty &&
                                                  taala.isEmpty)
                                              ? null
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (raaga.isNotEmpty)
                                                      Text("Raaga: $raaga"),
                                                    if (taala.isNotEmpty)
                                                      Text("Taala: $taala"),
                                                  ],
                                                ),
                                        );
                                      }))),

                          // performer note
                          if (widget.eventRecord.notePerformer.isNotEmpty)
                            Widgets().createTopLevelCard(
                              context: context,
                              title: "Note from performer",
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(widget.eventRecord.noteTemple),
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
          if (_isLoading) LoadingOverlay(image: widget.icon),
        ],
      ),
    );
  }
}
