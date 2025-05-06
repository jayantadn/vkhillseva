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
  final bool? readOnly;

  const RegistrationPage2({
    super.key,
    required this.title,
    this.icon,
    required this.selectedDate,
    required this.slot,
    this.oldEvent,
    this.readOnly,
  });

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationPage2State createState() => _RegistrationPage2State();
}

class _RegistrationPage2State extends State<RegistrationPage2> {
  // scalars
  bool _isLoading = true;
  PerformerProfile? _mainPerformer;
  final _minSongs = 3;

  // lists
  final List<SupportUser> _supportingTeam = [];
  final List<Guest> _guests = [];
  final List<String> _songs = [];

  // controllers, listeners and focus nodes
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _raagaController = TextEditingController();
  final TextEditingController _taalaController = TextEditingController();

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
    _noteController.dispose();
    _titleController.dispose();
    _raagaController.dispose();
    _taalaController.dispose();

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
    bool userExists = await FB().pathExists(
      "${Const().dbrootSangeetSeva}/Users/$mobile",
    );
    Map<String, dynamic> userdetailsJson = {};
    if (userExists) {
      userdetailsJson = await FB().getJson(
        path: "${Const().dbrootSangeetSeva}/Users/$mobile",
      );
    } else {
      Toaster().error("User not found");
    }

    if (widget.oldEvent != null) {
      // populate the data structure
      EventRecord performanceRequest = widget.oldEvent!;

      // populate the lists
      for (SupportUser support in performanceRequest.supportTeam) {
        _supportingTeam.add(support);
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Profile(
                title: "Profile",
                self: true,
                onProfileSaved: (user) {
                  setState(() {
                    _mainPerformer = user;
                  });
                },
              );
            },
          ),
        );
      } else {
        _mainPerformer = PerformerProfile.fromJson(userdetailsJson);
      }
    });
  }

  Widget _createSongTile(int index) {
    var song = _songs[index];
    var songDetails = song.split(":");
    String title = songDetails[0];
    String raaga = songDetails[1];
    String taala = songDetails[2];
    return ListTile(
      leading: Text(
        "${index + 1}",
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      title: Text(title),
      subtitle:
          (raaga.isNotEmpty && taala.isNotEmpty)
              ? Row(
                children: [
                  Text("raaga: $raaga"),
                  SizedBox(width: 10),
                  Text("taala: $taala"),
                ],
              )
              : null,
      trailing:
          widget.readOnly != null
              ? null
              : Widgets().createContextMenu(["Edit", "Delete"], (
                String action,
              ) {
                switch (action) {
                  case "Edit":
                    _showAddSongDialog(context: context, index: index);
                    break;
                  case "Delete":
                    setState(() {
                      _songs.removeAt(index);
                    });
                    break;
                }
              }),
    );
  }

  Widget _createSupportingTeamTile(int index) {
    var member = _supportingTeam[index];
    return ListTile(
      onTap: () {},
      title: Text("${member.salutation} ${member.name}"),
      leading: Text(
        "${index + 1}",
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium),
                SizedBox(width: 5),
                Text(member.specialization),
              ],
            ),
          ],
        ),
      ),
      trailing:
          widget.readOnly != null
              ? null
              : Widgets().createContextMenu(["Edit", "Remove"], (
                String action,
              ) async {
                switch (action) {
                  case "Edit":
                    await _showAddSupportTeamDialog(
                      context: context,
                      oldUser: member,
                    );
                    break;
                  case "Remove":
                    setState(() {
                      _supportingTeam.removeAt(index);
                    });
                    break;
                }
              }),
    );
  }

  Widget _createGuestTile(int index) {
    var member = _guests[index];
    return ListTile(
      onTap: () {},
      title: Text(member.name),
      leading: Text(
        "${index + 1}",
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              children: [
                Text(member.honorPrasadam ? "Honor Prasadam" : "No Prasadam"),
              ],
            ),
          ],
        ),
      ),
      trailing:
          widget.readOnly != null
              ? null
              : Widgets().createContextMenu(["Edit", "Remove"], (
                String action,
              ) async {
                switch (action) {
                  case "Edit":
                    await _showAddGuestDialog(
                      context: context,
                      oldUser: member,
                    );
                    break;
                  case "Remove":
                    setState(() {
                      _guests.removeAt(index);
                    });
                    break;
                }
              }),
    );
  }

  Future<void> _deleteEvent() async {
    // validate if event is in the past
    DateTime today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    if (widget.oldEvent!.date.isBefore(today)) {
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
      List<dynamic> list = await FB().getList(
        path: "${Const().dbrootSangeetSeva}/Events/$mobile",
      );
      index = list.indexWhere((element) {
        EventRecord event = Utils().convertRawToDatatype(
          element,
          EventRecord.fromJson,
        );
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
          index: index,
        );
      }
    }

    // delete from pending requests
    List pendingEvents = await FB().getList(
      path: "${Const().dbrootSangeetSeva}/PendingRequests",
    );
    int indexP = pendingEvents.indexWhere(
      (element) =>
          element['path'] == "${Const().dbrootSangeetSeva}/Events/$mobile",
    );
    await FB().deleteFromList(
      listpath: "${Const().dbrootSangeetSeva}/PendingRequests",
      index: indexP,
    );

    // mark available slot
    String dbdate = DateFormat("yyyy-MM-dd").format(widget.selectedDate);
    Map<String, dynamic> slots = await FB().getJson(
      path: "${Const().dbrootSangeetSeva}/Slots/$dbdate",
      silent: true,
    );
    String slotKey = "";
    for (var slot in slots.entries) {
      Slot s = Utils().convertRawToDatatype(slot.value, Slot.fromJson);
      if (widget.slot.from == s.from && widget.slot.to == s.to) {
        slotKey = slot.key;
        break;
      }
    }
    if (slotKey.isNotEmpty) {
      Slot slotToUpdate = Utils().convertRawToDatatype(
        slots[slotKey],
        Slot.fromJson,
      );
      slotToUpdate.avl = true;
      await FB().setJson(
        path: "${Const().dbrootSangeetSeva}/Slots/$dbdate/$slotKey",
        json: slotToUpdate.toJson(),
      );
    }

    // show success message
    Toaster().info("Event deleted successfully");

    // notify admin
    String msg = Utils().getUsername();
    String date = DateFormat("dd MMM yyyy").format(widget.oldEvent!.date);
    msg += ", $date ${widget.slot.from} - ${widget.slot.to}";
    Notifications().sendPushNotificationToTopic(
      topic: "SSAdmin",
      title: "Event request deleted",
      body: msg,
    );

    // go to homepage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return HomePage(title: "Hare Krishna");
        },
      ),
    );
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
      DateTime today = DateTime.now();
      today = DateTime(today.year, today.month, today.day);
      if (widget.oldEvent!.date.isBefore(today)) {
        Toaster().error("Can't update past event");
        return;
      }
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
      supportTeam: _supportingTeam,
      guests: _guests,
      songs: _songs,
      notePerformer: _noteController.text,
      status: "Pending",
    );

    // save to firebase
    UserBasics? basics = Utils().getUserBasics();
    String mobile = "";
    String dbdate = DateFormat("yyyy-MM-dd").format(performanceRequest.date);
    if (basics == null) {
      Toaster().error("Cant access user data");
      return;
    } else {
      mobile = basics.mobile;
      FB().setJson(
        path:
            "${Const().dbrootSangeetSeva}/Events/$mobile/$dbdate/${performanceRequest.slot.name}",
        json: performanceRequest.toJson(),
      );
    }

    // add to pending requests
    if (widget.oldEvent == null || widget.oldEvent!.status != "Pending") {
      FB().addToList(
        listpath: "${Const().dbrootSangeetSeva}/PendingRequests",
        data: {
          "path":
              "${Const().dbrootSangeetSeva}/Events/$mobile/$dbdate/${performanceRequest.slot.name}",
        },
      );
    }

    // notify admin
    String msg = Utils().getUsername();
    String date = DateFormat("dd MMM yyyy").format(performanceRequest.date);
    msg += ", $date";
    Notifications().sendPushNotificationToTopic(
      topic: "SSAdmin",
      title: "Event request submitted",
      body: msg,
    );

    // show success message
    await Widgets().showMessage(
      context,
      "Your request has been submitted.\nYou will be notified once your request is approved",
    );

    // go to homepage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return HomePage(title: "Hare Krishna");
        },
      ),
    );
  }

  Future<void> _showAddGuestDialog({
    required BuildContext context,
    Guest? oldUser,
  }) {
    bool honorPrasadam = false;
    if (oldUser == null) {
      _guestNameController.clear();
    } else {
      _guestNameController.text = oldUser.name;
      honorPrasadam = oldUser.honorPrasadam;
    }

    FocusNode focusNode = FocusNode();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    return showDialog(
      context: context,
      builder: (context) {
        // Request focus after the dialog is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });

        return AlertDialog(
          title: Text(oldUser == null ? "Add guest" : "Edit guest"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // name
                  TextFormField(
                    controller: _guestNameController,
                    focusNode: focusNode,
                    decoration: InputDecoration(labelText: "Name"),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.length < 3 ||
                          value.length > 30) {
                        return "Please enter a valid name";
                      }
                      if (RegExp(
                        r'[0-9!@#$%^&*(),.?":{}|<>]',
                      ).hasMatch(value)) {
                        return "Numbers and special characters are not allowed";
                      }
                      if (_guests.any((guest) => guest.name == value)) {
                        return "Guest already exists";
                      }
                      return null;
                    },
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
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),

            // add button
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(context);

                setState(() {
                  if (oldUser == null) {
                    _guests.add(
                      Guest(
                        name: _guestNameController.text,
                        honorPrasadam: honorPrasadam,
                      ),
                    );
                  } else {
                    int index = _guests.indexOf(oldUser);
                    if (index != -1) {
                      _guests[index] = Guest(
                        name: _guestNameController.text,
                        honorPrasadam: honorPrasadam,
                      );
                    }
                  }
                });
              },
              child: Text(oldUser == null ? "Add" : "Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddSongDialog({required BuildContext context, int? index}) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    _titleController.clear();

    if (index != null) {
      var songDetails = _songs[index].split(":");
      _titleController.text = songDetails[0];
      _raagaController.text = songDetails[1];
      _taalaController.text = songDetails[2];
    }

    FocusNode focusNode = FocusNode();
    return showDialog(
      context: context,
      builder: (context) {
        // Request focus after the dialog is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });

        return AlertDialog(
          title: Text("Add song for event"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // title
                  TextFormField(
                    controller: _titleController,
                    focusNode: focusNode,
                    onChanged: (value) {},
                    decoration: InputDecoration(labelText: "Song title"),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 3) {
                        return "Please enter a valid name";
                      }
                      if (RegExp(
                        r'[0-9!@#$%^&*(),.?":{}|<>]',
                      ).hasMatch(value)) {
                        return "Special characters are not allowed";
                      }
                      return null;
                    },
                  ),

                  // Raaga
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _raagaController,
                    onChanged: (value) {},
                    decoration: InputDecoration(labelText: "Raaga"),
                    validator: (value) {
                      if (value != null &&
                          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                        return "Special characters are not allowed";
                      }
                      return null;
                    },
                  ),

                  // Taala
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _taalaController,
                    onChanged: (value) {},
                    decoration: InputDecoration(labelText: "Taala"),
                    validator: (value) {
                      if (value != null &&
                          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                        return "Special characters are not allowed";
                      }
                      return null;
                    },
                  ),
                ],
              ),
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
                if (!formKey.currentState!.validate()) {
                  return;
                }

                setState(() {
                  if (index == null) {
                    _songs.add(
                      "${_titleController.text}:${_raagaController.text}:${_taalaController.text}",
                    );
                  } else {
                    // edit mode
                    _songs[index] =
                        "${_titleController.text}:${_raagaController.text}:${_taalaController.text}";
                  }
                });

                Navigator.pop(context);
              },
              child: Text(index == null ? "Add" : "Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddSupportTeamDialog({
    required BuildContext context,
    SupportUser? oldUser,
  }) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    String salutation = "";
    TextEditingController supportNameController = TextEditingController();
    String specialization = "Vocalist";

    // edit mode
    if (oldUser != null) {
      salutation = oldUser.salutation;
      supportNameController.text = oldUser.name;
      specialization = oldUser.specialization;
    }

    FocusNode focusNode = FocusNode();
    return showDialog(
      context: context,
      builder: (context) {
        // Request focus after the dialog is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });

        return AlertDialog(
          title: Text(
            oldUser == null ? "Add support team" : "Edit support team",
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // salutation
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Salutation"),
                    value:
                        salutation.isNotEmpty
                            ? salutation
                            : SSConst().salutations.first,
                    items:
                        SSConst().salutations.map((salutation) {
                          return DropdownMenuItem<String>(
                            value: salutation,
                            child: Text(salutation),
                          );
                        }).toList(),
                    onChanged: (value) {
                      salutation = value!;
                    },
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.length < 3 ||
                          value.length > 30) {
                        return "Please enter a valid name";
                      }
                      if (RegExp(
                        r'[0-9!@#$%^&*(),.?":{}|<>]',
                      ).hasMatch(value)) {
                        return "Special characters are not allowed";
                      }
                      if (_supportingTeam.any((s) => s.name == value)) {
                        return "Member already exists";
                      }

                      return null;
                    },
                  ),

                  // name
                  TextFormField(
                    controller: supportNameController,
                    focusNode: focusNode,
                    decoration: InputDecoration(labelText: "Name"),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.length < 3 ||
                          value.length > 30) {
                        return "Please enter a valid name";
                      }
                      if (RegExp(
                        r'[0-9!@#$%^&*(),.?":{}|<>]',
                      ).hasMatch(value)) {
                        return "Numbers and special characters are not allowed";
                      }
                      if (_guests.any((guest) => guest.name == value)) {
                        return "Guest already exists";
                      }

                      return null;
                    },
                  ),

                  // specialization
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Specialization"),
                    value: specialization,
                    items:
                        [
                          "Vocalist",
                          ...SSConst().instrumentSkills,
                          "Other",
                        ].map((specialization) {
                          return DropdownMenuItem<String>(
                            value: specialization,
                            child: Text(specialization),
                          );
                        }).toList(),
                    onChanged: (value) {
                      specialization = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please select a specialization";
                      }
                      return null;
                    },
                  ),
                ],
              ),
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
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(context);

                SupportUser user = SupportUser(
                  salutation: salutation,
                  name: supportNameController.text,
                  specialization: specialization,
                  friendMobile: _mainPerformer!.mobile,
                );

                setState(() {
                  if (oldUser == null) {
                    _supportingTeam.add(user);
                  } else {
                    int index = _supportingTeam.indexOf(oldUser);
                    if (index != -1) {
                      _supportingTeam[index] = user;
                    }
                  }
                });
              },
              child: Text(oldUser == null ? "Add" : "Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              if (widget.oldEvent != null && widget.readOnly == null)
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    Widgets().showConfirmDialog(
                      context,
                      "Are you sure you want to delete this event?",
                      "Delete",
                      () async {
                        await _deleteEvent();
                      },
                    );
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

                      // date
                      Text(
                        DateFormat(
                          "EEE, dd MMM, yyyy",
                        ).format(widget.selectedDate),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),

                      // slot
                      Text(
                        "${widget.slot.from} - ${widget.slot.to}",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),

                      // temple notes
                      SizedBox(height: 10),
                      if (widget.oldEvent != null &&
                          widget.oldEvent!.noteTemple.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: ListTile(
                            title: Text("Notes from temple"),
                            subtitle: Text(widget.oldEvent!.noteTemple),
                          ),
                        ),
                      SizedBox(height: 10),

                      // main performer
                      if (_mainPerformer != null)
                        Widgets().createTopLevelCard(
                          context: context,
                          title: "Main performer",
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => Profile(
                                        title: "Main performer",
                                        self: true,
                                        onProfileSaved: (user) {
                                          setState(() {
                                            _mainPerformer = user;
                                          });
                                        },
                                        friendMobile: _mainPerformer!.mobile,
                                      ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                _mainPerformer!.profilePicUrl,
                              ),
                            ),
                            title: Text(
                              "${_mainPerformer!.salutation} ${_mainPerformer!.name}",
                            ),
                            subtitle: Widgets().createResponsiveRow(context, [
                              Icon(Icons.phone),
                              Text(_mainPerformer!.mobile),
                              SizedBox(width: 4),
                              Icon(Icons.workspace_premium),
                              Text(_mainPerformer!.credentials),
                            ]),
                          ),
                        ),

                      // supporting team
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Supporting team",
                        child: Column(
                          children: [
                            Widgets().createTopLevelResponsiveContainer(
                              context,
                              List.generate(_supportingTeam.length, (index) {
                                return _createSupportingTeamTile(index);
                              }),
                            ),

                            // button - add supporting team
                            if (widget.readOnly == null)
                              TextButton(
                                onPressed: () async {
                                  await _showAddSupportTeamDialog(
                                    context: context,
                                  );
                                },
                                child: Text(
                                  _supportingTeam.isEmpty
                                      ? "Add supporting team"
                                      : "Add more members",
                                ),
                              ),
                          ],
                        ),
                      ),

                      // guests
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Guests",
                        child: Column(
                          children: [
                            Widgets().createTopLevelResponsiveContainer(
                              context,
                              List.generate(_guests.length, (index) {
                                return _createGuestTile(index);
                              }),
                            ),

                            // button
                            if (widget.readOnly == null)
                              TextButton(
                                onPressed: () {
                                  _showAddGuestDialog(context: context);
                                },
                                child: Text(
                                  _guests.isEmpty
                                      ? "Add guest"
                                      : "Add more guests",
                                ),
                              ),
                          ],
                        ),
                      ),

                      // list of songs
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "List of songs",
                        child: Column(
                          children: [
                            ...List.generate(_songs.length, (index) {
                              return _createSongTile(index);
                            }),

                            // button
                            if (_songs.length < 10 && widget.readOnly == null)
                              TextButton(
                                onPressed: () async {
                                  await _showAddSongDialog(context: context);
                                },
                                child: Text(
                                  _songs.isEmpty
                                      ? "Add song for event"
                                      : "Add more songs",
                                ),
                              ),
                          ],
                        ),
                      ),

                      // performer note
                      Widgets().createTopLevelCard(
                        context: context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Note:",
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
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
                      SizedBox(height: 20),
                      if (widget.readOnly == null)
                        ElevatedButton(
                          onPressed: _onSubmit,
                          child:
                              widget.oldEvent == null
                                  ? Text("Submit")
                                  : Text("Update"),
                        ),

                      // leave some space at bottom
                      // SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(image: "assets/images/Logo/SangeetSeva.png"),
      ],
    );
  }
}
