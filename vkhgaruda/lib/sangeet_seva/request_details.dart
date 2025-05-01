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
  PerformerProfile? _mainPerformer;

  // lists
  final List<PerformerProfile> _supportTeam = [];

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
    _supportTeam.clear();

    // clear all controllers and focus nodes
    _noteController.dispose();

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here
    _mainPerformer = await SSUtils()
        .getPerformerProfile(widget.eventRecord.mainPerformerMobile);
    // TODO for (String supportMobile in widget.eventRecord.supportTeamMobiles) {
    //   PerformerProfile? support = await SSUtils().getUserProfile(supportMobile);
    //   if (support != null) _supportTeam.add(support);
    // }

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
      String mobile = widget.eventRecord.mainPerformerMobile;
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
            await FB().setJson(
                path: dbpath,
                json: {"Slot1": widget.eventRecord.slot.toJson()});
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
                if (widget.pendingRequest != null)
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
                  child: Column(
                    children: [
                      // leave some space at top
                      SizedBox(height: 10),

                      // your widgets here
                      Center(
                        child: Column(children: [
                          // date
                          Text(
                              DateFormat("EEE, dd MMM, yyyy")
                                  .format(widget.eventRecord.date),
                              style: themeGaruda.textTheme.headlineLarge),

                          // slot
                          Text(
                              "${widget.eventRecord.slot.from} - ${widget.eventRecord.slot.to}",
                              style: themeGaruda.textTheme.headlineMedium),

                          // main performer
                          Card(
                            child: Column(
                              children: [
                                Text("Main performer",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                ListTile(
                                  onTap: () async {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileDetails(
                                            title: "Main performer",
                                            icon: widget.icon,
                                            userdetails: _mainPerformer!),
                                      ),
                                    );
                                  },
                                  leading: _mainPerformer == null
                                      ? Text("")
                                      : CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              _mainPerformer!.profilePicUrl),
                                        ),
                                  title: _mainPerformer == null
                                      ? Text("")
                                      : Text(
                                          "${_mainPerformer!.salutation} ${_mainPerformer!.name}"),
                                  subtitle: _mainPerformer == null
                                      ? Text("")
                                      : Row(
                                          children: [
                                            Icon(Icons.phone),
                                            Text(_mainPerformer!.mobile),
                                            SizedBox(width: 10),
                                            Icon(Icons.workspace_premium),
                                            Text(_mainPerformer!.credentials),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),

                          // supporting team
                          if (_supportTeam.isNotEmpty)
                            Card(
                              child: Column(
                                children: [
                                  Text("Supporting team",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall),
                                  Widgets().createTopLevelResponsiveContainer(
                                      context,
                                      List.generate(_supportTeam.length,
                                          (index) {
                                        var member = _supportTeam[index];
                                        return ListTile(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileDetails(
                                                        title:
                                                            "Supporting team",
                                                        icon: widget.icon,
                                                        userdetails: member),
                                              ),
                                            );
                                          },
                                          leading: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                member.profilePicUrl),
                                          ),
                                          title: Text(
                                              "${member.salutation} ${member.name}"),
                                          subtitle: Row(
                                            children: [
                                              Icon(Icons.phone),
                                              Text(member.mobile),
                                              SizedBox(width: 10),
                                              Icon(Icons.workspace_premium),
                                              Text(member.credentials),
                                            ],
                                          ),
                                        );
                                      })),
                                ],
                              ),
                            ),

                          // guests
                          SizedBox(height: 10),
                          if (widget.eventRecord.guests.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Guests",
                                  style: themeGaruda.textTheme.headlineSmall),
                            ),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Widgets().createTopLevelResponsiveContainer(
                                context,
                                List.generate(widget.eventRecord.guests.length,
                                    (index) {
                                  var guest = widget.eventRecord.guests[index];
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        "${index + 1}. ${guest.name} ${guest.honorPrasadam ? " (Prasadam)" : ""}"),
                                  );
                                })),
                          ),

                          // list of songs
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("List of songs",
                                style: themeGaruda.textTheme.headlineSmall),
                          ),
                          ...List.generate(widget.eventRecord.songs.length,
                              (index) {
                            String song = widget.eventRecord.songs[index];
                            String title = song.split(":")[0];
                            String raaga = song.split(":")[1];
                            String taala = song.split(":")[2];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text(
                                      "${index + 1}. title: $title",
                                    ),
                                    SizedBox(width: 10),
                                    if (raaga.isNotEmpty) Text("raaga: $raaga"),
                                    SizedBox(width: 10),
                                    if (taala.isNotEmpty) Text("taala: $taala"),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // performer note
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Note:",
                                    style: themeGaruda.textTheme.headlineSmall),
                                Text(widget.eventRecord.notePerformer)
                              ],
                            ),
                          ),
                        ]),
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
