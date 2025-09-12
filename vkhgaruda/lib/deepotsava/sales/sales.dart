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
  SalesEntry? _lastAddedEntry;
  SalesEntry? _lastDeletedEntry;
  DateTime _selectedDate = DateTime.now();
  int _totalAmount = 0;

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
      _selectedDate = DateTime.now();

      // read database and populate counter
      String dbdate = DateFormat("yyyy-MM-dd").format(_selectedDate);
      String dbpath = "${Const().dbrootGaruda}/Deepotsava/Sales/$dbdate";
      int count = 0;
      _totalAmount = 0;
      FB().getList(path: dbpath).then((listRaw) {
        for (var item in listRaw) {
          SalesEntry entry =
              Utils().convertRawToDatatype(item, SalesEntry.fromJson);
          count += entry.count;
          _totalAmount += (entry.deepamPrice * entry.count);
          if (entry.isPlateIncluded) {
            _totalAmount += entry.platePrice;
          }
        }
        _counterSalesKey.currentState!.setCounterValue(count);

        setState(() {});
      });

      // listen for database events
      for (var listener in _listeners) {
        listener.cancel();
      }
      FB().listenForChange(
        dbpath,
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
              if (_lastAddedEntry != null && entry != _lastAddedEntry) {
                _addSales(entry);
              } else if (_lastAddedEntry == null) {
                _addSales(entry);
              }
              _lastAddedEntry = entry;
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
              SalesEntry entry =
                  Utils().convertRawToDatatype(data, SalesEntry.fromJson);
              if (_lastDeletedEntry != null && entry != _lastDeletedEntry) {
                _deleteSales(entry);
              } else if (_lastDeletedEntry == null) {
                _deleteSales(entry);
              }
              _lastDeletedEntry = entry;
            }
          },

          // get listeners
          getListeners: (listeners) {
            _listeners = listeners;
          },
        ),
      );
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  void _addSales(SalesEntry entry) {
    // update counter
    _counterSalesKey.currentState!.addCount(entry.count);

    setState(() {
      _totalAmount += (entry.deepamPrice * entry.count);
      if (entry.isPlateIncluded) {
        _totalAmount += entry.platePrice;
      }
    });
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

  void _deleteSales(SalesEntry entry) {
    // update counter
    int value = _counterSalesKey.currentState!.getCount();
    value -= entry.count;
    if (value < 0) {
      value = 0;
    }
    _counterSalesKey.currentState!.setCounterValue(value);

    setState(() {
      _totalAmount -= (entry.deepamPrice * entry.count);
      if (entry.isPlateIncluded) {
        _totalAmount -= entry.platePrice;
      }
      if (_totalAmount < 0) {
        _totalAmount = 0;
      }
    });
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
                                Text("Total Amount: ₹$_totalAmount",
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
