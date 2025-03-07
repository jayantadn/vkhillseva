import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/home.dart';
import 'package:vkhsangeetseva/profile.dart';

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
  final _minSongs = 4;

  // lists
  final List<UserDetails> _supportingTeam = [];
  final List<Guest> _guests = [];
  final List<String> _songs = [];

  // controllers, listeners and focus nodes
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _songController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _supportingTeam.clear();
    _guests.clear();
    _songs.clear();

    // clear all controllers and focus nodes
    _guestNameController.dispose();
    _songController.dispose();
    _noteController.dispose();

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
    bool userExists =
        await FB().pathExists("${Const().dbrootSangeetSeva}/Users/$mobile");
    Map<String, dynamic> userdetailsJson = {};
    if (userExists) {
      userdetailsJson = await FB()
          .getJson(path: "${Const().dbrootSangeetSeva}/Users/$mobile");
    } else {
      Toaster().error("User not found");
    }

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;

      if (userdetailsJson.isEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Profile(
            title: "Profile",
            self: true,
            onProfileSaved: (user) {
              setState(() {
                _mainPerformer = user;
              });
            },
          );
        }));
      } else {
        _mainPerformer = UserDetails.fromJson(userdetailsJson);
      }
    });
  }

  Future<void> _onSubmit() async {
    // add half filled song
    if (_songController.text.isNotEmpty) {
      _songs.add(_songController.text);
    }

    // validate list of songs
    if (_songs.length < _minSongs) {
      Toaster().error("Please enter at least $_minSongs songs");
      return;
    }

    // populate the data structure
    EventRecord performanceRequest = EventRecord(
      date: widget.selectedDate,
      slot: widget.slot,
      mainPerformerMobile: _mainPerformer!.mobile,
      supportTeamMobiles: List.generate(_supportingTeam.length, (index) {
        return _supportingTeam[index].mobile;
      }),
      guests: _guests,
      songs: _songs,
      notePerformer: _noteController.text,
    );

    // save to firebase
    UserBasics? basics = Utils().getUserBasics();
    String mobile = "";
    int index = 0;
    if (basics == null) {
      Toaster().error("Cant access user data");
      return;
    } else {
      mobile = basics.mobile;
      index = await FB().addToList(
          listpath: "${Const().dbrootSangeetSeva}/Events/$mobile",
          data: performanceRequest.toJson());
    }

    // add to pending requests
    FB().addToList(
        listpath: "${Const().dbrootSangeetSeva}/PendingRequests",
        data: {
          "path": "${Const().dbrootSangeetSeva}/Events/$mobile",
          "index": index
        });

    // go to homepage
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return HomePage();
    }));
  }

  Future<void> _showAddGuestDialog(BuildContext context) {
    _guestNameController.clear();
    bool honorPrasadam = false;

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
                  controller: _guestNameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),

                // honor prasadam
                StatefulBuilder(
                  builder: (context, setState) {
                    return CheckboxListTile(
                      title: Text("Honor Prasadam"),
                      value: honorPrasadam,
                      onChanged: (newValue) {
                        setState(() {
                          honorPrasadam = newValue!;
                        });
                      },
                    );
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

                setState(() {
                  _guests.add(Guest(
                      name: _guestNameController.text,
                      honorPrasadam: honorPrasadam));
                });
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

                          // supporting team
                          Utils().responsiveBuilder(
                              context,
                              List.generate(_supportingTeam.length, (index) {
                                var member = _supportingTeam[index];
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

                          // add supporting team
                          SizedBox(height: 10),
                          TextButton(
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
                              child: Text(
                                "Add supporting team",
                              )),

                          // guests
                          SizedBox(height: 10),
                          if (_guests.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Guests",
                                  style: themeDefault.textTheme.headlineSmall),
                            ),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Utils().responsiveBuilder(
                                context,
                                List.generate(_guests.length, (index) {
                                  var guest = _guests[index];
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        "${index + 1}. ${guest.name} ${guest.honorPrasadam ? " (Prasadam)" : ""}"),
                                  );
                                })),
                          ),

                          // add guest
                          SizedBox(height: 10),
                          TextButton(
                              onPressed: () {
                                _showAddGuestDialog(context);
                              },
                              child: Text("Add guest")),

                          // list of songs
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("List of songs",
                                style: themeDefault.textTheme.headlineSmall),
                          ),
                          ...List.generate(_songs.length, (index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "${index + 1}. ${_songs[index]}",
                                ),
                              ),
                            );
                          }),
                          SizedBox(height: 10),
                          if (_songs.length < 10)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _songController,
                                    decoration: InputDecoration(
                                        hintText: "Enter song name"),
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _songs.add(_songController.text);
                                      });
                                      _songController.clear();
                                    },
                                    icon: Icon(Icons.add))
                              ],
                            ),

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
                                TextField(
                                  maxLines: 2,
                                  controller: _noteController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: "optional note for performer",
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // submit button
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _onSubmit,
                            child: Text("Submit"),
                          )
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
