import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhgaruda/nitya_seva/festival_by_event.dart';
import 'package:vkhgaruda/nitya_seva/festival_by_year.dart';
import 'package:vkhgaruda/nitya_seva/laddu/laddu.dart';
import 'package:vkhgaruda/nitya_seva/ticket_page.dart';
import 'package:vkhgaruda/widgets/common_widgets.dart';
import 'package:vkhgaruda/nitya_seva/day_summary.dart';
import 'package:vkhgaruda/home/settings.dart';
import 'package:vkhpackages/vkhpackages.dart';

class NityaSeva extends StatefulWidget {
  final String title;

  const NityaSeva({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _NityaSevaState createState() => _NityaSevaState();
}

class _NityaSevaState extends State<NityaSeva> {
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  DateTime _lastCallbackInvoked = DateTime.now();
  String _username = "Guest";
  bool _isAdmin = false;

  // lists
  final List<FestivalSettings> _sevaList = [];
  final List<Session> _sessions = [];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    // auto lock any old open session
    _autoLockOldSessions();

    // listen to database events
    _addFBListeners();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _sevaList.clear();
    _sessions.clear();

    // clear all controllers and focus nodes
    for (var listener in _listeners) {
      listener.cancel();
    }

    super.dispose();
  }

  Future<void> refresh({bool spinner = true}) async {
    if (spinner) {
      setState(() {
        _isLoading = true;
      });
    }

    _username = Utils().getUsername();
    _isAdmin = await Utils().isAdmin();

    // show tutorials

    // admin tutorial


    // fetch festival sevas from db
    _sevaList.clear();
    dynamic data = await FB()
        .getValue(path: "${Const().dbrootGaruda}/Settings/NityaSevaList");
    if (data != null) {
      for (var element in List<dynamic>.from(data)) {
        Map<String, dynamic> map = Map<String, dynamic>.from(element);
        _sevaList.add(FestivalSettings.fromJson(map));
      }
    }

    // fetch session details from db
    _sessions.clear();
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    List<dynamic> sessions =
        await FB().getList(path: "${Const().dbrootGaruda}/NityaSeva/$dbDate");
    for (var session in sessions) {
      Map<String, dynamic> map = Map<String, dynamic>.from(session as Map);
      if (map['Settings'] != null) {
        Map<String, dynamic> json =
            Map<String, dynamic>.from(map['Settings'] as Map);
        _sessions.add(Session.fromJson(json));
      }
    }
    _sessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addEditSession({Session? session}) async {
    DateTime now = DateTime.now();
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // seva amount
    List<String> sevaAmounts = [];
    Const().nityaSeva['amounts']?.forEach((element) {
      element.forEach((key, value) {
        // skip the obsolete amounts
        if (value['obsolete'] == true) {
          return;
        }

        sevaAmounts.add(key);
      });
    });

    // payment mode
    List<String> paymentModes = [];
    Const().paymentModes.forEach(
      (key, value) {
        paymentModes.add(key);
      },
    );

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation animation,
          Animation secondaryAnimation) {
        return AddEditSessionDialog(
          session: session,
          sevaList: _sevaList,
          sevaAmounts: sevaAmounts,
          paymentModes: paymentModes,
          username: _username,
          now: now,
          dbDate: dbDate,
          onAddOrUpdate: (Session newSession) async {
            if (session == null) {
              List<String> errors = _preValidation(newSession);
              String? ret = 'Proceed';
              if (errors.isNotEmpty) {
                ret = await NSWidgetsOld()
                    .createErrorDialog(context: context, errors: errors);
              }
              if (errors.isEmpty || ret == 'Proceed') {
                await FB().addMapToList(
                  path: "${Const().dbrootGaruda}/NityaSeva/$dbDate",
                  child: "Settings",
                  data: newSession.toJson(),
                );
                setState(() {
                  _sessions.add(newSession);
                });
                String path = "${Const().dbrootGaruda}/NityaSeva/OpenSessions";
                String data =
                    newSession.timestamp.toIso8601String().replaceAll(".", "^");
                if (await FB().pathExists(path)) {
                  await FB().addToList(listpath: path, data: data);
                } else {
                  await FB().setValue(path: path, value: [data]);
                }
              }
              if (errors.isEmpty) {
                _postValidation(newSession);
              }
            } else {
              setState(() {
                int index = _sessions
                    .indexWhere((s) => s.timestamp == session.timestamp);
                if (index != -1) {
                  _sessions[index] = newSession;
                }
              });
              String dbTimestamp =
                  session.timestamp.toIso8601String().replaceAll(".", "^");
              await FB().editJson(
                path:
                    "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbTimestamp/Settings",
                json: newSession.toJson(),
              );
            }
          },
        );
      },
    );
  }

  void _addFBListeners() {
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    FB().listenForChange(
        "${Const().dbrootGaruda}/NityaSeva/$dbDate",
        FBCallbacks(
          // add
          add: (data) {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              Map<String, dynamic> map = Map<String, dynamic>.from(data);
              Map<String, dynamic> json =
                  Map<String, dynamic>.from(map['Settings']);
              Session session = Session.fromJson(json);
              bool exists = false;
              for (var element in _sessions) {
                if (element.name == session.name) {
                  exists = true;
                  break;
                }
              }
              if (!exists) {
                setState(() {
                  _sessions.add(session);
                });
              }
            }
          },

          // edit
          edit: () {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              refresh();
            }
          },

          // delete
          delete: (data) {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              // process the received data
              Map<String, dynamic> map = Map<String, dynamic>.from(data);
              if (map['Settings'] != null) {
                Map<String, dynamic> json =
                    Map<String, dynamic>.from(map['Settings']);
                Session session = Session.fromJson(json);

                setState(() {
                  int index = _sessions
                      .indexWhere((s) => s.timestamp == session.timestamp);
                  if (index != -1) {
                    _sessions.removeAt(index);
                  }
                });
              }
            }
          },

          // get listeners
          getListeners: (listeners) {
            _listeners = listeners;
          },
        ));
  }

  Future<void> _autoLockOldSessions() async {
    String dbpath = "${Const().dbrootGaruda}/NityaSeva/OpenSessions";
    List openSessions = await FB().getList(path: dbpath);
    List openSessionsNew = [];
    if (openSessions.isNotEmpty) {
      for (var element in openSessions) {
        String dbTimestamp = element.toString().replaceAll("^", ".");
        DateTime timestamp = DateTime.parse(dbTimestamp);
        if (timestamp.isBefore(DateTime.now()
            .subtract(Duration(hours: Const().sessionLockDuration)))) {
          String dbDate = DateFormat('yyyy-MM-dd').format(timestamp);
          String dbpathSession =
              "${Const().dbrootGaruda}/NityaSeva/$dbDate/$element";

          if (mounted) {
            await Utils().lockSession(
                context: context, sessionPath: dbpathSession, silent: true);

            Toaster().info(
              "Session Autolocked: ${element.toString()}",
            );
          }
        } else {
          openSessionsNew.add(element);
        }
      }
      if (openSessionsNew.isNotEmpty) {
        FB().setValue(path: dbpath, value: openSessionsNew);
      } else {
        FB().deleteValue(path: dbpath);
      }
    }
  }

  Widget _createSessionTile(int index) {
    Session session = _sessions[index];
    return Widgets().createTopLevelCard(
        context: context,
        child: ListTile(
            leading: session.icon.isNotEmpty
                ? ClipOval(
                    child: Image.asset(
                      session.icon,
                    ),
                  )
                : null,
            title: Text(session.name),
            subtitle: Text(
                "${session.sevakarta}, ${session.timestamp.hour < 14 ? 'Morning' : 'Evening'} ${session.type}, ${DateFormat('HH:mm').format(session.timestamp)}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketPage(
                    session: session,
                  ),
                ),
              );
            },
            trailing: (session.sessionLock != null &&
                    session.sessionLock!.isLocked)
                ? IconButton(
                    onPressed: () async {
                      String dbDate =
                          DateFormat('yyyy-MM-dd').format(_selectedDate);
                      String key = session.timestamp
                          .toIso8601String()
                          .replaceAll(".", "^");
                      await Utils().unlockSession(
                          context: context,
                          sessionPath:
                              "${Const().dbrootGaruda}/NityaSeva/$dbDate/$key");
                    },
                    icon: Icon(Icons.lock))
                : Widgets().createContextMenu(["Edit", "Delete", "Lock"],
                    (String value) {
                    if (value == "Edit") {
                      _addEditSession(session: session);
                    } else if (value == "Delete") {
                      String dbDate =
                          DateFormat('yyyy-MM-dd').format(_selectedDate);

                      // confirmation dialog
                      NSWidgetsOld().confirm(
                          context: context,
                          msg: 'Are you sure you want to delete this session?',
                          callbacks: ConfirmationCallbacks(onConfirm: () async {
                            // delete locally
                            setState(() {
                              _sessions.remove(session);
                            });

                            // delete in server
                            String dbTimestamp = session.timestamp
                                .toIso8601String()
                                .replaceAll(".", "^");
                            await FB().deleteValue(
                                path:
                                    "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbTimestamp");

                            // delete from open sessions
                            List openSessions = await FB().getList(
                                path:
                                    "${Const().dbrootGaruda}/NityaSeva/OpenSessions");
                            openSessions.remove(dbTimestamp);
                            await FB().setValue(
                                path:
                                    "${Const().dbrootGaruda}/NityaSeva/OpenSessions",
                                value: openSessions);
                          }));
                    } else if (value == "Lock") {
                      String dbDate =
                          DateFormat('yyyy-MM-dd').format(_selectedDate);
                      String key = session.timestamp
                          .toIso8601String()
                          .replaceAll(".", "^");
                      Utils().lockSession(
                          context: context,
                          sessionPath:
                              "${Const().dbrootGaruda}/NityaSeva/$dbDate/$key",
                          username: _username);
                    } else {
                      if (value.isNotEmpty) {
                        Toaster().error("Unknown action: $value");
                      }
                    }
                  })));
  }

  List<String> _preValidation(Session session) {
    List<String> errors = [];

    // check if session is created during service time
    DateTime now = DateTime.now();
    if (now.hour < 10 || now.hour > 20) {
      errors.add("Outside service hours");
    }

    // check if last session was created recently
    if (_sessions.isNotEmpty) {
      Session lastSession = _sessions.last;
      var diff = now.difference(lastSession.timestamp).inHours;
      if (diff < 3) {
        errors.add("Session created too recently");
      }
    }

    // check if session is created for today
    if (_selectedDate.day != now.day ||
        _selectedDate.month != now.month ||
        _selectedDate.year != now.year) {
      errors.add("Session created in older date");
    }

    return errors;
  }

  void _postValidation(Session session) {
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    List<String> errors = [];

    refresh(spinner: false).then((_) async {
      Session lastSession = _sessions.last;

      if (_sessions.length > 1) {
        if (lastSession.name == session.name &&
            lastSession.sevakarta == session.sevakarta) {
          lastSession = _sessions[_sessions.length - 2];
        }

        // check if last session was created recently
        bool isRecent = false;
        if (session.timestamp.difference(lastSession.timestamp).inHours < 3) {
          errors.add("Session created too recently");
          isRecent = true;
        }

        // validate duplicate session name
        if (session.name == lastSession.name &&
            lastSession.type == session.type &&
            isRecent) {
          errors.add("Duplicate session name");
        }
      }

      if (errors.isNotEmpty) {
        String? ret = await NSWidgetsOld()
            .createErrorDialog(context: context, errors: errors, post: true);
        if (ret == 'Edit') {
          _addEditSession(session: session);
        } else if (ret == 'Delete') {
          // delete locally
          setState(() {
            _sessions.remove(session);
          });

          // delete in server
          FB().deleteValue(
              path:
                  "${Const().dbrootGaruda}/NityaSeva/$dbDate/${session.name}");

          Toaster().info("Session deleted");
        }
      }
    });
  }

  void _onDateChange(DateTime date) {
    setState(() {
      _selectedDate = date;
      _addFBListeners();
    });
    refresh();
  }

  Future<void> _onFestivalRecord() async {
    await Widgets().showResponsiveDialog(
        context: context,
        child: Column(
          children: [
            // view by year
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FestivalRecordByYear(
                            title: "Festival record",
                            icon: 'assets/images/LauncherIcons/NityaSeva.png')),
                  );
                },
                child: Text("View by year")),

            // view by event
            SizedBox(height: 8),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FestivalRecordByEvent(
                            title: "Festival record",
                            splashImage:
                                'assets/images/LauncherIcons/NityaSeva.png')),
                  );
                },
                child: Text("View by event")),
          ],
        ),
        actions: []);
  }

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();

    return Theme(
      data: themeGaruda,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text(widget.title), actions: [
              // add session button
              if (_selectedDate.day == today.day &&
                  _selectedDate.month == today.month &&
                  _selectedDate.year == today.year)
                IconButton(
                  icon: Icon(
                    Icons.add,
                    size: 32,
                  ),
                  onPressed: _addEditSession,
                ),

              // menu button
              NSWidgetsOld().createPopupMenu([
                // laddu
                MyPopupMenuItem(
                    text: "Laddu seva",
                    icon: Icons
                        .card_giftcard, // Replace with an appropriate IconData
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LadduMain(),
                        ),
                      );
                    }),

                // festival record
                MyPopupMenuItem(
                    text: "Festival Record",
                    icon: Icons.temple_hindu,
                    onPressed: _onFestivalRecord),
              ]),
            ]),
            body: Padding(
              padding: const EdgeInsets.all(4.0),
              child: RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                  children: [
                    // date header
                    DateHeader(callbacks:
                        DateHeaderCallbacks(onChange: (DateTime date) {
                      _onDateChange(date);
                    })),

                    // prompt if no sessions
                    if (_sessions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Click '+' to add a new session",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),

                    // Session tiles
                    ...List.generate(_sessions.length, (index) {
                      return _createSessionTile(index);
                    }),

                    // summary
                    DaySummary(date: _selectedDate),

                    // leave some bottom spacing
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(image: 'assets/images/LauncherIcons/NityaSeva.png'),
        ],
      ),
    );
  }
}

class AddEditSessionDialog extends StatefulWidget {
  final Session? session;
  final List<FestivalSettings> sevaList;
  final List<String> sevaAmounts;
  final List<String> paymentModes;
  final String username;
  final DateTime now;
  final String dbDate;
  final Function(Session) onAddOrUpdate;

  const AddEditSessionDialog({
    Key? key,
    required this.session,
    required this.sevaList,
    required this.sevaAmounts,
    required this.paymentModes,
    required this.username,
    required this.now,
    required this.dbDate,
    required this.onAddOrUpdate,
  }) : super(key: key);

  @override
  State<AddEditSessionDialog> createState() => _AddEditSessionDialogState();
}

class _AddEditSessionDialogState extends State<AddEditSessionDialog> {
  late String selectedSevaType;
  late String selectedSeva;
  late String sevaAmount;
  late String paymentMode;
  late List<String> sevaAmounts;
  late List<String> paymentModes;

  @override
  void initState() {
    super.initState();
    selectedSevaType = widget.session?.type ?? "Pushpanjali";
    selectedSeva = widget.session?.name ?? "Nitya Seva";
    sevaAmounts = List<String>.from(widget.sevaAmounts);
    sevaAmount = widget.session?.defaultAmount.toString() ?? sevaAmounts.first;
    paymentModes = List<String>.from(widget.paymentModes);
    paymentMode = widget.session?.defaultPaymentMode ?? paymentModes.first;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 32),
                Text(
                  widget.session == null ? 'Add New Session' : 'Edit Session',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSevaType = "Pushpanjali";
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedSevaType == "Pushpanjali"
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                                color: Theme.of(context).colorScheme.primary),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            "Pushpanjali",
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: selectedSevaType == "Pushpanjali"
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSevaType = "Kumkum Archana";
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedSevaType == "Kumkum Archana"
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            border: const Border(
                              top: BorderSide(color: Colors.blue),
                              right: BorderSide(color: Colors.blue),
                              bottom: BorderSide(color: Colors.blue),
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            "Kumkum Archana",
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: selectedSevaType == "Kumkum Archana"
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: selectedSeva,
                  decoration: const InputDecoration(labelText: 'Seva'),
                  items: widget.sevaList.map((FestivalSettings value) {
                    return DropdownMenuItem<String>(
                      value: value.name,
                      child: Text(value.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      if (newValue != null) {
                        selectedSeva = newValue;
                      }
                    });
                  },
                ),
                SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: sevaAmount,
                        decoration: const InputDecoration(
                            labelText: 'Default seva amount'),
                        items: sevaAmounts.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            sevaAmount = newValue ?? sevaAmounts.first;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: paymentMode,
                        decoration: const InputDecoration(
                            labelText: 'Default payment mode'),
                        items: paymentModes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            paymentMode = newValue ?? paymentModes.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          sevaAmounts.clear();
                          paymentModes.clear();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        child: Text(widget.session == null ? 'Add' : 'Update'),
                        onPressed: () {
                          String icon = '';
                          for (var element in widget.sevaList) {
                            if (element.name == selectedSeva) {
                              icon = element.icon;
                              break;
                            }
                          }
                          Session newSession = Session(
                            name: selectedSeva,
                            type: selectedSevaType,
                            defaultAmount: int.parse(sevaAmount),
                            defaultPaymentMode: paymentMode,
                            icon: icon,
                            sevakarta: widget.username,
                            timestamp: widget.session == null
                                ? widget.now
                                : widget.session!.timestamp,
                          );
                          widget.onAddOrUpdate(newSession);
                          sevaAmounts.clear();
                          paymentModes.clear();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
