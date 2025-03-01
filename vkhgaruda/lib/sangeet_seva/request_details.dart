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

  const RequestDetails(
      {super.key,
      required this.title,
      this.icon,
      required this.pendingRequest,
      required this.eventRecord});

  @override
  // ignore: library_private_types_in_public_api
  _RequestDetailsState createState() => _RequestDetailsState();
}

class _RequestDetailsState extends State<RequestDetails> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
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
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(widget
                                    .eventRecord.mainPerformer.profilePicUrl),
                              ),
                              title: Text(
                                  "${widget.eventRecord.mainPerformer.salutation} ${widget.eventRecord.mainPerformer.name}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "${widget.eventRecord.mainPerformer.credentials}, ${widget.eventRecord.mainPerformer.experience} yrs sadhana"),
                                  Text(widget.eventRecord.mainPerformer.skills
                                      .join(', ')),
                                ],
                              ),
                              trailing: Icon(widget.eventRecord.mainPerformer
                                          .fieldOfExpertise ==
                                      "Vocalist"
                                  ? Icons.record_voice_over
                                  : Icons.music_note),
                            ),
                          ),

                          // supporting team
                          Utils().responsiveBuilder(
                              context,
                              List.generate(
                                  widget.eventRecord.supportTeam.length,
                                  (index) {
                                var member =
                                    widget.eventRecord.supportTeam[index];
                                return Card(
                                  child: ListTile(
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
