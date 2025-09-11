import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/deepotsava/datatypes.dart';
import 'package:vkhgaruda/deepotsava/sales/hmi_sales.dart';
import 'package:vkhgaruda/deepotsava/sales/log.dart';
import 'package:vkhgaruda/deepotsava/sales/summary.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Sales extends StatefulWidget {
  final String title;
  final String? splashImage;
  final String stall;

  const Sales(
      {super.key, required this.title, this.splashImage, required this.stall});

  @override
  // ignore: library_private_types_in_public_api
  _SalesState createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  final GlobalKey<CounterDisplayState> _counterSalesKey =
      GlobalKey<CounterDisplayState>();
  DateTime _lastDataModification = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  SalesEntry? _lastEntry;

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

      // listen for database events
      String dateStr = DateFormat("yyyy-MM-dd").format(_selectedDate);
      for (var listener in _listeners) {
        listener.cancel();
      }
      FB().listenForChange(
        "${Const().dbrootGaruda}/Deepotsava/Sales/$dateStr",
        FBCallbacks(
          // add
          add: (data) {
            if (_lastDataModification.isBefore(
              DateTime.now()
                  .subtract(Duration(seconds: Const().fbListenerDelay)),
            )) {
              _lastDataModification = DateTime.now();

              // process the received data
              SalesEntry entry =
                  Utils().convertRawToDatatype(data, SalesEntry.fromJson);
              if (_lastEntry != null && entry != _lastEntry) {
                _addSales(entry);
              } else if (_lastEntry == null) {
                _addSales(entry);
              }
              _lastEntry = entry;
            }
          },

          // edit
          edit: () {
            if (_lastDataModification.isBefore(
              DateTime.now()
                  .subtract(Duration(seconds: Const().fbListenerDelay)),
            )) {
              _lastDataModification = DateTime.now();

              refresh();
            }
          },

          // delete
          delete: (data) async {
            if (_lastDataModification.isBefore(
              DateTime.now()
                  .subtract(Duration(seconds: Const().fbListenerDelay)),
            )) {
              _lastDataModification = DateTime.now();

              // process the received data
            }
          },

          // get listeners
          getListeners: (listeners) {
            _listeners = listeners;
          },
        ),
      );

      // read database and populate counter
      String dbdate = DateFormat("yyyy-MM-dd").format(DateTime.now());
      String dbpath = "${Const().dbrootGaruda}/Deepotsava/Sales/$dbdate";
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  void _addSales(SalesEntry entry) {
    // update counter
    _counterSalesKey.currentState!.addCount(entry.count);
  }

  Widget _createHMI(String paymentMode) {
    Color color =
        Const().paymentModes[paymentMode]?['color'] as Color? ?? Colors.grey;

    return Widgets().createTopLevelCard(
        context: context,
        title: "$paymentMode - count: 0, amount: ₹0",
        color: color,
        child: HmiSales(paymentMode: paymentMode, onSubmit: (value) {}));
  }

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (widget.stall == "RKC") {
      color = Colors.pink;
    } else if (widget.stall == "RRG") {
      color = Colors.black;
    }
    ThemeData theme = ThemeCreator(primaryColor: color ?? Colors.grey).create();

    List<String> paymentModes = Const().paymentModes.keys.toList();

    return Theme(
      data: theme,
      child: Stack(
        children: [
          ResponsiveScaffold(
            // title
            title: widget.title,

            // toolbar icons
            toolbarActions: [
              // summary
              ResponsiveToolbarAction(
                icon: const Icon(Icons.article),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Summary(
                              title: "Summary",
                              splashImage: widget.splashImage)));
                },
              ),

              // entry logs
              ResponsiveToolbarAction(
                icon: const Icon(Icons.receipt_long),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Log(
                              title: "Entry Logs",
                              splashImage: widget.splashImage)));
                },
              ),
            ],

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
                        SizedBox(height: 10),

                        // your widgets here

                        // dashboard
                        Widgets().createTopLevelCard(
                            context: context,
                            title: "Total Sales",
                            color: color ?? Colors.grey,
                            child: Column(
                              children: [
                                CounterDisplay(
                                    key: _counterSalesKey,
                                    fontSize: 48,
                                    maxValue: 9999,
                                    color: color ?? Colors.grey),
                                Text("Total Amount: ₹0",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                              ],
                            )),

                        // all HMIs
                        SizedBox(height: 10),
                        ...List.generate(paymentModes.length, (index) {
                          return _createHMI(paymentModes[index]);
                        }),

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
      ),
    );
  }
}
