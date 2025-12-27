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
  Map<String, dynamic> _ladduSessionData = {};

  // global keys
  final GlobalKey<SingleBarChartState> _keySingleBarChart =
      GlobalKey<SingleBarChartState>();
  final GlobalKey<KVTableState> _keyKVTable = GlobalKey<KVTableState>();

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
      _ladduSessionData = await FBL().readLatestLadduSessionData() ?? {};
      int availableLadduPacks = _calculateAvailableLadduPacks();
      int totalLadduPacks = _calculateTotalLadduPacks();

      // refresh all child widgets

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
    Map<String, dynamic> stocksMap =
        Map<String, dynamic>.from(_ladduSessionData['stocks']);
    List<LadduStock> stocks = stocksMap.values
        .toList()
        .map(
            (entry) => Utils().convertRawToDatatype(entry, LadduStock.fromJson))
        .toList();
    int stockTotal = 0;
    for (var stock in stocks) {
      stockTotal += stock.count;
      stockTotal += stock.carry ?? 0;
    }

    // total serves
    Map<String, dynamic> servesMap =
        Map<String, dynamic>.from(_ladduSessionData['serves']);
    List<LadduServe> serves = servesMap.values
        .toList()
        .map(
            (entry) => Utils().convertRawToDatatype(entry, LadduServe.fromJson))
        .toList();
    int serveTotal = 0;
    for (var serve in serves) {
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

    // stocks

    // total stocks
    Map<String, dynamic> stocksMap =
        Map<String, dynamic>.from(_ladduSessionData['stocks']);
    List<LadduStock> stocks = stocksMap.values
        .toList()
        .map(
            (entry) => Utils().convertRawToDatatype(entry, LadduStock.fromJson))
        .toList();
    int stockTotal = 0;
    for (var stock in stocks) {
      stockTotal += stock.count;
      stockTotal += stock.carry ?? 0;
    }

    return stockTotal;
  }

  void _deleteData(Map data) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
