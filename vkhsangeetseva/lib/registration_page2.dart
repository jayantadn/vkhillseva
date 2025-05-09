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
  PerformerProfile? _eventResponsible;
  final _minSongs = 3;

  // lists
  final List<SupportUser> _performers = [];
  int _guests = 0;
  final List<String> _songs = [];

  // controllers, listeners and focus nodes
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _raagaController = TextEditingController();
  final TextEditingController _taalaController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _performers.clear();
    _songs.clear();

    // clear all controllers and focus nodes
    _titleController.dispose();
    _raagaController.dispose();
    _taalaController.dispose();
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
                    _eventResponsible = user;
                  });
                },
              );
            },
          ),
        );
      } else {
        _eventResponsible = PerformerProfile.fromJson(userdetailsJson);
      }

      // performers
      _performers.clear();
      _performers.add(SupportUser(
          salutation: _eventResponsible!.salutation,
          name: _eventResponsible!.name,
          friendMobile: _eventResponsible!.mobile,
          specialization: "Vocalist"));

      if (widget.oldEvent != null) {
        // populate the data structure
        EventRecord performanceRequest = widget.oldEvent!;

        // populate the lists
        _performers.addAll(performanceRequest.supportTeam);

        _guests = performanceRequest.guests;
        _songs.addAll(performanceRequest.songs);
        _noteController.text = performanceRequest.notePerformer;
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
      subtitle: (raaga.isNotEmpty && taala.isNotEmpty)
          ? Row(
              children: [
                Text("raaga: $raaga"),
                SizedBox(width: 10),
                Text("taala: $taala"),
              ],
            )
          : null,
      trailing: widget.readOnly != null
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

  Widget _createPerfomerTile(int index) {
    var member = _performers[index];
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
                Icon(
                  member.specialization == "Vocalist"
                      ? Icons.mic
                      : Icons.music_note,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(member.specialization),
              ],
            ),
          ],
        ),
      ),
      trailing: widget.readOnly != null
          ? null
          : Widgets().createContextMenu(["Edit", "Remove"], (
              String action,
            ) async {
              switch (action) {
                case "Edit":
                  await _showAddPerformerDialog(
                    context: context,
                    oldUser: member,
                  );
                  break;
                case "Remove":
                  setState(() {
                    _performers.removeAt(index);
                  });
                  break;
              }
            }),
    );
  }

  Widget _createGuestTile() {
    return ListTile(
      onTap: () {},
      title: Text("Number of guests: $_guests"),
      trailing: widget.readOnly != null
          ? null
          : Widgets().createContextMenu(["Edit", "Remove"], (
              String action,
            ) async {
              switch (action) {
                case "Edit":
                  await _showAddGuestDialog(
                    context: context,
                  );
                  break;
                case "Remove":
                  setState(() {
                    _guests = 0;
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

    // validate number of performers
    if (_performers.isEmpty) {
      Toaster().error("Please enter at least 1 performer");
      return;
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
      eventRequesterMobile: _eventResponsible!.mobile,
      supportTeam: _performers,
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
  }) async {
    FocusNode focusNode = FocusNode();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    int guests = _guests;

    // Request focus after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    await Widgets().showResponsiveDialog(
        context: context,
        title: "Number of guests",
        child: Form(
            key: formKey,
            child: TextFormField(
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              initialValue: guests.toString(),
              onChanged: (value) {
                guests = int.parse(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a valid number";
                }
                if (int.tryParse(value) == null) {
                  return "Please enter a valid number";
                }
                if (RegExp(
                  r'[!@#$%^&*(),.?":{}|<>]',
                ).hasMatch(value)) {
                  return "Special characters not allowed";
                }
                if (int.parse(value) < 0) {
                  return "Number of guests can't be negative";
                }
                return null;
              },
              onTap: () {
                // Select all text when the field gains focus
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  focusNode.requestFocus();
                  (focusNode.context as EditableTextState)
                      .selectAll(SelectionChangedCause.tap);
                });
              },
            )),
        actions: [
          // ok button
          ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                setState(() {
                  _guests = guests;
                });

                Navigator.pop(context);

                if (_guests + _performers.length > 10) {
                  Widgets().showMessage(context,
                      "Nominal charges for prasadam will apply for more than 10 members");
                }
              },
              child: Text("OK"))
        ]);
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    FocusNode focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    Widgets().showResponsiveDialog(
        context: context,
        title: "Add note for performer",
        child: Column(
          children: [
            TextField(
              focusNode: focusNode,
              maxLines: 3,
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "Enter your note here",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: Text("Save"),
          ),
        ]);
  }

  Future<void> _showAddSongDialog(
      {required BuildContext context, int? index}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    _titleController.clear();

    if (index != null) {
      var songDetails = _songs[index].split(":");
      _titleController.text = songDetails[0];
      _raagaController.text = songDetails[1];
      _taalaController.text = songDetails[2];
    }

    FocusNode focusNode = FocusNode();

    // Request focus after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    await Widgets().showResponsiveDialog(
      context: context,
      title: "Add song for event",
      child: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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

              SizedBox(height: 10),
              Row(
                children: [
                  // Raaga
                  Expanded(
                    child: TextFormField(
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
                  ),

                  // Taala
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
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
  }

  Future<void> _showAddPerformerDialog({
    required BuildContext context,
    SupportUser? oldUser,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    String salutation = SSConst().salutations.first;
    TextEditingController performerNameController = TextEditingController();
    TextEditingController otherController = TextEditingController();
    String specialization = "Vocalist";
    String other_specialization = "";

    // edit mode
    if (oldUser != null) {
      salutation = oldUser.salutation;
      performerNameController.text = oldUser.name;
      specialization = oldUser.specialization;
    }

    FocusNode focusNode = FocusNode();
    // Request focus after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    await Widgets().showResponsiveDialog(
      context: context,
      title: oldUser == null ? "Add performer" : "Edit performer",
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Row(
              children: [
                // salutation
                Expanded(
                  flex: 3, // 30% of the horizontal space
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Salutation"),
                    value: salutation.isNotEmpty
                        ? salutation
                        : SSConst().salutations.first,
                    items: SSConst().salutations.map((salutation) {
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
                      if (_performers.any((s) => s.name == value)) {
                        return "Member already exists";
                      }

                      return null;
                    },
                  ),
                ),

                SizedBox(width: 10), // Add some spacing between the widgets

                // name
                Expanded(
                  flex: 7, // Remaining 70% of the horizontal space
                  child: TextFormField(
                    controller: performerNameController,
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
                        r'[0-9!@#$%^&*(),;.?":{}|<>]',
                      ).hasMatch(value)) {
                        return "Numbers and special characters are not allowed";
                      }
                      if (oldUser == null &&
                          _performers
                              .any((performer) => performer.name == value)) {
                        return "Performer already exists";
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),

            // specialization
            SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Specialization"),
                      value: specialization,
                      items: [
                        "Vocalist",
                        ...SSConst().instrumentSkills,
                      ].map((specialization) {
                        return DropdownMenuItem<String>(
                          value: specialization,
                          child: Text(specialization),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          specialization = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please select a specialization";
                        }
                        return null;
                      },
                    ),

                    // other specialization
                    if (specialization == "Other")
                      TextFormField(
                        controller: otherController,
                        decoration:
                            InputDecoration(labelText: "Other specialization"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a specialization";
                          }
                          if (RegExp(
                            r'[0-9!@#$%^&*(),;.?":{}|<>]',
                          ).hasMatch(value)) {
                            return "Numbers and special characters are not allowed";
                          }
                          return null;
                        },
                        onChanged: (value) {
                          other_specialization = value;
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) {
              return;
            }

            Navigator.pop(context);

            SupportUser user = SupportUser(
              salutation: salutation,
              name: performerNameController.text,
              specialization: specialization == "Other"
                  ? other_specialization
                  : specialization,
              friendMobile: _eventResponsible!.mobile,
            );

            setState(() {
              if (oldUser == null) {
                _performers.add(user);
              } else {
                int index = _performers.indexOf(oldUser);
                if (index != -1) {
                  _performers[index] = user;
                }
              }
            });
          },
          child: Text(oldUser == null ? "Add" : "Update"),
        ),
      ],
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
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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

                    // event requester
                    if (_eventResponsible != null)
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Event requester",
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Profile(
                                  title: "Profile",
                                  self: true,
                                  onProfileSaved: (user) {
                                    setState(() {
                                      _eventResponsible = user;
                                    });
                                  },
                                  friendMobile: _eventResponsible!.mobile,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              _eventResponsible!.profilePicUrl,
                            ),
                          ),
                          title: Text(
                            "${_eventResponsible!.salutation} ${_eventResponsible!.name}",
                          ),
                          subtitle: Widgets().createResponsiveRow(context, [
                            Icon(
                              Icons.phone,
                              size: 16,
                            ),
                            Text(_eventResponsible!.mobile),
                            SizedBox(width: 4),
                            Icon(
                              Icons.workspace_premium,
                              size: 16,
                            ),
                            Text(_eventResponsible!.credentials),
                          ]),
                        ),
                      ),

                    // Performers
                    Widgets().createTopLevelCard(
                      context: context,
                      title: "Performers",
                      child: Column(
                        children: [
                          Widgets().createTopLevelResponsiveContainer(
                            context,
                            List.generate(_performers.length, (index) {
                              return _createPerfomerTile(index);
                            }),
                          ),

                          // guest count
                          if (_guests > 0) _createGuestTile(),

                          // button - add performer team
                          if (widget.readOnly == null)
                            TextButton(
                              onPressed: () async {
                                await _showAddPerformerDialog(
                                  context: context,
                                );
                              },
                              child: Text(
                                _performers.isEmpty
                                    ? "Add performer"
                                    : "Add more performers",
                              ),
                            ),

                          // button - add guest team
                          if (widget.readOnly == null && _guests == 0)
                            TextButton(
                              onPressed: () async {
                                await _showAddGuestDialog(
                                  context: context,
                                );
                              },
                              child: Text("Add guests"),
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
                      title: "Note from performer",
                      child: Column(
                        children: [
                          if (_noteController.text.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _noteController.text,
                              ),
                            ),
                          TextButton(
                            onPressed: () async {
                              await _showAddNoteDialog(context);
                            },
                            child: Text(
                              _noteController.text.isEmpty
                                  ? "Add some notes"
                                  : "Edit notes",
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
                        child: widget.oldEvent == null
                            ? Text("Submit")
                            : Text("Update"),
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
        if (_isLoading)
          LoadingOverlay(image: "assets/images/Logo/SangeetSeva.png"),
      ],
    );
  }
}
