import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/dashboard.dart';
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
  String _selectedYear = DateTime.now().year.toString();
  DateTime _lastDataModification = DateTime.now();

  // lists
  final List<InventoryEntry> _inventoryEntries = [
    InventoryEntry(
        count: 300,
        timestamp: DateTime.now(),
        note: "Test Note",
        username: "Test User",
        malaType: "chanters",
        addOrRemove: "Add"),
    InventoryEntry(
        count: 300,
        timestamp: DateTime.now(),
        note: "Test Note",
        username: "Test User",
        malaType: "chanters",
        addOrRemove: "Add")
  ];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];
  final GlobalKey<DashboardState> keyDashboard = GlobalKey<DashboardState>();

  @override
  initState() {
    super.initState();

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
          Map rawMap = data as Map;
          List entriesRaw = rawMap.values.first;
          for (var entryRaw in entriesRaw) {
            InventoryEntry entry =
                Utils().convertRawToDatatype(entryRaw, InventoryEntry.fromJson);
            _inventoryEntries.insert(0, entry);
          }
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
      // your code here

      String dbpath = "${Const().dbrootGaruda}/HarinaamInventory";
      List rawList =
          await FB().getListByYear(path: dbpath, year: _selectedYear);
      for (var rawItem in rawList) {
        Map rawMap = rawItem as Map;
        List entriesRaw = rawMap.values.first;
        for (var entryRaw in entriesRaw) {
          InventoryEntry entry =
              Utils().convertRawToDatatype(entryRaw, InventoryEntry.fromJson);
          _inventoryEntries.add(entry);

          // hint: sorting may not be necessary
        }
      }
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addInventory(InventoryEntry entry) async {
    setState(() {
      _inventoryEntries.insert(0, entry);
    });

    // store to database
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/HarinaamInventory/$dbdate";
    await FB().addToList(listpath: dbpath, data: entry.toJson());

    _lastDataModification = DateTime.now();
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
                  Icons.add_circle,
                  color: entry.malaType == "chanters"
                      ? Colors.brown
                      : Theme.of(context).colorScheme.primary,
                ),
                Text(entry.count.toString(),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: entry.malaType == "chanters"
                            ? Colors.brown
                            : Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),

          // mala type and timestamp
          title: Text(
            "[${entry.malaType} mala] ${DateFormat("dd MMM, yyyy").format(entry.timestamp)}",
          ),

          // username
          subtitle: Text(
            entry.username,
          ),

          // note
          infotext: Text("Note: ${entry.note} "),

          // context menu
          trailing: Widgets().createContextMenu(
              items: ["Edit", "Delete"],
              onPressed: (String action) {
                if (action == "Edit") {
                  _showDialogInventory(entry.addOrRemove);
                } else if (action == "Delete") {
                  Widgets().showConfirmDialog(
                      context, "Delete this inventory item?", "Delete", () {
                    _deleteInventory(entry);
                  });
                }
              }),
        ),

        // divider
        SizedBox(height: 8),
        if (_inventoryEntries.length > 1 &&
            index < _inventoryEntries.length - 1)
          Divider(
            color: Colors.grey.shade300,
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _createYearSelector() {
    List<int> years = List.generate(5, (index) => DateTime.now().year - index);

    double containerWidth = MediaQuery.of(context).size.width - 32;
    double itemWidth = 80;

    return Container(
      height: 50,
      width: containerWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(25),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: 8), // Add padding to center content
        itemCount: years.length,
        itemBuilder: (context, index) {
          int year = years[index];
          bool isSelected = year.toString() == _selectedYear;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedYear = year.toString();
                refresh();
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              width: itemWidth,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  year.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteInventory(InventoryEntry entry) async {
    setState(() {
      _inventoryEntries.remove(entry);
    });

    // delete from database
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/HarinaamInventory/$dbdate";
    await FB().deleteFromListByValue(listpath: dbpath, value: entry.toJson());

    _lastDataModification = DateTime.now();
  }

  Future<void> _showDialogInventory(String addOrRemove) async {
    final formKey = GlobalKey<FormState>();

    TextEditingController noteController = TextEditingController();
    TextEditingController countController = TextEditingController();
    String malaType = "Chanters";

    Widgets().showResponsiveDialog(
        context: context,
        title: "$addOrRemove Inventory",
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // select chanter or sale
              RadioRow(
                  items: ["Chanters", "Sale"],
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

                  _addInventory(entry);

                  noteController.dispose();
                  countController.dispose();
                }
              },
              child: Text(addOrRemove))
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
            // add
            ResponsiveToolbarAction(
              icon: Icon(Icons.add_circle_outline),
              onPressed: () async {
                await _showDialogInventory("Add");
              },
            ),

            // discard
            ResponsiveToolbarAction(
              icon: Icon(Icons.remove_circle_outline),
              onPressed: () async {
                await _showDialogInventory("Discard");
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
                      // dashboard
                      Widgets().createTopLevelCard(
                          context: context,
                          child: Column(
                            children: [
                              _createYearSelector(),
                              SizedBox(height: 4),
                              Dashboard(
                                key: keyDashboard,
                                chantersLabel: "Chanters mala stock",
                                salesLabel: "Sales mala stock",
                              )
                            ],
                          )),

                      // inventory entries
                      Widgets().createTopLevelCard(
                          context: context,
                          child: Column(
                            children: [
                              ...List.generate(_inventoryEntries.length,
                                  (index) => _createInventoryTile(index)),
                              if (_inventoryEntries.isEmpty)
                                Text("No inventory entries found")
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
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
