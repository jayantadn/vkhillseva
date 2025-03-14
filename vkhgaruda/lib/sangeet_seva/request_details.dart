import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/profile_details.dart';
import 'package:vkhpackages/vkhpackages.dart';

class RequestDetails extends StatefulWidget {
  final String title;
  final String? icon;
  final Map<String, dynamic> pendingRequest;
  final EventRecord eventRecord;
  final void Function(String action) callback;

  const RequestDetails(
      {super.key,
      required this.title,
      this.icon,
      required this.pendingRequest,
      required this.eventRecord,
      required this.callback});

  @override
  // ignore: library_private_types_in_public_api
  _RequestDetailsState createState() => _RequestDetailsState();
}

class _RequestDetailsState extends State<RequestDetails> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  UserDetails? _mainPerformer;

  // lists
  List<UserDetails> _supportTeam = [];

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
    _mainPerformer =
        await Utils().getUserDetails(widget.eventRecord.mainPerformerMobile);
    for (String supportMobile in widget.eventRecord.supportTeamMobiles) {
      UserDetails? support = await Utils().getUserDetails(supportMobile);
      if (support != null) _supportTeam.add(support);
    }

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _performAction(String action) async {
    String path = widget.pendingRequest['path'];
    int index = widget.pendingRequest['index'];
    List eventsRaw = await FB().getList(path: path);

    EventRecord event =
        Utils().convertRawToDatatype(eventsRaw[index], EventRecord.fromJson);
    event.status = action == "Approve" ? "Approved" : "Rejected";
    event.noteTemple = _noteController.text;

    eventsRaw[index] = event.toJson();
    await FB().setValue(path: path, value: eventsRaw);

    // mark the availability of the slot
    if (action == "Approve") {
      widget.eventRecord.slot.avl = false;
      String dbdate = DateFormat("yyyy-MM-dd").format(widget.eventRecord.date);
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
              path: dbpath, json: {"Slot1": widget.eventRecord.slot.toJson()});
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
      if (pendingRequest['path'] == path && pendingRequest['index'] == index) {
        pendingRequestsRaw.remove(pendingRequestRaw);
        break;
      }
    }
    await FB().setValue(
        path: "${Const().dbrootSangeetSeva}/PendingRequests",
        value: pendingRequestsRaw);

    // callback
    widget.callback(action);
  }

  void _showDialog(String action) {
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
                Text("Note:", style: themeDefault.textTheme.headlineSmall),
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
      data: themeDefault,
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
                    _showDialog("Reject");
                  },
                ),

                // approve button
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () {
                    _showDialog("Approve");
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
                              style: themeDefault.textTheme.headlineLarge),

                          // slot
                          Text(
                              "${widget.eventRecord.slot.from} - ${widget.eventRecord.slot.to}",
                              style: themeDefault.textTheme.headlineMedium),

                          // main performer
                          Card(
                            child: ListTile(
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
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "${_mainPerformer!.credentials}, ${_mainPerformer!.experience} yrs sadhana"),
                                        Text(_mainPerformer!.skills.join(', ')),
                                      ],
                                    ),
                              trailing: _mainPerformer == null
                                  ? Text("")
                                  : Icon(_mainPerformer!.fieldOfExpertise ==
                                          "Vocalist"
                                      ? Icons.record_voice_over
                                      : Icons.music_note),
                            ),
                          ),

                          // supporting team
                          Utils().responsiveBuilder(
                              context,
                              List.generate(_supportTeam.length, (index) {
                                var member = _supportTeam[index];
                                return Card(
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfileDetails(
                                              title: "Supporting team",
                                              icon: widget.icon,
                                              userdetails: member),
                                        ),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(member.profilePicUrl),
                                    ),
                                    title: Text(
                                        "${member.salutation} ${member.name}"),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "${member.credentials}, ${member.experience} yrs sadhana"),
                                        Text(member.skills.join(', ')),
                                      ],
                                    ),
                                    trailing: Icon(
                                        member.fieldOfExpertise == "Vocalist"
                                            ? Icons.record_voice_over
                                            : Icons.music_note),
                                  ),
                                );
                              })),

                          // guests
                          SizedBox(height: 10),
                          if (widget.eventRecord.guests.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Guests",
                                  style: themeDefault.textTheme.headlineSmall),
                            ),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Utils().responsiveBuilder(
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
                                style: themeDefault.textTheme.headlineSmall),
                          ),
                          ...List.generate(widget.eventRecord.songs.length,
                              (index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "${index + 1}. ${widget.eventRecord.songs[index]}",
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
                                    style:
                                        themeDefault.textTheme.headlineSmall),
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
