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
  DateTime _selectedDate = DateTime.now();
  final Set _loadedKeys = {};
  int _totalAmount = 0;
  final Map<String, dynamic> _amountPerMode = {
    "Cash": {
      "count": 0,
      "amount": 0,
    },
    "UPI": {
      "count": 0,
      "amount": 0,
    },
    "Card": {
      "count": 0,
      "amount": 0,
    },
    "Gift": {
      "count": 0,
      "amount": 0,
    },
  };

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
      await _initData(dbpath);

      // listen for database events
      _addFBListeners(dbpath);
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  void _addFBListeners(String dbpath) {
    for (var listener in _listeners) {
      listener.cancel();
    }
    FB().listenForChange(
      dbpath,
      FBCallbacks(
        // add
        add: (data) {
          // process the received data
          SalesEntry entry =
              Utils().convertRawToDatatype(data, SalesEntry.fromJson);

          // workaround to avoid duplicate entries during initial load
          if (_loadedKeys.contains(entry.timestamp)) {
            return;
          }
          _loadedKeys.add(entry.timestamp);

          _addSales(entry);
        },

        // edit
        edit: () {
          refresh();
        },

        // delete
        delete: (data) async {
          // process the received data
          SalesEntry entry =
              Utils().convertRawToDatatype(data, SalesEntry.fromJson);

          // workaround to avoid duplicate entries during initial load
          if (_loadedKeys.contains(entry.timestamp)) {
            _deleteSales(entry);
            _loadedKeys.remove(entry.timestamp);
          }
        },

        // get listeners
        getListeners: (listeners) {
          _listeners = listeners;
        },
      ),
    );
  }

  void _addSales(SalesEntry entry) {
    // update counter
    _counterSalesKey.currentState!.addCount(entry.count);

    // update total amount
    if (entry.paymentMode != "Gift") {
      _totalAmount += (entry.deepamPrice * entry.count);
      if (entry.isPlateIncluded) {
        _totalAmount += entry.platePrice;
      }
    }

    // update count and amount per mode
    _amountPerMode[entry.paymentMode]?['count'] =
        (_amountPerMode[entry.paymentMode]?['count'] ?? 0) + entry.count;
    if (entry.paymentMode != "Gift") {
      _amountPerMode[entry.paymentMode]?['amount'] =
          (_amountPerMode[entry.paymentMode]?['amount'] ?? 0) +
              (entry.deepamPrice * entry.count) +
              (entry.isPlateIncluded ? entry.platePrice : 0);
    }

    setState(() {});
  }

  Widget _createHMI(String paymentMode) {
    Color color =
        Const().paymentModes[paymentMode]?['color'] as Color? ?? Colors.grey;

    return Widgets().createTopLevelCard(
        context: context,
        title:
            "$paymentMode - count: ${_amountPerMode[paymentMode]?['count'] ?? 0}, amount: ₹${_amountPerMode[paymentMode]?['amount'] ?? 0}",
        color: color,
        child: HmiSales(
            paymentMode: paymentMode,
            onSubmit: (value) {
              Toaster().info(
                  "Added ${value.count} lamp${value.count > 1 ? 's' : ''}");
            }));
  }

  void _deleteSales(SalesEntry entry) {
    // update counter
    int value = _counterSalesKey.currentState!.getCount();
    value -= entry.count;
    if (value < 0) {
      value = 0;
    }
    _counterSalesKey.currentState!.setCounterValue(value);

    // update total amount
    if (entry.paymentMode != "Gift") {
      _totalAmount -= (entry.deepamPrice * entry.count);
      if (entry.isPlateIncluded) {
        _totalAmount -= entry.platePrice;
      }
      if (_totalAmount < 0) {
        _totalAmount = 0;
      }
    }

    // update count and amount per mode
    _amountPerMode[entry.paymentMode]?['count'] =
        (_amountPerMode[entry.paymentMode]?['count'] ?? 0) - entry.count;
    if (_amountPerMode[entry.paymentMode]?['count'] < 0) {
      _amountPerMode[entry.paymentMode]?['count'] = 0;
    }
    if (entry.paymentMode != "Gift") {
      _amountPerMode[entry.paymentMode]?['amount'] =
          (_amountPerMode[entry.paymentMode]?['amount'] ?? 0) -
              (entry.deepamPrice * entry.count) -
              (entry.isPlateIncluded ? entry.platePrice : 0);
      if (_amountPerMode[entry.paymentMode]?['amount'] < 0) {
        _amountPerMode[entry.paymentMode]?['amount'] = 0;
      }
    }

    setState(() {});
  }

  Future<void> _initData(String dbpath) async {
    List<dynamic> listRaw = await FB().getList(path: dbpath);
    // clear stuff befre loading data
    int count = 0;
    _totalAmount = 0;
    _amountPerMode.forEach((key, value) {
      value['count'] = 0;
      value['amount'] = 0;
    });
    _loadedKeys.clear();

    for (var item in listRaw) {
      SalesEntry entry =
          Utils().convertRawToDatatype(item, SalesEntry.fromJson);

      _loadedKeys.add(entry.timestamp);

      count += entry.count;

      // update total amount
      if (entry.paymentMode != "Gift") {
        _totalAmount += (entry.deepamPrice * entry.count);
        if (entry.isPlateIncluded) {
          _totalAmount += entry.platePrice;
        }
      }

      // set count and amount per mode
      _amountPerMode[entry.paymentMode]?['count'] =
          (_amountPerMode[entry.paymentMode]?['count'] ?? 0) + entry.count;
      if (entry.paymentMode != "Gift") {
        _amountPerMode[entry.paymentMode]?['amount'] =
            (_amountPerMode[entry.paymentMode]?['amount'] ?? 0) +
                (entry.deepamPrice * entry.count) +
                (entry.isPlateIncluded ? entry.platePrice : 0);
      }
    }

    // update the counter
    _counterSalesKey.currentState!.setCounterValue(count);
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

    List<String> paymentModes = ["Cash", "UPI", "Gift", "Card"];

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
