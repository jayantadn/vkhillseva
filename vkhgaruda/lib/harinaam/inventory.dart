import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Inventory extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Inventory({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _InventoryState createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  final String _selectedYear = DateTime.now().year.toString();
  DateTime _lastDataModification = DateTime.now();
  late String _session;
  late InventorySummary _sessionInventoryChanters;
  late InventorySummary _morningInventoryChanters;
  late InventorySummary _sessionInventorySales;
  late InventorySummary _morningInventorySales;
  bool _firstTimeEntry = false;

  // lists
  final List<InventoryEntry> _inventoryEntries = [];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    // set session
    if (DateTime.now().hour >= Const().morningCutoff) {
      _session = "Evening";
    } else {
      _session = "Morning";
    }

    // set default inventory data
    _sessionInventoryChanters = _morningInventoryChanters =
        _sessionInventorySales = _morningInventorySales = InventorySummary(
      openingBalance: 0,
      discarded: 0,
      newAdditions: 0,
      closingBalance: 0,
    );

    FB().listenForChange(
      "${Const().dbrootGaruda}/HarinaamInventory",
      FBCallbacks(
        // add
        add: (data) {
          if (_lastDataModification.isBefore(
            DateTime.now().subtract(Duration(seconds: Const().fbListenerDelay)),
          )) {
            _lastDataModification = DateTime.now();
          }

          // process the received data
          refresh();
        },

        // edit
        edit: () {
          if (_lastDataModification.isBefore(
            DateTime.now().subtract(Duration(seconds: Const().fbListenerDelay)),
          )) {
            _lastDataModification = DateTime.now();

            refresh();
          }
        },

        // delete
        delete: (data) async {
          if (_lastDataModification.isBefore(
            DateTime.now().subtract(Duration(seconds: Const().fbListenerDelay)),
          )) {
            _lastDataModification = DateTime.now();

            // process the received data
            refresh(); // directly refreshing because the deleted data is deeply nested
          }
        },

        // get listeners
        getListeners: (listeners) {
          _listeners = listeners;
        },
      ),
    );

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps
    _inventoryEntries.clear();

    // dispose all controllers and focus nodes
    _inventoryEntries.clear();

    // listeners
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
    if (!allowed) {
      Toaster().error("Access denied");

      if (mounted) {
        Navigator.of(context).pop();
      }

      return;
    }

    await _lock.synchronized(() async {
      // set session
      if (DateTime.now().hour >= Const().morningCutoff) {
        _session = "Evening";
      } else {
        _session = "Morning";
      }

      // populate current session chanters' inventory
      _sessionInventoryChanters =
          await _getInventorySummary(_selectedDate, _session, "Chanters");
      _sessionInventorySales =
          await _getInventorySummary(_selectedDate, _session, "Sales");
      if (!_firstTimeEntry && _session == "Evening") {
        _morningInventoryChanters =
            await _getInventorySummary(_selectedDate, "Morning", "Chanters");
        _morningInventorySales =
            await _getInventorySummary(_selectedDate, "Morning", "Sales");
      }

      // refill inventory entries
      _inventoryEntries.clear();
      String dbpath = "${Const().dbrootGaruda}/HarinaamInventory";
      List rawTopList =
          await FB().getListByYear(path: dbpath, year: _selectedYear);
      if (rawTopList.isNotEmpty) {
        for (var rawList in rawTopList) {
          for (var rawItem in rawList) {
            Map rawMap = rawItem as Map;
            InventoryEntry entry =
                Utils().convertRawToDatatype(rawMap, InventoryEntry.fromJson);
            _inventoryEntries.insert(0, entry);
          }
        }
      }
      _inventoryEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addInventoryEntry(InventoryEntry entry) async {
    setState(() {
      _inventoryEntries.insert(0, entry);
    });

    // store to database
    _lastDataModification = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/HarinaamInventory/$dbdate";
    await FB().addToList(listpath: dbpath, data: entry.toJson());
  }

  Widget _createInventoryDashboard() {
    return Column(
      children: [
        DateHeader(
          callbacks: DateHeaderCallbacks(onChange: (DateTime date) {
            _selectedDate = date;
            refresh();
          }),
        )
      ],
    );
  }

  Widget _createInventoryTile(int index) {
    InventoryEntry entry = _inventoryEntries[index];

    return Column(
      children: [
        ListTileCompact(
          // count
          leading: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Icon(
                  entry.addOrRemove == "Add"
                      ? Icons.add_circle
                      : Icons.remove_circle,
                  color: entry.malaType == "Chanters"
                      ? Colors.brown
                      : Theme.of(context).colorScheme.primary,
                ),
                Text(entry.count.toString(),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: entry.malaType == "Chanters"
                            ? Colors.brown
                            : Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),

          // mala type and timestamp
          title: Widgets().createResponsiveRow(
            context,
            [
              Text(
                "[${entry.malaType} mala]",
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: entry.malaType == "Chanters"
                          ? Colors.brown
                          : Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(DateFormat("dd MMM, yyyy").format(entry.timestamp),
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: entry.malaType == "Chanters"
                            ? Colors.brown
                            : Theme.of(context).colorScheme.primary,
                      )),
            ],
          ),

          // username
          subtitle: Text(
            entry.username,
          ),

          // note
          infotext: entry.note.isNotEmpty ? Text("Note: ${entry.note}") : null,

          // context menu
          trailing: Widgets().createContextMenu(
              items: ["Edit", "Delete"],
              onPressed: (String action) {
                if (action == "Edit") {
                  _showInventoryDialog(entry.addOrRemove, oldEntry: entry);
                } else if (action == "Delete") {
                  Widgets().showConfirmDialog(
                      context, "Delete this inventory item?", "Delete", () {
                    _deleteInventoryEntry(entry);
                  });
                }
              }),
        ),

        // divider
        if (_inventoryEntries.length > 1) SizedBox(height: 8),
        if (_inventoryEntries.length > 1 &&
            index < _inventoryEntries.length - 1)
          Divider(
            color: Colors.grey.shade300,
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
        if (_inventoryEntries.length > 1) SizedBox(height: 8),
      ],
    );
  }

  Future<void> _deleteInventoryEntry(InventoryEntry entry) async {
    setState(() {
      _inventoryEntries.remove(entry);
    });

    // delete from database
    _lastDataModification = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/HarinaamInventory/$dbdate";
    List inventoryEntriesRaw = await FB().getList(path: dbpath);
    List<InventoryEntry> inventoryEntries = inventoryEntriesRaw
        .map((e) => Utils().convertRawToDatatype(e, InventoryEntry.fromJson))
        .toList();
    if (inventoryEntries.isEmpty) {
      Toaster().error("No inventory entries found for the date");
    } else {
      inventoryEntries.remove(entry);
      inventoryEntriesRaw = inventoryEntries
          .map((e) => e.toJson())
          .toList(); // convert back to raw format
      await FB().setValue(path: dbpath, value: inventoryEntriesRaw);
    }
  }

  Future<void> _editInventoryEntry(
      InventoryEntry oldEntry, InventoryEntry newEntry) async {
    // update the entry in the list
    int index = _inventoryEntries.indexOf(oldEntry);
    if (index != -1) {
      setState(() {
        _inventoryEntries[index] = newEntry;
      });
    }

    // update in the database
    _lastDataModification = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(newEntry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/HarinaamInventory/$dbdate";
    List<dynamic> inventoryListRaw = await FB().getList(path: dbpath);
    if (inventoryListRaw.isEmpty) {
      Toaster().error("No inventory entries found for the date");
      return;
    } else {
      List newInventoryListRaw = [];
      for (var inventoryItem in inventoryListRaw) {
        InventoryEntry entry = Utils()
            .convertRawToDatatype(inventoryItem, InventoryEntry.fromJson);
        if (entry.timestamp == oldEntry.timestamp &&
            entry.malaType == oldEntry.malaType &&
            entry.addOrRemove == oldEntry.addOrRemove) {
          // found the entry to update
          newInventoryListRaw.add(newEntry.toJson());
        } else {
          // keep the old entry
          newInventoryListRaw.add(inventoryItem);
        }
      }

      _lastDataModification = DateTime.now();
      await FB().setValue(path: dbpath, value: newInventoryListRaw);
    }
  }

  Future<InventorySummary> _getInventorySummary(
      DateTime date, String session, String type) async {
    int openingBalance = 0;
    int discarded = 0;
    int newAdditions = 0;
    int closingBalance = 0;

    String dbdate = DateFormat("yyyy-MM-dd").format(date);
    String dbpath =
        "${Const().dbrootGaruda}/HarinaamInventorySummary/$dbdate/$session/$type";
    Map<String, dynamic> summaryDataJson =
        await FB().getJson(path: dbpath, silent: true);
    if (summaryDataJson.isEmpty) {
      // if session is evening, check for morning session
      if (session == "Evening") {
        String dbpathTemp =
            "${Const().dbrootGaruda}/HarinaamInventorySummary/$dbdate/Morning/$type";
        summaryDataJson = await FB().getJson(path: dbpathTemp, silent: true);
        if (summaryDataJson.isEmpty) {
          // ask for current balance
          openingBalance =
              closingBalance = await _showGetCurrentBalanceDialog(type);
        } else {
          // fill the current session
          openingBalance =
              closingBalance = summaryDataJson['closingBalance'] ?? 0;
        }
      }

      // if session is morning, check for previous day's evening session
      if (session == "Morning") {
        String prevDbdate =
            DateFormat("yyyy-MM-dd").format(date.subtract(Duration(days: 1)));
        String dbpathTemp =
            "${Const().dbrootGaruda}/HarinaamInventorySummary/$prevDbdate/Evening/$type";
        summaryDataJson = await FB().getJson(path: dbpathTemp, silent: true);
        if (summaryDataJson.isEmpty) {
          // ask for current balance
          openingBalance =
              closingBalance = await _showGetCurrentBalanceDialog(type);
        } else {
          // fill the current session
          openingBalance =
              closingBalance = summaryDataJson['closingBalance'] ?? 0;
        }
      }

      // write back to db
      await FB().setValue(path: dbpath, value: {
        'openingBalance': openingBalance,
        'discarded': discarded,
        'newAdditions': newAdditions,
        'closingBalance': closingBalance,
      });
    } else {
      // fill the current session
      openingBalance = summaryDataJson['openingBalance'] ?? 0;
      discarded = summaryDataJson['discarded'] ?? 0;
      newAdditions = summaryDataJson['newAdditions'] ?? 0;
      closingBalance = summaryDataJson['closingBalance'] ?? 0;
    }

    return InventorySummary(
      openingBalance: openingBalance,
      discarded: discarded,
      newAdditions: newAdditions,
      closingBalance: closingBalance,
    );
  }

  Future<int> _showGetCurrentBalanceDialog(String type) async {
    int currentBalance = 0;
    TextEditingController balanceController =
        TextEditingController(text: currentBalance.toString());
    final formKey = GlobalKey<FormState>();

    _firstTimeEntry = true;

    await Widgets().showResponsiveDialog(
        context: context,
        title: "Enter $type mala balance",
        child: Form(
          key: formKey,
          child: Column(
            children: [
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Current Balance",
                  border: OutlineInputBorder(),
                ),
                controller: balanceController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a count';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) < 0) {
                    return 'Count cannot be negative';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  currentBalance = int.parse(balanceController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Submit")),
        ]);

    return currentBalance;
  }

  Future<void> _showInventoryDialog(String addOrRemove,
      {InventoryEntry? oldEntry}) async {
    final formKey = GlobalKey<FormState>();

    TextEditingController noteController =
        TextEditingController(text: oldEntry?.note ?? "");
    TextEditingController countController =
        TextEditingController(text: oldEntry?.count.toString() ?? "");
    String malaType = oldEntry?.malaType ?? "Chanters";

    Widgets().showResponsiveDialog(
        context: context,
        title: "${oldEntry == null ? addOrRemove : 'Edit'} Inventory",
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // select chanter or sale
              RadioRow(
                  items: ["Chanters", "Sales"],
                  selectedIndex: malaType == "Chanters" ? 0 : 1,
                  onChanged: (String value) {
                    setState(() {
                      malaType = value;
                    });
                  }),

              // count
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Count",
                  border: OutlineInputBorder(),
                ),
                controller: countController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a count';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Count must be greater than 0';
                  }
                  return null;
                },
              ),

              // note
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "Note",
                  border: OutlineInputBorder(),
                ),
                controller: noteController,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop();

                  UserBasics? userBasics = await Utils().fetchOrGetUserBasics();

                  // create the inventory entry
                  InventoryEntry entry = InventoryEntry(
                    count: int.parse(countController.text),
                    timestamp: DateTime.now(),
                    note: noteController.text,
                    username: userBasics?.name ?? "Unknown",
                    malaType: malaType,
                    addOrRemove: addOrRemove,
                  );

                  if (oldEntry == null) {
                    await _addInventoryEntry(entry);
                  } else {
                    await _editInventoryEntry(oldEntry, entry);
                  }
                }
              },
              child:
                  Text("$addOrRemove${oldEntry == null ? '' : ' (Update)'}")),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveScaffold(
          // title
          title: widget.title,

          toolbarActions: [
            // Only show add/discard buttons if selected year is current year
            if (_selectedYear == DateTime.now().year.toString()) ...[
              // add
              ResponsiveToolbarAction(
                icon: Icon(Icons.add_circle_outline),
                onPressed: () async {
                  await _showInventoryDialog("Add");
                },
              ),

              // discard
              ResponsiveToolbarAction(
                icon: Icon(Icons.remove_circle_outline),
                onPressed: () async {
                  await _showInventoryDialog("Discard");
                },
              ),
            ],
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
                      // inventory dashboard
                      Widgets().createTopLevelCard(
                          context: context,
                          title: "Dashboard",
                          child: _createInventoryDashboard()),

                      // inventory entries
                      Widgets().createTopLevelCard(
                          context: context,
                          title: "Inventory entries",
                          child: Column(
                            children: [
                              ...List.generate(_inventoryEntries.length,
                                  (index) => _createInventoryTile(index)),
                              if (_inventoryEntries.isEmpty)
                                Text("No inventory entries found.")
                            ],
                          )),

                      // leave some space at bottom
                      SizedBox(height: 500),
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
            image: widget.splashImage,
          ),
      ],
    );
  }
}
