import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/dashboard.dart';
import 'package:vkhgaruda/harinaam/datatypes.dart';
import 'package:vkhgaruda/harinaam/hmi_chanters.dart';
import 'package:vkhgaruda/harinaam/hmi_sales.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Harinaam extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Harinaam({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _HarinaamState createState() => _HarinaamState();
}

class _HarinaamState extends State<Harinaam> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  final GlobalKey<HmiChantersState> _keyHmiChanters =
      GlobalKey<HmiChantersState>();
  final GlobalKey<HmiSalesState> _keyHmiSales = GlobalKey<HmiSalesState>();
  final GlobalKey<DashboardState> _keyDashboard = GlobalKey<DashboardState>();
  DateTime _lastCallbackInvoked = DateTime.now();

  // lists
  final List<ChantersEntry> _chantersEntries = [];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    // listen to database events
    String dbdate = DateFormat("yyyy-MM-dd").format(_selectedDate);
    String dbpath = "${Const().dbrootGaruda}/Harinaam/$dbdate/Chanters";
    FB().listenForChange(
        dbpath,
        FBCallbacks(
          // add
          add: (data) {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();
            }

            // process the received data
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
          delete: (data) async {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              // process the received data
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
    // clear all lists and maps
    _chantersEntries.clear();

    // clear all controllers and focus nodes
    for (var element in _listeners) {
      element.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control
    bool allowed = await Utils().checkPermission("Harinaam Mantapa");
    if (!allowed && mounted) {
      Toaster().error("You are not allowed to access Harinaam");
      Navigator.of(context).pop();
    }

    await _lock.synchronized(() async {
      _chantersEntries.clear();

      String dbdate = DateFormat("yyyy-MM-dd").format(_selectedDate);
      String dbpath = "${Const().dbrootGaruda}/Harinaam/$dbdate/Chanters";
      Map<String, dynamic> chantersJson =
          await FB().getJson(path: dbpath, silent: true);
      int countChanters = 0;
      for (String key in chantersJson.keys) {
        ChantersEntry entry = Utils()
            .convertRawToDatatype(chantersJson[key], ChantersEntry.fromJson);
        countChanters += entry.count;
        _chantersEntries.add(entry);
      }
      _chantersEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _keyDashboard.currentState!.setChanters(countChanters);
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addChanters(ChantersEntry entry) async {
    setState(() {
      _isLoading = true;
    });

    // update counter
    _keyDashboard.currentState!.addChanters(entry.count);

    // add to the list
    setState(() {
      _chantersEntries.insert(0, entry);
    });

    // update database asynchronously
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/Harinaam/$dbdate/Chanters/$dbtime";
    FB().setJson(path: dbpath, json: entry.toJson());

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createChantersTile(int index) {
    ChantersEntry entry = _chantersEntries[index];
    return Align(
        alignment: Alignment.centerLeft,
        child: IntrinsicWidth(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.brown),
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).cardColor,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: ListTile(
                title: Text(DateFormat("HH:mm:ss").format(entry.timestamp)),
                leading: CircleAvatar(
                  backgroundColor: Colors.brown,
                  child: Text(entry.count.toString()),
                ),
                subtitle: Text(entry.username),
                trailing: Widgets().createContextMenu(
                  ["Edit", "Delete"],
                  (action) {
                    if (action == "Edit") {
                      _editChanters(index);
                    } else if (action == "Delete") {
                      _deleteChanters(index);
                    }
                  },
                ),
              ),
            ),
          ),
        ));
  }

  Future<void> _deleteChanters(int index) async {
    setState(() {
      _isLoading = true;
    });

    // confirm delete
    dynamic ret = await Widgets()
        .showConfirmDialog(context, "Are you sure?", "Delete", null);
    bool confirmed = ret == null ? false : true;

    if (!confirmed) return;

    // update dashboard counter
    int count = _keyDashboard.currentState!.getChanters();
    count -= _chantersEntries[index].count;
    _keyDashboard.currentState!.setChanters(count);

    // update database
    ChantersEntry entry = _chantersEntries[index];
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/Harinaam/$dbdate/Chanters/$dbtime";
    FB().deleteValue(path: dbpath);

    // remove from the list
    setState(() {
      _chantersEntries.removeAt(index);
      _isLoading = false;
    });
  }

  Future<ChantersEntry?> _showDialogEditChanters(ChantersEntry entry) async {
    final TextEditingController controller =
        TextEditingController(text: entry.count.toString());
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return await Widgets().showResponsiveDialog(
        context: context,
        child: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Count",
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Count cannot be empty';
              }

              final number = int.tryParse(value.trim());
              if (number == null) {
                return 'Please enter a valid number';
              }

              if (number <= 0) {
                return 'Count must be greater than 0';
              }

              if (number > 10000) {
                return 'Count cannot exceed 10,000';
              }

              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // close dialog without saving
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate form before saving
              if (formKey.currentState!.validate()) {
                // save changes - read from controller
                int count = int.parse(controller.text.trim());
                ChantersEntry editedEntry = ChantersEntry(
                  count: count,
                  timestamp: entry.timestamp,
                  username: Utils().getUsername(),
                );
                Navigator.of(context).pop(editedEntry);
              }
            },
            child: const Text("Save"),
          ),
        ]);
  }

  Future<void> _editChanters(int index) async {
    // get the entry to edit
    ChantersEntry entry = _chantersEntries[index];

    // Show the edit dialog
    ChantersEntry? editedEntry = await _showDialogEditChanters(entry);

    // If user saved changes, update the entry
    if (editedEntry != null) {
      // Update the list
      setState(() {
        _isLoading = true;
        _chantersEntries[index] = editedEntry;
      });

      // Update database (since timestamp doesn't change, we can update in place)
      String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
      String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
      String dbpath =
          "${Const().dbrootGaruda}/Harinaam/$dbdate/Chanters/$dbtime";
      FB().setJson(path: dbpath, json: editedEntry.toJson());

      // Update dashboard counter
      int totalCount = 0;
      for (ChantersEntry chanterEntry in _chantersEntries) {
        totalCount += chanterEntry.count;
      }
      _keyDashboard.currentState!.setChanters(totalCount);

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // stock japamala
              IconButton(
                icon: const Icon(Icons.playlist_add),
                onPressed: () {},
              ),

              // more actions
              Widgets().createContextMenu(
                ["Settlement", "Reports"],
                (action) {
                  // handle context menu actions
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

                      // counter display
                      Widgets().createTopLevelCard(
                        context: context,
                        child: Dashboard(key: _keyDashboard),
                      ),

                      // Chanters' club
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Chanters' club",
                        color: Colors.brown,
                        child: Column(
                          children: [
                            // HmiChanters widget
                            HmiChanters(
                                key: _keyHmiChanters,
                                onSubmit: (count) {
                                  // create a new entry
                                  ChantersEntry entry = ChantersEntry(
                                    count: count,
                                    timestamp: DateTime.now(),
                                    username: Utils().getUsername(),
                                  );
                                  _addChanters(entry);
                                }),

                            // chanters entries list
                            if (_chantersEntries.isNotEmpty)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(
                                    _chantersEntries.length,
                                    (index) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4.0),
                                      child: _createChantersTile(index),
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),

                      // Japamala sales
                      SizedBox(height: 10),
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Japamala sales",
                        child: Column(
                          children: [
                            HmiSales(key: _keyHmiSales),
                          ],
                        ),
                      ),

                      // leave some space at bottom
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
