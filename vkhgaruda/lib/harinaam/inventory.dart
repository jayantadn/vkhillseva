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
  String _selectedYear = DateTime.now().year.toString();
  DateTime _lastDataModification = DateTime.now();

  // lists
  final List<InventoryEntry> _inventoryEntries = [];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    FB().listenForChange(
      "${Const().dbrootGaruda}/Harinaam/Inventory",
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
      // refill inventory entries
      _inventoryEntries.clear();
      String dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory";
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

      // calculate dashboard counters
      int chantersCount = 0;
      int salesCount = 0;
      for (InventoryEntry entry in _inventoryEntries) {
        if (entry.malaType == "Chanters") {
          if (entry.addOrRemove == "Add") {
            chantersCount += entry.count;
          } else {
            chantersCount -= entry.count;
          }
        } else if (entry.malaType == "Sales") {
          if (entry.addOrRemove == "Add") {
            salesCount += entry.count;
          } else {
            salesCount -= entry.count;
          }
        }
      }

      // offset by the sales count
      int salesOffset = 0;
      dbpath = "${Const().dbrootGaruda}/Harinaam/ServiceEntries";
      var rawList = await FB().getListByYear(path: dbpath, year: _selectedYear);
      if (rawList.isNotEmpty) {
        for (var rawItem in rawList) {
          Map rawMap = rawItem as Map;
          var entryRaw = rawMap.values.first as Map;
          var salesRaw = entryRaw["Sales"];
          if (salesRaw != null) {
            Map salesMap = salesRaw as Map;
            for (var entry in salesMap.entries) {
              SalesEntry salesEntry = Utils()
                  .convertRawToDatatype(entry.value, SalesEntry.fromJson);
              salesOffset += salesEntry.count;
            }
          }
        }
      }
      salesCount -= salesOffset;
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
    String dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory/$dbdate";
    await FB().addToList(listpath: dbpath, data: entry.toJson());

    // update balance in db
    String today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    dbpath = "${Const().dbrootGaruda}/Harinaam/MalaBalance/$today/";
    Map<String, dynamic> data = await FB().getJson(path: dbpath);
    if (entry.malaType == "Chanters") {
      if (entry.addOrRemove == "Add") {
        data['ChantersClosingBalance'] =
            (data['ChantersClosingBalance'] ?? 0) + entry.count;
      } else {
        data['ChantersClosingBalance'] =
            (data['ChantersClosingBalance'] ?? 0) - entry.count;
        if (data['ChantersClosingBalance'] < 0) {
          data['ChantersClosingBalance'] = 0;
          Toaster().error("Chanters mala count cannot be negative.");
        }
      }
    } else {
      if (entry.addOrRemove == "Add") {
        data['SalesClosingBalance'] =
            (data['SalesClosingBalance'] ?? 0) + entry.count;
      } else {
        data['SalesClosingBalance'] =
            (data['SalesClosingBalance'] ?? 0) - entry.count;
        if (data['SalesClosingBalance'] < 0) {
          data['SalesClosingBalance'] = 0;
          Toaster().error("Sales mala count cannot be negative.");
        }
      }
    }
    FB().setJson(path: dbpath, json: data);
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
                  _showDialogInventory(entry.addOrRemove, oldEntry: entry);
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

  Widget _createYearSelector() {
    List<int> years = List.generate(5, (index) => DateTime.now().year - index);

    double containerWidth = MediaQuery.of(context).size.width - 32;
    double itemWidth = 80;

    return Container(
      height: 50,
      width: containerWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  Future<void> _deleteInventoryEntry(InventoryEntry entry) async {
    setState(() {
      _inventoryEntries.remove(entry);
    });

    // delete from database
    _lastDataModification = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory/$dbdate";
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

    // update balance in db
    String today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String dbpathBalance =
        "${Const().dbrootGaruda}/Harinaam/MalaBalance/$today/";
    Map<String, dynamic> dataBalance = await FB().getJson(path: dbpathBalance);
    if (entry.malaType == "Chanters") {
      if (entry.addOrRemove == "Add") {
        dataBalance['ChantersClosingBalance'] =
            (dataBalance['ChantersClosingBalance'] ?? 0) - entry.count;
      } else if (entry.addOrRemove == "Remove") {
        dataBalance['ChantersClosingBalance'] =
            (dataBalance['ChantersClosingBalance'] ?? 0) + entry.count;
      } else {
        Toaster().error("Invalid entry");
      }
    } else if (entry.malaType == "Sales") {
      if (entry.addOrRemove == "Add") {
        dataBalance['SalesClosingBalance'] =
            (dataBalance['SalesClosingBalance'] ?? 0) - entry.count;
      } else if (entry.addOrRemove == "Remove") {
        dataBalance['SalesClosingBalance'] =
            (dataBalance['SalesClosingBalance'] ?? 0) + entry.count;
      } else {
        Toaster().error("Invalid entry");
      }
    } else {
      Toaster().error("Invalid entry");
    }
    FB().setJson(path: dbpathBalance, json: dataBalance);
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

    // prepare for balance update
    String today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String dbpathBalance =
        "${Const().dbrootGaruda}/Harinaam/MalaBalance/$today/";
    Map<String, dynamic> dataBalance = await FB().getJson(path: dbpathBalance);

    // update the balance in db
    int delta = newEntry.count - oldEntry.count;
    if (oldEntry.malaType == newEntry.malaType) {
      if (oldEntry.malaType == "Chanters") {
        if (oldEntry.addOrRemove == "Add") {
          dataBalance['ChantersClosingBalance'] =
              (dataBalance['ChantersClosingBalance'] ?? 0) + delta;
        } else {
          dataBalance['ChantersClosingBalance'] =
              (dataBalance['ChantersClosingBalance'] ?? 0) - delta;
        }
      } else if (oldEntry.malaType == "Sales") {
        if (oldEntry.addOrRemove == "Add") {
          dataBalance['SalesClosingBalance'] =
              (dataBalance['SalesClosingBalance'] ?? 0) + delta;
        } else {
          dataBalance['SalesClosingBalance'] =
              (dataBalance['SalesClosingBalance'] ?? 0) - delta;
        }
      }
    } else {
      if (oldEntry.malaType == "Chanters") {
        if (oldEntry.addOrRemove == "Add") {
          dataBalance['SalesClosingBalance'] =
              (dataBalance['SalesClosingBalance'] ?? 0) + newEntry.count;
          dataBalance['ChantersClosingBalance'] =
              (dataBalance['ChantersClosingBalance'] ?? 0) - oldEntry.count;
        } else {
          dataBalance['ChantersClosingBalance'] =
              (dataBalance['ChantersClosingBalance'] ?? 0) + oldEntry.count;
          dataBalance['SalesClosingBalance'] =
              (dataBalance['SalesClosingBalance'] ?? 0) - newEntry.count;
        }
      } else if (oldEntry.malaType == "Sales") {
        if (oldEntry.addOrRemove == "Add") {
          dataBalance['SalesClosingBalance'] =
              (dataBalance['SalesClosingBalance'] ?? 0) - oldEntry.count;
          dataBalance['ChantersClosingBalance'] =
              (dataBalance['ChantersClosingBalance'] ?? 0) + newEntry.count;
        } else {
          dataBalance['SalesClosingBalance'] =
              (dataBalance['SalesClosingBalance'] ?? 0) + oldEntry.count;
          dataBalance['ChantersClosingBalance'] =
              (dataBalance['ChantersClosingBalance'] ?? 0) - newEntry.count;
        }
      }
    }

    // update in the database
    _lastDataModification = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(newEntry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory/$dbdate";
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

    // update balance in db
    FB().setJson(path: dbpathBalance, json: dataBalance);
  }

  Future<void> _showDialogInventory(String addOrRemove,
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
                      // inventory entries
                      Widgets().createTopLevelCard(
                          context: context,
                          title: "Entry records",
                          child: Column(
                            children: [
                              _createYearSelector(),
                              Divider(),
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
            image: widget.splashImage,
          ),
      ],
    );
  }
}
