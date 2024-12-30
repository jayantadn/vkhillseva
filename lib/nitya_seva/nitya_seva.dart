import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/common/datatypes.dart';
import 'package:vkhillseva/common/fb.dart';
import 'package:vkhillseva/common/toaster.dart';
import 'package:vkhillseva/nitya_seva/session.dart';
import 'package:vkhillseva/nitya_seva/ticket_page.dart';
import 'package:vkhillseva/widgets/common_widgets.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:vkhillseva/nitya_seva/day_summary.dart';
import 'package:vkhillseva/widgets/date_header.dart';
import 'package:vkhillseva/widgets/launcher_tile.dart';

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
        "NityaSeva/$dbDate",
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
    if (!spinner) {
      setState(() {
        _isLoading = true;
      });
    }

    // fetch festival sevas from db
    _sevaList.clear();
    dynamic data = await FB().getValue(path: "Settings/NityaSevaList");
    if (data != null) {
      for (var element in List<dynamic>.from(data)) {
        Map<String, dynamic> map = Map<String, dynamic>.from(element);
        _sevaList.add(FestivalSettings.fromJson(map));
      }
    }

    // put Nitya Seva at the top
    _sevaList.sort((a, b) {
      if (a.name == 'Morning Nitya Seva') return -1;
      if (b.name == 'Morning Nitya Seva') return 1;
      if (a.name == 'Evening Nitya Seva') return -1;
      if (b.name == 'Evening Nitya Seva') return 1;
      return 0;
    });

    // fetch session details from db
    _sessions.clear();
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    List<dynamic> sessions = await FB().getList(path: "NityaSeva/$dbDate");
    for (var element in sessions) {
      Map<String, dynamic> map = Map<String, dynamic>.from(element as Map);
      Map<String, dynamic> json =
          Map<String, dynamic>.from(map['Settings'] as Map);
      _sessions.add(Session.fromJson(json));
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
    if (now.hour < 9 || now.hour > 21) {
      errors.add("Outside service hours");
    }

    // validate duplicate session name
    for (var element in _sessions) {
      if (element.name == session.name) {
        errors.add("Duplicate session name");
        break;
      }
    }

    // check if last session was created recently
    if (_sessions.isNotEmpty) {
      Session lastSession = _sessions.last;
      if (lastSession.timestamp.difference(now).inHours < 3) {
        errors.add("Session created too recently");
      }
    }

    return errors;
  }

  void _postValidation(Session session) {
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    List<String> errors = [];

    refresh(spinner: false).then((_) async {
      Session lastSession = _sessions.last;
      if (lastSession.name == session.name &&
          lastSession.sevakarta == session.sevakarta) {
        lastSession = _sessions[_sessions.length - 2];
      }

      // validate duplicate session name
      if (session.name == lastSession.name) {
        errors.add("Duplicate session name");
      }

      // check if last session was created recently
      lastSession.timestamp;
      if (lastSession.timestamp.difference(lastSession.timestamp).inHours < 3) {
        errors.add("Session created too recently");
      }

      if (errors.isNotEmpty) {
        String? ret = await CommonWidgets()
            .createErrorDialog(context: context, errors: errors, post: true);
        if (ret == 'Edit') {
          _createEditSession(session: session);
        } else if (ret == 'Delete') {
          // delete locally
          setState(() {
            _sessions.remove(session);
          });

          // delete in server
          FB().deleteValue(path: "NityaSeva/$dbDate/${session.name}");

          Toaster().info("Session deleted");
        }
      }
    });
  }

  Future<void> _createEditSession({Session? session}) async {
    final double padding = 10.0;
    DateTime now = DateTime.now();
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // select default seva
    String selectedSeva = '';
    if (session == null) {
      if (now.hour < 14) {
        selectedSeva = _sevaList.first.name;
      } else {
        selectedSeva = _sevaList[1].name;
      }
    } else {
      selectedSeva = session.name;
    }

    // seva amount
    List<String> sevaAmounts = [];
    Const().nityaSeva['amounts']?.forEach((element) {
      element.forEach((key, value) {
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(session == null ? 'Add New Session' : 'Edit Session',
              style: Theme.of(context).textTheme.headlineMedium),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                // drop down for seva
                DropdownButtonFormField<String>(
                  value: selectedSeva, // Set the default value here
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

                // default amount
                SizedBox(height: padding),
                DropdownButtonFormField<String>(
                  value: sevaAmount, // Set the default value here
                  decoration: InputDecoration(labelText: 'Default seva amount'),
                  items: sevaAmounts.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    sevaAmount = newValue ?? sevaAmounts.first;
                  },
                ),

                // default payment mode
                SizedBox(height: padding),
                DropdownButtonFormField<String>(
                  value: paymentMode,
                  decoration:
                      InputDecoration(labelText: 'Default payment mode'),
                  items: paymentModes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    paymentMode = newValue ?? paymentModes.first;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                // clear all local lists
                sevaAmounts.clear();
                paymentModes.clear();

                // clear all local controllers and focus nodes

                // close the dialog
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(session == null ? 'Add' : 'Edit'),
              onPressed: () async {
                // find the icon for the selected seva
                String icon = '';
                for (var element in _sevaList) {
                  if (element.name == selectedSeva) {
                    icon = element.icon;
                    break;
                  }
                }

                // create a new session
                Session newSession = Session(
                  name: selectedSeva,
                  defaultAmount: int.parse(sevaAmount),
                  defaultPaymentMode: paymentMode,
                  icon: icon,
                  sevakarta: 'Guest',
                  timestamp: session == null ? now : session.timestamp,
                );

                // add session
                if (session == null) {
                  List<String> errors = _preValidation(newSession);
                  String? ret = 'Proceed';
                  if (errors.isNotEmpty) {
                    ret = await CommonWidgets()
                        .createErrorDialog(context: context, errors: errors);
                  }
                  if (errors.isEmpty || ret == 'Proceed') {
                    // push to db
                    FB().addToList(
                      path: "NityaSeva/$dbDate",
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
                  // edit session

                  // doing no validation for edit,
                  // as it may give false positive against the session being edited

                  // local edit
                  setState(() {
                    int index = _sessions
                        .indexWhere((s) => s.timestamp == session.timestamp);
                    if (index != -1) {
                      _sessions[index] = newSession;
                    }
                  });

                  // server edit
                  String dbTimestamp =
                      session.timestamp.toIso8601String().replaceAll(".", "^");
                  FB().editJson(
                      path: "NityaSeva/$dbDate/$dbTimestamp/Settings",
                      json: newSession.toJson());
                }

                // clear all local lists
                sevaAmounts.clear();
                paymentModes.clear();

                // clear all local controllers and focus nodes

                // close the dialog
                Navigator.of(context).pop();
              },
            ),
          ],
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
                _createEditSession(session: session);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                // confirmation dialog
                CommonWidgets().confirm(
                    context: context,
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
                      FB().deleteValue(path: "NityaSeva/$dbDate/$dbTimestamp");

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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
                title: CommonWidgets().customAppBarTitle(widget.title),
                actions: [
                  // TAS
                  IconButton(
                    icon: ClipOval(
                      child: Image.asset(
                        'assets/images/NityaSeva/tas.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    onPressed: () {
                      // navigate to add ticket page
                    },
                  ),

                  // laddu seva
                  IconButton(
                    icon: ClipOval(
                      child: Image.asset(
                        'assets/images/NityaSeva/laddu.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    onPressed: () {
                      // navigate to add ticket page
                    },
                  ),
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
                      _selectedDate = date;
                      refresh();
                    })),

                    // Session tiles
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._sessions.map((Session session) {
                            return GestureDetector(
                              onLongPress: () {
                                HapticFeedback.mediumImpact();
                                _createContextMenu(session);
                              },
                              child: LauncherTile2(
                                image: session.icon,
                                title: session.name,
                                text:
                                    "${session.sevakarta}, ${DateFormat('dd MMM, HH:mm').format(session.timestamp)}",
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

                          // add slot
                          LauncherTile2(
                            image: 'assets/images/Common/add.png',
                            title: 'New Session',
                            text: "Add a new session",
                            callback: LauncherTileCallback(onClick: () {
                              _createEditSession();
                            }),
                          ),
                        ],
                      ),
                    ),

                    // summary
                    DaySummary(date: _selectedDate),
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
