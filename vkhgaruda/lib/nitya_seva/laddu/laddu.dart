import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/nitya_seva/laddu/datatypes.dart';
import 'package:vkhgaruda/nitya_seva/laddu/fbl.dart';
import 'package:vkhgaruda/nitya_seva/laddu/laddu_calc.dart';
import 'package:vkhgaruda/nitya_seva/laddu/laddu_settings.dart';
import 'package:vkhgaruda/nitya_seva/laddu/serve.dart';
import 'package:vkhgaruda/nitya_seva/laddu/service_select.dart';
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
  bool _isSessionClosed = false;
  DateTime? _selectedSession;
  DateTime? _lastSession;
  int _availableLadduPacks = 0;
  int _totalLadduPacks = 0;

  // global keys
  final GlobalKey<SingleBarChartState> _keySingleBarChart =
      GlobalKey<SingleBarChartState>();
  // KVTable is now controlled from parent props; no GlobalKey needed

  // lists and maps
  List<LadduStock> _stocks = [];
  List<LadduServe> _serves = [];
  final Map<String, dynamic> _ladduSessionData =
      {}; // dump of all data inside a session
  final Map<DateTime, Map<String, dynamic>> _ladduServiceEntries =
      {}; // all data inside a session keyed with stock, serve, return
  final Map<DateTime, dynamic> _pushpanjaliSessions = {};

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
    _ladduServiceEntries.clear();
    _pushpanjaliSessions.clear();

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
      _isSessionClosed = false;
      _ladduSessionData.clear();
      _stocks.clear();
      _serves.clear();
      _lastSession = await FBL().getLastSessionDateTime();
      _selectedSession ??= _lastSession;
      String dbpath =
          '${Const().dbrootGaruda}/LadduSeva/${_selectedSession!.toIso8601String().replaceAll(".", "^")}';
      _ladduSessionData.addAll(await FB().getJson(path: dbpath));
      Map<String, dynamic> stocksMap = {};
      if (_ladduSessionData['stocks'] != null) {
        stocksMap = Map<String, dynamic>.from(_ladduSessionData['stocks']);
        _stocks = stocksMap.values
            .toList()
            .map((entry) =>
                Utils().convertRawToDatatype(entry, LadduStock.fromJson))
            .toList();
      }

      Map<String, dynamic> servesMap = {};
      if (_ladduSessionData['serves'] != null) {
        servesMap = Map<String, dynamic>.from(_ladduSessionData['serves']);
        _serves = servesMap.values
            .toList()
            .map((entry) =>
                Utils().convertRawToDatatype(entry, LadduServe.fromJson))
            .toList();
      }
      _availableLadduPacks = _calculateAvailableLadduPacks();
      _totalLadduPacks = _calculateTotalLadduPacks();

      // laddu service entries
      _ladduServiceEntries.clear();
      for (LadduStock stock in _stocks) {
        _ladduServiceEntries[stock.timestamp] = {"stock": stock};
      }
      for (LadduServe serve in _serves) {
        _ladduServiceEntries[serve.timestamp] = {"serve": serve};
      }
      if (_ladduSessionData['returned'] != null) {
        Map<String, dynamic> returnedMap =
            Map<String, dynamic>.from(_ladduSessionData['returned']);
        if (returnedMap['count'] != -1) {
          _ladduServiceEntries[DateTime.parse(returnedMap['timestamp'])] = {
            "return": returnedMap
          };
        }
      }

      // sort laddu service entries by timestamp (descending)
      List<DateTime> sortedKeys = _ladduServiceEntries.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      Map<DateTime, Map<String, dynamic>> sortedServiceEntries = {};
      for (var key in sortedKeys) {
        sortedServiceEntries[key] = _ladduServiceEntries[key]!;
      }
      _ladduServiceEntries.clear();
      _ladduServiceEntries.addAll(sortedServiceEntries);

      // check if last entry is more than one day old. If yes, return remaining laddu packs and close session.
      if (_ladduServiceEntries.isNotEmpty) {
        String serviceType = _ladduServiceEntries.values.first.keys.first;
        DateTime serviceTime = _ladduServiceEntries.keys.first;
        if (serviceType == "return") {
          Map<String, dynamic> returnedMap =
              Map<String, dynamic>.from(_ladduSessionData['returned']);
          if (returnedMap['count'] != -1) {
            _isSessionClosed = true;
          }
        } else {
          DateTime now = DateTime.now();
          Duration difference = now.difference(serviceTime);
          if (difference.inDays >= 1) {
            // last session is more than 1 day old
            if (mounted) {
              Widgets().showConfirmDialog(
                  context,
                  "Session is more than one day old. Close the session and return all remaining laddu packs?",
                  "Close session",
                  _closeSession);
            }
          }
        }
      }

      // linked pushpanjali entries
      _pushpanjaliSessions.clear();
      for (var entry in _ladduServiceEntries.entries) {
        Map<String, dynamic> value = Map<String, dynamic>.from(entry.value);
        if (value.keys.first == "serve") {
          LadduServe serve = value["serve"];
          DateTime? pushpanjaliSlot = serve.pushpanjaliSlot;
          if (pushpanjaliSlot == null) {
            Toaster().error("Failed to get pushpanjali slot");
          } else {
            String dbdate = DateFormat("yyyy-MM-dd").format(pushpanjaliSlot);
            String dbkey =
                pushpanjaliSlot.toIso8601String().replaceAll(".", "^");
            String dbpath = "${Const().dbrootGaruda}/NityaSeva/$dbdate/$dbkey";

            Map<String, dynamic> pushpanjaliEntry =
                await FB().getJson(path: dbpath);
            _pushpanjaliSessions[pushpanjaliSlot] = pushpanjaliEntry;
          }
        }
      }

      //-- refresh all child widgets

      // availability bar
      _keySingleBarChart.currentState?.updateChart(
          _totalLadduPacks == 0 ? 0 : _availableLadduPacks / _totalLadduPacks,
          "Available: $_availableLadduPacks");

      // summary table now derives from state in build()

      // listen for database events
      _addListeners(
          "${Const().dbrootGaruda}/LadduSeva/${_selectedSession!.toIso8601String().replaceAll(".", "^")}");
    });

    setState(() {
      _isLoading = false;
    });
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
          refresh();
        },

        // edit
        edit: () {
          refresh();
        },

        // delete
        delete: (data) async {
          refresh();
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
      returnedTotal = returned['count'] == -1 ? 0 : returned['count'];
    }

    return stockTotal - (serveTotal + returnedTotal);
  }

  Map<int, int> _calculateTicketsSold(
      Map<String, dynamic>? pushpanjaliSession) {
    Map<int, int> numTickets = {};
    if (pushpanjaliSession != null &&
        pushpanjaliSession['Tickets'] != null &&
        pushpanjaliSession['Tickets'].isNotEmpty) {
      Map<String, dynamic> ticketsRaw =
          Map<String, dynamic>.from(pushpanjaliSession['Tickets']);
      List<Ticket> tickets = ticketsRaw.values
          .map((value) => Utils().convertRawToDatatype(value, Ticket.fromJson))
          .toList();

      for (Ticket ticket in tickets) {
        numTickets[ticket.amount] = (numTickets[ticket.amount] ?? 0) + 1;
      }
    }

    return numTickets;
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

  int _calculateTotalServe(LadduServe serve) {
    int serveTotal = 0;

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

    return serveTotal;
  }

  int _calculateTotalServeOverall() {
    int total = 0;
    for (var serve in _serves) {
      total += _calculateTotalServe(serve);
    }
    return total;
  }

  void _closeSession() {
    returnStock(context);

    setState(() {
      _isSessionClosed = true;
    });
  }

  Widget _createPushpanjaliRow(Map<String, String> row) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Column(
        children: [
          ListTileCompact(
            leading: Container(
              decoration: BoxDecoration(
                color: Utils().getNityaSevaAmountColor(row['amount']),
                borderRadius: BorderRadius.circular(4.0),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "₹${row['amount']}",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(" Tickets: ${row['tickets'] ?? '0'}"),
            subtitle: Text(" Laddu Packs: ${row['ladduPacks'] ?? '0'}"),
          ),
          Divider(color: Colors.grey)
        ],
      ),
    );
  }

  Widget _createReturnTile(DateTime timestamp) {
    LadduReturn returnEntry = Utils().convertRawToDatatype(
        _ladduServiceEntries[timestamp]?['return'], LadduReturn.fromJson);
    return Widgets().createTopLevelCard(
        context: context,
        color: Colors.grey,
        title: "Return -${returnEntry.count}",
        child: ListTileCompact(
            title: Widgets().createResponsiveRow(
              context,
              [
                Text("Service by "),
                Text(returnEntry.user,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(
                    " on ${DateFormat("EEE, ").format(returnEntry.timestamp)}"),
                Text(DateFormat("dd MMM, yyyy ").format(returnEntry.timestamp)),
                Text(DateFormat("hh:mm a").format(returnEntry.timestamp)),
              ],
            ),
            subtitle: KVTable(
              rows: [
                MapEntry("Returned to", returnEntry.to),
                MapEntry("Packs returned", returnEntry.count.toString())
              ],
            ),
            onTap: () async {
              returnStock(context, lr: returnEntry);
            }));
  }

  void _createServeDialog(BuildContext context) {
    if (_stocks.isEmpty) {
      Toaster().error("No stocks available");
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ServiceSelect();
      },
    );
  }

  Widget _createServeTile(DateTime timestamp) {
    LadduServe serveEntry = _ladduServiceEntries[timestamp]?['serve'];
    int count = _calculateTotalServe(serveEntry);

    // pushpanjali session name
    Map<String, dynamic>? pushpanjaliSession =
        _pushpanjaliSessions[serveEntry.pushpanjaliSlot];
    String pushpanjaliSessionName = "Unknown pushpanjali session";
    if (pushpanjaliSession != null) {
      pushpanjaliSessionName = pushpanjaliSession['Settings']['name'];
      if (serveEntry.pushpanjaliSlot!.hour <= Const().morningCutoff) {
        pushpanjaliSessionName += " (Morning)";
      } else {
        pushpanjaliSessionName += " (Evening)";
      }
      pushpanjaliSessionName +=
          " - ${DateFormat('EEE, dd MMM yyyy').format(serveEntry.pushpanjaliSlot!)}";
    }

    //-- table of pushpanjali and laddu service entries
    List<Map<String, String>> serveTable = [];
    // add the pushpanjali tickets
    Map<int, int> numTickets = _calculateTicketsSold(pushpanjaliSession);
    for (Map<String, dynamic> data in Const().nityaSeva['amounts']!) {
      String amount = data.keys.first;
      bool obsolete = data[amount]?["obsolete"] ?? true;

      if (!obsolete) {
        int numLadduPacks = _getLadduPacketsDistributed(serveEntry, amount);

        serveTable.add({
          "amount": amount,
          "tickets": numTickets[int.parse(amount)]?.toString() ?? "0",
          "ladduPacks": numLadduPacks.toString(),
        });
      }
    }

    return Widgets().createTopLevelCard(
        context: context,
        color: Colors.orange,
        title: "Serve -$count",
        child: Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 4.0),
          child: ListTileCompact(
              // user and timestamp
              title: Widgets().createResponsiveRow(
                context,
                [
                  Text("Service by "),
                  Text(serveEntry.user,
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(
                      " on ${DateFormat("EEE, ").format(serveEntry.timestamp)}"),
                  Text(
                      DateFormat("dd MMM, yyyy ").format(serveEntry.timestamp)),
                  Text(DateFormat("hh:mm a").format(serveEntry.timestamp)),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // pushpanjali session title
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    pushpanjaliSessionName,
                    style: TextStyle(
                        backgroundColor: Colors.black, color: Colors.white),
                  ),

                  // starting balance
                  Text("Starting balance: ${serveEntry.available}"),

                  // table for pushpanjali tickets
                  SizedBox(height: 10),
                  ...List.generate(serveTable.length, (index) {
                    Map<String, String> row = serveTable[index];
                    return _createPushpanjaliRow(row);
                  }),

                  // other laddu sevas
                  Widgets().createResponsiveRow(context, [
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: "Misc: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: "${serveEntry.packsMisc[0]['Miscellaneous']}"
                              .padRight(4, ' ')),
                    ])),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: "Special Puja: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              "${serveEntry.packsOtherSeva[0]['Special Puja']}"
                                  .padRight(4, ' ')),
                    ])),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: "Festival: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: "${serveEntry.packsOtherSeva[1]['Festival']}"
                              .padRight(4, ' ')),
                    ])),
                  ]),

                  // total distributed
                  SizedBox(height: 10),
                  Text(
                    "Total packs served: $count",
                  ),

                  // closing balance
                  Text(
                    "Closing balance: ${serveEntry.balance}",
                  )
                ],
              ),
              infotext: serveEntry.note.isEmpty
                  ? null
                  : Text("Note: ${serveEntry.note}"), // note
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Serve(
                            serve: serveEntry,
                            slot: Session(
                                defaultAmount: 500,
                                defaultPaymentMode: 'UPI',
                                type: "Pushpanjali",
                                icon:
                                    'assets/images/NityaSeva/vishnu_pushpanjali.png',
                                timestamp: serveEntry.pushpanjaliSlot ??
                                    DateTime.now(),
                                name: serveEntry.title,
                                sevakarta: serveEntry.user),
                          )),
                );
              }),
        ));
  }

  Widget _createServiceEntryTile(DateTime timestamp) {
    String entryType = _ladduServiceEntries[timestamp]?.keys.first ?? 'Unknown';

    switch (entryType) {
      case "stock":
        return _createStockTile(timestamp);

      case "serve":
        return _createServeTile(timestamp);

      case "return":
        return _createReturnTile(timestamp);

      case "Unknown":
        return Widgets().createTopLevelCard(
            context: context,
            color: Colors.grey,
            title: "Unknown",
            child: SizedBox(height: 50, child: Text("Unknown entry")));
    }

    return Placeholder();
  }

  Widget _createSessionScroller() {
    String start =
        DateFormat("dd MMM").format(_selectedSession ?? DateTime.now());

    DateTime endDateTime = DateTime.now();
    if (_ladduServiceEntries.isNotEmpty) {
      endDateTime = _ladduServiceEntries.keys.first;
    }
    String end = DateFormat("dd MMM").format(endDateTime);

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // previous session button
          IconButton(
            icon: Transform.rotate(
              angle: 3.14, // Rotate 180 degrees to point left
              child: Icon(
                Icons.play_arrow,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            onPressed: () async {
              _selectedSession =
                  await FBL().getLastSessionDateTime(before: _selectedSession);
              await refresh();
            },
          ),

          // date
          InkWell(
            onTap: () async {
              _selectedSession = _lastSession;
              await refresh();
            },
            child: Container(
              width: 150.0,
              alignment: Alignment.center,
              child: Text(
                "$start - $end",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),

          // next day button
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ), // Default points right
            onPressed: () async {
              _selectedSession = await FBL().getLastSessionDateTime(
                  after: _selectedSession, silent: true);
              await refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _createStockTile(DateTime timestamp) {
    LadduStock stockEntry = _ladduServiceEntries[timestamp]?['stock'];
    return Widgets().createTopLevelCard(
        context: context,
        color: Colors.green,
        title: "Stock +${stockEntry.count + (stockEntry.carry ?? 0)}",
        child: ListTileCompact(
          title: Widgets().createResponsiveRow(
            context,
            [
              Text("Service by "),
              Text(stockEntry.user,
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(" on ${DateFormat("EEE, ").format(stockEntry.timestamp)}"),
              Text(DateFormat("dd MMM, yyyy ").format(stockEntry.timestamp)),
              Text(DateFormat("hh:mm a").format(stockEntry.timestamp)),
            ],
          ),
          subtitle: KVTable(
            rows: [
              MapEntry("Stocks procured: ", "${stockEntry.count}"),
              MapEntry("Carry over: ", "${stockEntry.carry ?? 0}"),
              MapEntry("Procured from: ", stockEntry.from),
            ],
          ),
          onTap: () async {
            if (_ladduSessionData.isEmpty) {
              await addEditStock(context, edit: true, stock: stockEntry);
            } else {
              await addEditStock(context,
                  edit: true, stock: stockEntry, session: _selectedSession);
            }
          },
        ));
  }

  Widget _createSummary() {
    int totalServe = _calculateTotalServeOverall();
    int returned = _getLadduPacksReturned();
    return Widgets().createTopLevelCard(
        title: "Summary",
        context: context,
        child: KVTable(
          rows: [
            MapEntry("Starting balance", "$_totalLadduPacks"),
            MapEntry("Laddu packets served", "$totalServe"),
            MapEntry("Laddu packs returned", "$returned"),
            MapEntry("Closing balance", "$_availableLadduPacks"),
          ],
        ));
  }

  int _getLadduPacketsDistributed(serveEntry, amount) {
    var shortlist = serveEntry.packsPushpanjali
        .where((item) => item.keys.first == amount)
        .toList();

    if (shortlist.isEmpty) return 0;
    return shortlist[0].values.first;
  }

  int _getLadduPacksReturned() {
    if (_ladduSessionData['returned'] != null) {
      Map<String, dynamic> returned =
          Map<String, dynamic>.from(_ladduSessionData['returned']);
      int count = returned['count'];
      return count == -1 ? 0 : count;
    }
    return 0;
  }

  void _newSession() {
    Widgets().showConfirmDialog(
        context, "Are you sure to create new session?", "New Session",
        () async {
      _isSessionClosed = false;

      String timestamp = DateTime.now().toIso8601String().replaceAll(".", "^");
      await FB().setJson(
          json: {"dummyKey": "NewSession"},
          path: "${Const().dbrootGaruda}/LadduSeva/$timestamp");

      _selectedSession = null;
      await refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> serviceEntryKeys = _ladduServiceEntries.keys.toList();

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
                      // session date scroller
                      _createSessionScroller(),

                      // leave some space on top
                      Divider(),

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
                      _createSummary(),

                      // button row
                      Divider(),
                      if (_selectedSession == _lastSession)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            // new session
                            if (_isSessionClosed)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  _newSession();
                                },
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: Text('New Session'),
                              ),

                            // stock button
                            if (!_isSessionClosed)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  addEditStock(context);
                                },
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: Text('Stock'),
                              ),

                            // serve button
                            if (!_isSessionClosed)
                              ElevatedButton.icon(
                                onPressed: _isSessionClosed
                                    ? null
                                    : () async {
                                        _createServeDialog(context);
                                      },
                                icon: Icon(Icons.remove, color: Colors.white),
                                label: Text('Serve'),
                              ),

                            // return button
                            if (!_isSessionClosed)
                              ElevatedButton.icon(
                                onPressed: _isSessionClosed
                                    ? null
                                    : () {
                                        returnStock(context);
                                      },
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
                        _isSessionClosed ? "Session Closed" : "Service Entries",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      ...List.generate(
                        serviceEntryKeys.length,
                        (index) =>
                            _createServiceEntryTile(serviceEntryKeys[index]),
                      ),

                      // leave some space on bottom
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
