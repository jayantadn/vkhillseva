import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/deepotsava/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Log extends StatefulWidget {
  final String title;
  final String stall;
  final DateTime date;
  final String? splashImage;

  const Log(
      {super.key,
      required this.title,
      required this.stall,
      required this.date,
      required this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _LogState createState() => _LogState();
}

class _LogState extends State<Log> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists
  List<SalesEntry> _salesEntries = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps
    _salesEntries.clear();

    // dispose all controllers and focus nodes

    // listeners
    // no listeners for this page, only manual refresh

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here
      String dbdate = DateFormat("yyyy-MM-dd").format(widget.date);
      String dbpath =
          "${Const().dbrootGaruda}/Deepotsava/${widget.stall}/Sales/$dbdate";
      List salesEntriesRaw = await FB().getList(path: dbpath);
      _salesEntries.clear();
      for (var entryRaw in salesEntriesRaw) {
        SalesEntry entry =
            Utils().convertRawToDatatype(entryRaw, SalesEntry.fromJson);
        _salesEntries.add(entry);
      }
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createSalesEntryCard(int index) {
    SalesEntry entry = _salesEntries[index];
    return Widgets().createTopLevelCard(
        context: context,
        child: ListTileCompact(
          title: Text(
              "${DateFormat('HH:mm:ss').format(entry.timestamp)} - ₹${entry.count * entry.deepamPrice + (entry.isPlateIncluded ? entry.platePrice : 0)}"),
          leading: CircleAvatar(
            child: Text("${entry.count}"),
          ),
          subtitle: Widgets().createResponsiveRow(context, [
            Text(" mode: ${entry.paymentMode}"),
            if (entry.isPlateIncluded) Text(", Plate included"),
          ]),
          infotext: Text("user: ${entry.username}"),
          trailing: Widgets().createContextMenu(
              items: ["Edit", "Delete"],
              onPressed: (value) {
                if (value == "Edit") {
                  _onEditEntry(index);
                } else if (value == "Delete") {
                  _onDeleteEntry(index);
                }
              }),
        ));
  }

  Future<void> _onDeleteEntry(int index) async {
    SalesEntry entry = _salesEntries[index];

    // confirm dialog
    Widgets().showConfirmDialog(context, "Are you sure?", "Delete", () async {
      // delete from db
      String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
      String timekey = entry.timestamp.toIso8601String().replaceAll(".", "^");
      String dbpath =
          "${Const().dbrootGaruda}/Deepotsava/${widget.stall}/Sales/$dbdate/$timekey";
      await FB().deleteValue(path: dbpath);

      // delete from local list
      setState(() {
        _salesEntries.removeAt(index);
      });
    });
  }

  Future<void> _onEditEntry(int index) async {
    SalesEntry oldentry = _salesEntries[index];
    SalesEntry newentry = SalesEntry(
      timestamp: oldentry.timestamp,
      username: oldentry.username,
      count: oldentry.count,
      isPlateIncluded: oldentry.isPlateIncluded,
      paymentMode: oldentry.paymentMode,
      deepamPrice: oldentry.deepamPrice,
      platePrice: oldentry.platePrice,
    );

    Widgets().showResponsiveDialog(
        context: context,
        title: "Edit sales entry",
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // count
                  TextFormField(
                    initialValue: newentry.count.toString(),
                    decoration: InputDecoration(labelText: "Count"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      newentry.count = int.tryParse(value) ?? newentry.count;
                    },
                  ),

                  // plate include
                  SwitchListTile(
                    title: Text("Plate Included"),
                    value: newentry.isPlateIncluded,
                    onChanged: (value) {
                      setState(() {
                        newentry.isPlateIncluded = value;
                      });
                    },
                  ),

                  // payment mode
                  DropdownButtonFormField<String>(
                    value:
                        Const().paymentModes.keys.contains(newentry.paymentMode)
                            ? newentry.paymentMode
                            : Const().paymentModes.keys.first,
                    decoration:
                        const InputDecoration(labelText: "Payment Mode"),
                    items: Const()
                        .paymentModes
                        .keys
                        .map(
                          (mode) => DropdownMenuItem<String>(
                            value: mode,
                            child: Text(mode),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          newentry.paymentMode = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          ElevatedButton(
            child: Text("Update"),
            onPressed: () async {
              // update db
              String dbdate =
                  DateFormat("yyyy-MM-dd").format(newentry.timestamp);
              String timekey =
                  newentry.timestamp.toIso8601String().replaceAll(".", "^");
              String dbpath =
                  "${Const().dbrootGaruda}/Deepotsava/${widget.stall}/Sales/$dbdate/$timekey";
              await FB().setValue(path: dbpath, value: newentry.toJson());

              // update local list
              setState(() {
                _salesEntries[index] = newentry;
              });

              Navigator.of(context).pop();
            },
          )
        ]);
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
            // ResponsiveToolbarAction(
            //   icon: Icon(Icons.refresh),
            // ),
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

                      if (_salesEntries.isEmpty)
                        Text("No sales entries for this date."),

                      ...List.generate(
                        _salesEntries.length,
                        (index) => _createSalesEntryCard(index),
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
