import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vkhgaruda/nitya_seva/festival.dart';
import 'package:vkhgaruda/nitya_seva/laddu/laddu.dart';
import 'package:vkhgaruda/nitya_seva/session.dart';
import 'package:vkhgaruda/nitya_seva/tas/tas.dart';
import 'package:vkhgaruda/nitya_seva/ticket_page.dart';
import 'package:vkhgaruda/widgets/common_widgets.dart';
import 'package:vkhgaruda/nitya_seva/day_summary.dart';
import 'package:vkhgaruda/widgets/date_header.dart';
import 'package:vkhgaruda/widgets/launcher_tile.dart';
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

  // lists
  final List<FestivalSettings> _sevaList = [];
  final List<Session> _sessions = [];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    // listed to database events
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

    setState(() {
      _isLoading = false;
    });
  }

  List<String> _preValidation(Session session) {
    List<String> errors = [];

    // check if session is created during service time
    DateTime now = DateTime.now();
    if (now.hour < 10 || now.hour > 20) {
      errors.add("Outside service hours");
    }

    // check if last session was created recently
    bool isRecent = false;
    if (_sessions.isNotEmpty) {
      Session lastSession = _sessions.last;
      var diff = now.difference(lastSession.timestamp).inHours;
      if (diff < 3) {
        errors.add("Session created too recently");
        isRecent = true;
      }
    }

    // validate duplicate session name
    for (var element in _sessions) {
      if (element.name == session.name &&
          element.type == session.type &&
          isRecent) {
        errors.add("Duplicate session name");
        break;
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
        String? ret = await CommonWidgets()
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

  Future<void> _addEditSession({Session? session}) async {
    DateTime now = DateTime.now();
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // seva type
    String selectedSevaType = "Pushpanjali";

    // select default seva
    String selectedSeva = '';
    if (session == null) {
      selectedSeva = "Nitya Seva";
    } else {
      selectedSeva = session.name;
    }

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
    String sevaAmount = sevaAmounts.first;
    if (session != null) {
      sevaAmount = session.defaultAmount.toString();
    }

    // payment mode
    List<String> paymentModes = [];
    Const().paymentModes.forEach(
      (key, value) {
        paymentModes.add(key);
      },
    );
    String paymentMode = paymentModes.first;
    if (session != null) {
      paymentMode = session.defaultPaymentMode;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session == null ? 'Add New Session' : 'Edit Session',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 16.0),
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Row(
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
                                      ? accentColor
                                      : Colors.transparent,
                                  border: Border.all(color: accentColor),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  "Pushpanjali",
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: selectedSevaType == "Pushpanjali"
                                            ? Colors.white
                                            : accentColor,
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
                                      ? accentColor
                                      : Colors.transparent,
                                  border: Border(
                                    top: BorderSide(color: accentColor),
                                    right: BorderSide(color: accentColor),
                                    bottom: BorderSide(color: accentColor),
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  "Kumkum Archana",
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color:
                                            selectedSevaType == "Kumkum Archana"
                                                ? Colors.white
                                                : accentColor,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // select seva
                  SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    value: selectedSeva,
                    decoration: InputDecoration(labelText: 'Seva'),
                    items: _sevaList.map((FestivalSettings value) {
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
                          decoration:
                              InputDecoration(labelText: 'Default seva amount'),
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
                          decoration: InputDecoration(
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
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          sevaAmounts.clear();
                          paymentModes.clear();
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text(session == null ? 'Add' : 'Edit'),
                        onPressed: () async {
                          String icon = '';
                          for (var element in _sevaList) {
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
                            sevakarta: _username,
                            timestamp:
                                session == null ? now : session.timestamp,
                          );

                          if (session == null) {
                            List<String> errors = _preValidation(newSession);
                            String? ret = 'Proceed';
                            if (errors.isNotEmpty) {
                              ret = await CommonWidgets().createErrorDialog(
                                  context: context, errors: errors);
                            }
                            if (errors.isEmpty || ret == 'Proceed') {
                              FB().addMapToList(
                                path:
                                    "${Const().dbrootGaruda}/NityaSeva/$dbDate",
                                child: "Settings",
                                data: newSession.toJson(),
                              );

                              setState(() {
                                _sessions.add(newSession);
                              });
                            }
                            if (errors.isEmpty) {
                              _postValidation(newSession);
                            }
                          } else {
                            setState(() {
                              int index = _sessions.indexWhere(
                                  (s) => s.timestamp == session.timestamp);
                              if (index != -1) {
                                _sessions[index] = newSession;
                              }
                            });

                            String dbTimestamp = session.timestamp
                                .toIso8601String()
                                .replaceAll(".", "^");
                            FB().editJson(
                                path:
                                    "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbTimestamp/Settings",
                                json: newSession.toJson());
                          }

                          sevaAmounts.clear();
                          paymentModes.clear();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _createContextMenu(Session session) {
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () {
                Navigator.of(context).pop();
                _addEditSession(session: session);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                // confirmation dialog
                CommonWidgets().confirm(
                    context: context,
                    msg: 'Are you sure you want to delete this session?',
                    callbacks: ConfirmationCallbacks(onConfirm: () {
                      // TODO: pre validations e.g. for admin only

                      // delete locally
                      setState(() {
                        _sessions.remove(session);
                      });

                      // delete in server
                      String dbTimestamp = session.timestamp
                          .toIso8601String()
                          .replaceAll(".", "^");
                      FB().deleteValue(
                          path:
                              "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbTimestamp");

                      // close the dialog
                      Navigator.of(context).pop();
                    }));
              },
            ),
          ],
        );
      },
    );
  }

  void _onDateChange(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text(widget.title), actions: [
              // settings button
              IconButton(
                icon: Icon(
                  Icons.settings,
                  size: 32,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Settings(title: 'Settings')),
                  );
                },
              ),

              // menu button
              CommonWidgets().createPopupMenu([
                // festival record
                MyPopupMenuItem(
                    text: "Festival Record",
                    icon: Icons.temple_hindu,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FestivalRecord(
                                title: "Festival record",
                                icon:
                                    'assets/images/LauncherIcons/NityaSeva.png')),
                      );
                    }),
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

                    // other apps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // TAS
                        LauncherTile(
                          title: "Tulasi Archana",
                          image: 'assets/images/NityaSeva/tas.png',
                          scale: 0.75,
                          callback: LauncherTileCallback(onClick: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TAS(title: "Tulasi Archana Seva"),
                              ),
                            );
                          }),
                        ),

                        // Laddu seva
                        LauncherTile(
                          title: "Laddu distribution",
                          image: 'assets/images/NityaSeva/laddu.png',
                          scale: 0.75,
                          callback: LauncherTileCallback(onClick: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LadduMain(),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),

                    // summary
                    DaySummary(date: _selectedDate),

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
                    ..._sessions.map((Session session) {
                      return GestureDetector(
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          _createContextMenu(session);
                        },
                        child: LauncherTile2(
                          imageLeading: session.icon,
                          imageTrailing: session.timestamp.hour < 14
                              ? 'assets/images/Common/morning.png'
                              : 'assets/images/Common/evening.png',
                          title: session.name,
                          text:
                              "${session.sevakarta}, ${session.timestamp.hour < 14 ? 'Morning' : 'Evening'} ${session.type}, ${DateFormat('HH:mm').format(session.timestamp)}",
                          callback: LauncherTileCallback(onClick: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TicketPage(
                                  session: session,
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),

                    // leave some bottom spacing
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Add session
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _addEditSession();
              },
              child: Icon(Icons.add, size: Const().toolbarIconSize),
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
