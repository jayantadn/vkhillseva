import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/nitya_seva/laddu/datatypes.dart';
import 'package:vkhgaruda/nitya_seva/laddu/fbl.dart';
import 'package:vkhgaruda/nitya_seva/laddu/laddu_settings.dart';
import 'package:vkhpackages/vkhpackages.dart';

class LadduMain extends StatefulWidget {
  final String title;
  final String? splashImage;

  const LadduMain({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _LadduState createState() => _LadduState();
}

class _LadduState extends State<LadduMain> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  final Set _loadedKeys = {};

  // global keys
  final GlobalKey<SingleBarChartState> _keySingleBarChart =
      GlobalKey<SingleBarChartState>();
  final GlobalKey<KVTableState> _keyKVTable = GlobalKey<KVTableState>();

  // lists and maps
  List<LadduStock> _stocks = [];
  List<LadduServe> _serves = [];
  final Map<String, dynamic> _ladduSessionData = {};
  final Map<DateTime, Map<String, dynamic>> _serviceEntries = {};

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
    _stocks.clear();
    _serves.clear();
    _ladduSessionData.clear();
    _serviceEntries.clear();

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
      _ladduSessionData.clear();
      _ladduSessionData.addAll(await FBL().readLatestLadduSessionData() ?? {});
      Map<String, dynamic> stocksMap =
          Map<String, dynamic>.from(_ladduSessionData['stocks']);
      _stocks = stocksMap.values
          .toList()
          .map((entry) =>
              Utils().convertRawToDatatype(entry, LadduStock.fromJson))
          .toList();
      Map<String, dynamic> servesMap =
          Map<String, dynamic>.from(_ladduSessionData['serves']);
      _serves = servesMap.values
          .toList()
          .map((entry) =>
              Utils().convertRawToDatatype(entry, LadduServe.fromJson))
          .toList();
      int availableLadduPacks = _calculateAvailableLadduPacks();
      int totalLadduPacks = _calculateTotalLadduPacks();

      // service entries
      _serviceEntries.clear();
      for (LadduStock stock in _stocks) {
        _serviceEntries[stock.timestamp] = {"stock": stock};
      }
      for (LadduServe serve in _serves) {
        _serviceEntries[serve.timestamp] = {"serve": serve};
      }
      if (_ladduSessionData['returned'] != null) {
        Map<String, dynamic> returnedMap =
            Map<String, dynamic>.from(_ladduSessionData['returned']);
        _serviceEntries[returnedMap['timestamp']] = {"return": returnedMap};
      }

      // sort service entries by timestamp (descending)
      List<DateTime> sortedKeys = _serviceEntries.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      Map<DateTime, Map<String, dynamic>> sortedServiceEntries = {};
      for (var key in sortedKeys) {
        sortedServiceEntries[key] = _serviceEntries[key]!;
      }
      _serviceEntries.clear();
      _serviceEntries.addAll(sortedServiceEntries);

      //-- refresh all child widgets

      // availability bar
      _keySingleBarChart.currentState?.updateChart(
          availableLadduPacks / totalLadduPacks,
          "Available: $availableLadduPacks");

      // summary
      _keyKVTable.currentState?.clearRows();
      _keyKVTable.currentState?.addRows([
        MapEntry("Starting balance", "$totalLadduPacks"),
        MapEntry("Laddu packets distributed",
            "${totalLadduPacks - availableLadduPacks}"),
        MapEntry("Closing balance", "$availableLadduPacks"),
      ]);

      // listen for database events
      // idea: separate event for serve, stock and return
      // TODO: _addListeners(dbpath);
    });

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

  int _calculateAvailableLadduPacks() {
    if (_ladduSessionData.isEmpty) return 0;

    // stocks - (serves + returned)

    // total stocks
    int stockTotal = 0;
    for (var stock in _stocks) {
      stockTotal += stock.count;
      stockTotal += stock.carry ?? 0;
    }

    // total serves
    int serveTotal = 0;
    for (var serve in _serves) {
      // misc packs
      List miscList = serve.packsMisc;
      serveTotal += miscList.fold<int>(0, (sum, misc) {
        Map<String, int> kvMap = Map<String, int>.from(misc);
        return sum + kvMap.values.fold<int>(0, (s, val) => s + val);
      });

      // other sevas
      List otherSevaList = serve.packsOtherSeva;
      serveTotal += otherSevaList.fold<int>(0, (sum, otherSeva) {
        Map<String, int> kvMap = Map<String, int>.from(otherSeva);
        return sum + kvMap.values.fold<int>(0, (s, val) => s + val);
      });

      // pushpanjali
      List pushpanjaliList = serve.packsPushpanjali;
      serveTotal += pushpanjaliList.fold<int>(0, (sum, pushpanjali) {
        Map<String, int> kvMap = Map<String, int>.from(pushpanjali);
        return sum + kvMap.values.fold<int>(0, (s, val) => s + val);
      });
    }

    // returned value
    int returnedTotal = 0;
    if (_ladduSessionData['returned'] != null) {
      Map<String, dynamic> returned =
          Map<String, dynamic>.from(_ladduSessionData['returned']);
      returnedTotal = returned['count'];
    }

    return stockTotal - (serveTotal + returnedTotal);
  }

  int _calculateTotalLadduPacks() {
    if (_ladduSessionData.isEmpty) return 0;

    // total stocks
    int stockTotal = 0;
    for (var stock in _stocks) {
      stockTotal += stock.count;
      stockTotal += stock.carry ?? 0;
    }

    return stockTotal;
  }

  Widget _createServiceEntryTile(DateTime timestamp) {
    String entryType = _serviceEntries[timestamp]?.keys.first ?? 'Unknown';
    LadduStock? stock;
    LadduServe? serve;
    int serveTotal = 0;
    int returnTotal = 0;
    Map<String, dynamic> returned = {};
    if (entryType == 'stock') {
      stock = _serviceEntries[timestamp]?.values.first;
    } else if (entryType == 'serve') {
      serve = _serviceEntries[timestamp]?.values.first;

      // misc packs
      List miscList = serve?.packsMisc ?? [];
      serveTotal += miscList.fold<int>(0, (sum, misc) {
        Map<String, int> kvMap = Map<String, int>.from(misc);
        return sum + kvMap.values.fold<int>(0, (s, val) => s + val);
      });

      // other sevas
      List otherSevaList = serve?.packsOtherSeva ?? [];
      serveTotal += otherSevaList.fold<int>(0, (sum, otherSeva) {
        Map<String, int> kvMap = Map<String, int>.from(otherSeva);
        return sum + kvMap.values.fold<int>(0, (s, val) => s + val);
      });

      // pushpanjali
      List pushpanjaliList = serve?.packsPushpanjali ?? [];
      serveTotal += pushpanjaliList.fold<int>(0, (sum, pushpanjali) {
        Map<String, int> kvMap = Map<String, int>.from(pushpanjali);
        return sum + kvMap.values.fold<int>(0, (s, val) => s + val);
      });
    } else if (entryType == "return") {
      returned = Map<String, dynamic>.from(
          _serviceEntries[timestamp]?.values.first ?? {});
      returnTotal = returned['count'] ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Widgets().createTopLevelCard(
          context: context,
          title: entryType == 'stock'
              ? "Stock + ${stock?.count ?? 0 + (stock?.carry ?? 0)}"
              : (entryType == 'serve'
                  ? "Serve - $serveTotal    "
                  : "Return - $returnTotal"),
          color: entryType == 'stock'
              ? Colors.green
              : (entryType == 'serve' ? Colors.orange : Colors.grey),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: [
                Widgets().createResponsiveRow(context, [
                  Text("User: ",
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(
                      entryType == 'stock'
                          ? stock?.user ?? "Unknown"
                          : (entryType == 'serve'
                              ? serve?.user ?? "Unknown"
                              : returned['user'] ?? "Unknown"),
                      style: Theme.of(context).textTheme.headlineSmall),
                ])
              ],
            ),
          )),
    );
  }

  void _deleteData(Map data) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> serviceEntryKeys = _serviceEntries.keys.toList();

    return Stack(
      children: [
        ResponsiveScaffold(
          // title
          title: widget.title,

          // toolbar icons
          toolbarActions: [
            ResponsiveToolbarAction(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LadduSettings()),
                );
              },
            )
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
                      SingleBarChart(
                        key: _keySingleBarChart,
                        initialPercentage: 0,
                        initialLabel: "Available: 0",
                      ),

                      // Summary
                      SizedBox(
                        height: 10,
                      ),
                      Widgets().createTopLevelCard(
                          title: "Summary",
                          context: context,
                          child: KVTable(
                            key: _keyKVTable,
                          )),

                      // button row
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          // stock button
                          ElevatedButton.icon(
                            onPressed: () async {
                              // addEditStock(context);
                            },
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                            label: Text('Stock'),
                          ),

                          // serve button
                          ElevatedButton.icon(
                            onPressed:

                                // (_lr == null || _lr!.count == -1)
                                //     ? () async {
                                //         _createServeDialog(context);
                                //       }
                                //     :
                                null,
                            icon: Icon(Icons.remove, color: Colors.white),
                            label: Text('Serve'),
                          ),

                          // return button
                          ElevatedButton.icon(
                            onPressed:
                                // (_lr == null || _lr!.count == -1)
                                //     ? () {
                                //         returnStock(context);
                                //       }
                                //     :
                                null,
                            icon: Icon(Icons.undo, color: Colors.white),
                            label: Text('Return'),
                          )
                        ],
                      ),
                      Divider(),

                      // Service Entries
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Service Entries",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(
                        height: 1000,
                        child: ListView.builder(
                            itemCount: serviceEntryKeys.length,
                            itemBuilder: (context, index) {
                              return SizedBox(
                                // height: 50,
                                child: _createServiceEntryTile(
                                    serviceEntryKeys[index]),
                              );
                            }),
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
        if (_isLoading) LoadingOverlay(image: widget.splashImage),
      ],
    );
  }
}
