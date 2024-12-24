import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/common/datatypes.dart';
import 'package:vkhillseva/common/fb.dart';
import 'package:vkhillseva/nitya_seva/session.dart';
import 'package:vkhillseva/widgets/confirmation.dart';
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
              print("data edited");
              _lastCallbackInvoked = DateTime.now();
            }
          },

          // delete
          delete: (data) {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              print("data deleted: $data");
              _lastCallbackInvoked = DateTime.now();
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

    setState(() {
      _isLoading = false;
    });
  }

  Future<String?> _createErrorDialog(
      {required List<String> errors, bool post = false}) async {
    Completer<String?> completer = Completer<String?>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('ERROR',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(color: Colors.red)),
            ],
          ),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start, // Add this line
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("The following errors are detected:"),
                ),
                for (var error in errors)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(" - $error"),
                  ),
              ],
            ),
          ),
          actions: [
            // cancel button
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                completer.complete('Cancel');
              },
            ),

            // create button
            if (post == false)
              TextButton(
                child: Text('Create'),
                onPressed: () {
                  Navigator.of(context).pop();
                  completer.complete('Create');
                },
              ),

            // Edit button
            if (post == true)
              TextButton(
                child: Text('Edit'),
                onPressed: () {
                  Navigator.of(context).pop();
                  completer.complete('Edit');
                },
              ),

            // delete button
            if (post == true)
              TextButton(
                child: Text('Delete'),
                onPressed: () {
                  Navigator.of(context).pop();
                  completer.complete('Delete');
                },
              ),
          ],
        );
      },
    );

    return completer.future;
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

  void _postValidation() {
    List<String> errors = [];

    refresh(spinner: false).then((_) async {
      Session lastSession = _sessions.last;
      Session secondLastSession = _sessions[_sessions.length - 2];

      // validate duplicate session name
      if (lastSession.name == secondLastSession.name) {
        errors.add("Duplicate session name");
      }

      // check if last session was created recently
      lastSession.timestamp;
      if (lastSession.timestamp
              .difference(secondLastSession.timestamp)
              .inHours <
          3) {
        errors.add("Session created too recently");
      }

      if (errors.isNotEmpty) {
        String? ret = await _createErrorDialog(errors: errors, post: true);
        if (ret == 'Edit') {
          // TODO: edit the last session
        } else if (ret == 'Delete') {
          // TODO: delete the last session
        }
      }
    });
  }

  Future<void> _createSession() async {
    final double padding = 10.0;

    // select default seva
    String selectedSeva = '';
    DateTime now = DateTime.now();
    if (now.hour < 14) {
      selectedSeva = _sevaList.first.name;
    } else {
      selectedSeva = _sevaList[1].name;
    }

    // seva amount
    List<String> sevaAmounts = [];
    Const().nityaSeva['amounts']?.forEach((element) {
      element.forEach((key, value) {
        sevaAmounts.add(key);
      });
    });
    String sevaAmount = sevaAmounts.first;

    // payment mode
    List<String> paymentModes = [];
    Const().paymentModes.forEach(
      (key, value) {
        paymentModes.add(key);
      },
    );
    String paymentMode = paymentModes.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Session',
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
              child: Text('Add'),
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
                Session session = Session(
                  name: selectedSeva,
                  defaultAmount: int.parse(sevaAmount),
                  defaultPaymentMode: paymentMode,
                  icon: icon,
                  sevakarta: 'Guest',
                  timestamp: now,
                );

                // do validations, update state variable, push to db
                List<String> errors = _preValidation(session);
                String? ret = 'Create';
                if (errors.isNotEmpty) {
                  ret = await _createErrorDialog(errors: errors);
                }
                if (errors.isEmpty || ret == 'Create') {
                  // push to db
                  String dbDate = DateFormat('yyyy-MM-dd').format(now);
                  FB().addToList(
                    path: "NityaSeva/$dbDate",
                    child: "Settings",
                    data: session.toJson(),
                  );

                  setState(() {
                    _sessions.add(session);
                  });
                }

                // post validation
                _postValidation();

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
                // TODO: Implement edit functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                // // confirmation dialog
                // Confirmation().show(
                //     callbacks: ConfirmationCallbacks(onConfirm: () {
                //   // pre validations

                //   // delete locally
                //   setState(() {
                //     _sessions.remove(session);
                //   });

                //   // delete in server
                //   FB().deleteValue(path: "NityaSeva/$dbDate/${session.name}");

                //   // post validations

                //   // close the dialog
                //   // Navigator.of(context).pop();
                // }));
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
            ),
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

                    // slot tiles
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
                                  // open session details
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
                              _createSession();
                            }),
                          ),
                        ],
                      ),
                    ),

                    // summary
                    DaySummary(),
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
