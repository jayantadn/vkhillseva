import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/home.dart';
import 'package:vkhsangeetseva/profile.dart';

class RegistrationPage2 extends StatefulWidget {
  final String title;
  final String? icon;
  final DateTime selectedDate;
  final Slot slot;
  final EventRecord? oldEvent;

  const RegistrationPage2(
      {super.key,
      required this.title,
      this.icon,
      required this.selectedDate,
      required this.slot,
      this.oldEvent});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationPage2State createState() => _RegistrationPage2State();
}

class _RegistrationPage2State extends State<RegistrationPage2> {
  // scalars
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

    if (widget.oldEvent != null) {
      // populate the data structure
      EventRecord performanceRequest = widget.oldEvent!;

      // populate the lists
      _mainPerformer = UserDetails.fromJson(userdetailsJson);
      for (String mobile in performanceRequest.supportTeamMobiles) {
        UserDetails? details = await Utils().getUserDetails(mobile);
        if (details != null) {
          _supportingTeam.add(details);
        }
      }
      _guests.addAll(performanceRequest.guests);
      _songs.addAll(performanceRequest.songs);
      _noteController.text = performanceRequest.notePerformer;
    }

    // refresh all child widgets

    // perform sync operations here

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

  Future<void> _deleteEvent() async {
    // validate if event is in the past
    if (widget.oldEvent!.date.isBefore(DateTime.now())) {
      Toaster().error("Can't delete past event");
      return;
    }

    // delete from events
    UserBasics? basics = Utils().getUserBasics();
    String mobile = "";
    int index = 0;
    if (basics == null) {
      Toaster().error("Cant access user data");
      return;
    } else {
      mobile = basics.mobile;
      List<dynamic> list = await FB()
          .getList(path: "${Const().dbrootSangeetSeva}/Events/$mobile");
      index = list.indexWhere((element) {
        EventRecord event =
            Utils().convertRawToDatatype(element, EventRecord.fromJson);
        return event.date == widget.oldEvent!.date &&
            event.slot.from == widget.oldEvent!.slot.from &&
            event.slot.to == widget.oldEvent!.slot.to;
      });
      if (index == -1) {
        Toaster().error("Event not found");
        return;
      } else {
        await FB().deleteFromList(
            listpath: "${Const().dbrootSangeetSeva}/Events/$mobile",
            index: index);
      }
    }

    // delete from pending requests
    List pendingEvents = await FB()
        .getList(path: "${Const().dbrootSangeetSeva}/PendingRequests");
    int indexP = pendingEvents.indexWhere((element) =>
        element['path'] == "${Const().dbrootSangeetSeva}/Events/$mobile" &&
        element['index'] == index);
    await FB().deleteFromList(
        listpath: "${Const().dbrootSangeetSeva}/PendingRequests",
        index: indexP);

    // mark available slot
    String dbdate = DateFormat("yyyy-MM-dd").format(widget.selectedDate);
    Map<String, dynamic> slots = await FB().getJson(
        path: "${Const().dbrootSangeetSeva}/Slots/$dbdate", silent: true);
    String slotKey = "";
    for (var slot in slots.entries) {
      Slot s = Utils().convertRawToDatatype(slot.value, Slot.fromJson);
      if (widget.slot.from == s.from && widget.slot.to == s.to) {
        slotKey = slot.key;
        break;
      }
    }
    if (slotKey.isNotEmpty) {
      Slot slotToUpdate =
          Utils().convertRawToDatatype(slots[slotKey], Slot.fromJson);
      slotToUpdate.avl = true;
      await FB().setJson(
          path: "${Const().dbrootSangeetSeva}/Slots/$dbdate/$slotKey",
          json: slotToUpdate.toJson());
    }

    // show success message
    Toaster().info("Event deleted successfully");

    // notify admin
    String msg = Utils().getUsername();
    String date = DateFormat("dd MMM yyyy").format(widget.oldEvent!.date);
    msg += ", $date ${widget.slot.from} - ${widget.slot.to}";
    Notifications().sendPushNotificationToTopic(
        topic: "SSAdmin", title: "Event request deleted", body: msg);

    // go to homepage
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return HomePage(title: "Hare Krishna");
    }));
  }

  Future<void> _onSubmit() async {
    // validations for edit event
    if (widget.oldEvent != null) {
      // validate if event is already approved
      if (widget.oldEvent!.status == "Approved") {
        Toaster().error("Can't update approved event");
        return;
      }

      // validate if event is in the past
      if (widget.oldEvent!.date.isBefore(DateTime.now())) {
        Toaster().error("Can't update past event");
        return;
      }
    }

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
        status: "Pending");

    // save to firebase
    UserBasics? basics = Utils().getUserBasics();
    String mobile = "";
    int index = 0;
    if (basics == null) {
      Toaster().error("Cant access user data");
      return;
    } else {
      mobile = basics.mobile;
      if (widget.oldEvent == null) {
        // fresh entry
        index = await FB().addToList(
            listpath: "${Const().dbrootSangeetSeva}/Events/$mobile",
            data: performanceRequest.toJson());
      } else {
        // edit entry
        List<dynamic> list = await FB()
            .getList(path: "${Const().dbrootSangeetSeva}/Events/$mobile");
        index = list.indexWhere((element) {
          EventRecord event =
              Utils().convertRawToDatatype(element, EventRecord.fromJson);
          return event.date == widget.oldEvent!.date &&
              event.slot.from == widget.oldEvent!.slot.from &&
              event.slot.to == widget.oldEvent!.slot.to;
        });
        if (index == -1) {
          Toaster().error("Event not found");
          return;
        } else {
          await FB().editList(
              listpath: "${Const().dbrootSangeetSeva}/Events/$mobile",
              index: index,
              data: performanceRequest.toJson());
        }
      }
    }

    // add to pending requests
    if (widget.oldEvent == null || widget.oldEvent!.status != "Pending") {
      FB().addToList(
          listpath: "${Const().dbrootSangeetSeva}/PendingRequests",
          data: {
            "path": "${Const().dbrootSangeetSeva}/Events/$mobile",
            "index": index
          });
    }

    // show success message
    UtilWidgets().showMessage(context,
        "Your request has been submitted.\nYou will be notified once your request is approved");

    // go to homepage
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return HomePage(title: "Hare Krishna");
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
            appBar: AppBar(title: Text(widget.title), actions: [
              if (widget.oldEvent != null)
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    UtilWidgets().showConfirmDialog(
                        context,
                        "Are you sure you want to delete this event?",
                        "Delete", () async {
                      await _deleteEvent();
                    });
                  },
                )
            ]),
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

                          // temple notes
                          if (widget.oldEvent != null &&
                              widget.oldEvent!.noteTemple.isNotEmpty)
                            Card(
                                color: widget.oldEvent!.status == "Approved"
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                child: ListTile(
                                  title: Text("Temple notes"),
                                  subtitle: Text(widget.oldEvent!.noteTemple),
                                )),

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
                                subtitle: Text(
                                    "${_mainPerformer!.mobile} \n${_mainPerformer!.credentials}"),
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
                            child: widget.oldEvent == null
                                ? Text("Submit")
                                : Text("Update"),
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
