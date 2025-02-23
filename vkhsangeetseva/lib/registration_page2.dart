import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/profile.dart';
import 'package:vkhsangeetseva/user.dart';

class RegistrationPage2 extends StatefulWidget {
  final String title;
  final String? icon;
  final DateTime selectedDate;
  final Slot slot;

  const RegistrationPage2(
      {super.key,
      required this.title,
      this.icon,
      required this.selectedDate,
      required this.slot});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationPage2State createState() => _RegistrationPage2State();
}

class _RegistrationPage2State extends State<RegistrationPage2> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  UserDetails? _mainPerformer;

  // lists
  List<UserDetails> _supportingTeam = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _supportingTeam.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here

    // fetch form values
    await Utils().fetchUserBasics();
    String mobile = Utils().getUserBasics()!.mobile;
    bool userExists = await FB().pathExists("Users/$mobile");
    Map<String, dynamic> userdetailsJson = {};
    if (userExists) {
      userdetailsJson = await FB().getJson(path: "Users/$mobile");
    } else {
      Toaster().error("User not found");
    }

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;

      if (userdetailsJson.isNotEmpty) {
        _mainPerformer = UserDetails.fromJson(userdetailsJson);
      }
    });
  }

  Future<void> _showAddGuestDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add guest"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // name
                TextField(
                  decoration: InputDecoration(labelText: "Name"),
                ),

                // honor prasadam
                CheckboxListTile(
                  title: Text("Honor Prasadam"),
                  value: false,
                  onChanged: (newValue) {
                    // handle change
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Add"),
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
            appBar: AppBar(title: Text(widget.title)),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // leave some space at top
                      SizedBox(height: 10),

                      // your widgets here
                      Center(
                        child: Column(children: [
                          // date
                          Text(
                              DateFormat("EEE, dd MMM, yyyy")
                                  .format(widget.selectedDate),
                              style: themeDefault.textTheme.headlineLarge),

                          // slot
                          Text("${widget.slot.from} - ${widget.slot.to}",
                              style: themeDefault.textTheme.headlineMedium),

                          // main performer
                          if (_mainPerformer != null)
                            Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      _mainPerformer!.profilePicUrl),
                                ),
                                title: Text(
                                    "${_mainPerformer!.salutation} ${_mainPerformer!.name}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "${_mainPerformer!.credentials}, ${_mainPerformer!.experience} yrs sadhana"),
                                    Text(_mainPerformer!.skills.join(', ')),
                                  ],
                                ),
                                trailing: Icon(
                                    _mainPerformer!.fieldOfExpertise ==
                                            "Vocalist"
                                        ? Icons.record_voice_over
                                        : Icons.music_note),
                              ),
                            ),

                          // support team
                          Utils().responsiveBuilder(
                              List.generate(_supportingTeam.length, (index) {
                            var member = _supportingTeam[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(member.profilePicUrl),
                                ),
                                title:
                                    Text("${member.salutation} ${member.name}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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

                          // add supporting team
                          SizedBox(height: 10),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Profile(
                                      title: "Supporting team",
                                      self: false,
                                      onProfileSaved: (user) {
                                        setState(() {
                                          _supportingTeam.add(user);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Text("Add supporting team")),

                          // add
                          SizedBox(height: 10),
                          ElevatedButton(
                              onPressed: () {
                                _showAddGuestDialog(context);
                              },
                              child: Text("Add guest")),
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
