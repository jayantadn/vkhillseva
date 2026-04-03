import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Accounting extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Accounting({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _AccountingState createState() => _AccountingState();
}

class _AccountingState extends State<Accounting> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  final Set _loadedKeys = {};
  int _selectedYear = DateTime.now().year;
  final int _totalLamps = 0;
  final int _totalAmount = 0;
  final int _amountCash = 0;
  final int _amountUPI = 0;
  final int _amountCard = 0;

  // lists

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps

    // dispose all controllers and focus nodes

    // listeners
    for (var listener in _listeners) {
      listener.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here

      // read database and populate data
      String dbdate = DateFormat("yyyy-MM-dd").format(DateTime.now());
      String dbpath = "${Const().dbrootGaruda}/Deepotsava/Accounting/$dbdate";
      await _initData(dbpath);

      // listen for database events
      _addListeners(dbpath);
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  void _addData(Map data) {
    setState(() {});
  }

  void _addListeners(String dbpath) {
    for (var listener in _listeners) {
      listener.cancel();
    }
    FB().listenForChange(
      dbpath,
      FBCallbacks(
        // add
        add: (data) {
          // workaround to avoid duplicate entries during initial load
          if (_loadedKeys.contains(data['timestamp'])) {
            return;
          }
          _loadedKeys.add(data['timestamp']);

          // process the received data
          _addData(data);
        },

        // edit
        edit: () {
          refresh();
        },

        // delete
        delete: (data) async {
          // workaround to avoid duplicate entries during initial load
          if (_loadedKeys.contains(data['timestamp'])) {
            _loadedKeys.remove(data['timestamp']);

            // process the received data
            _deleteData(data);
          }
        },

        // get listeners
        getListeners: (listeners) {
          _listeners = listeners;
        },
      ),
    );
  }

  void _deleteData(Map data) {
    setState(() {});
  }

  Future<void> _initData(String dbpath) async {}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveScaffold(
          // title
          title: widget.title,

          // toolbar icons
          toolbarActions: [],

          // body
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

                      // your widgets here

                      // year selector
                      YearHeader(
                        onYearChanged: (year) {
                          setState(() {
                            _selectedYear = year;
                          });
                        },
                      ),

                      // stall selector
                      SizedBox(height: 4),
                      RadioRow(
                          items: ["RKC", "RRG", "All"],
                          onChanged: (value) {
                            setState(() {
                              // handle stall selection
                            });
                          }),

                      // table of data
                      SizedBox(height: 10),
                      Widgets().createTopLevelCard(
                          context: context,
                          title: "Sale data",
                          child: Column(children: [
                            Widgets().createKVRow(
                                context, "Total lamps sold", "$_totalLamps",
                                bold: true),
                            Widgets().createKVRow(context,
                                "Total amount collected", "₹$_totalAmount"),
                            Widgets().createKVRow(context,
                                "Amount collected in cash", "₹$_amountCash"),
                            Widgets().createKVRow(context,
                                "Amount collected in UPI", "₹$_amountUPI"),
                            Widgets().createKVRow(context,
                                "Amount collected in card", "₹$_amountCard"),
                          ])),

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
        if (_isLoading) LoadingOverlay(image: widget.splashImage),
      ],
    );
  }
}
