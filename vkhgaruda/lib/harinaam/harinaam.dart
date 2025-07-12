import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/dashboard.dart';
import 'package:vkhgaruda/harinaam/datatypes.dart';
import 'package:vkhgaruda/harinaam/hmi_chanters.dart';
import 'package:vkhgaruda/harinaam/hmi_sales.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Harinaam extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Harinaam({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _HarinaamState createState() => _HarinaamState();
}

class _HarinaamState extends State<Harinaam> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  final GlobalKey<HmiChantersState> keyHmiChanters =
      GlobalKey<HmiChantersState>();
  final GlobalKey<HmiSalesState> keyHmiSales = GlobalKey<HmiSalesState>();
  final GlobalKey<DashboardState> keyDashboard = GlobalKey<DashboardState>();

  // lists
  final List<ChantersEntry> _chantersEntries = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps
    _chantersEntries.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control
    bool allowed = await Utils().checkPermission("Harinaam Mantapa");
    if (!allowed && mounted) {
      Toaster().error("You are not allowed to access Harinaam");
      Navigator.of(context).pop();
    }

    await _lock.synchronized(() async {
      // your code here
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addChanters(ChantersEntry entry) async {
    // update counter
    keyDashboard.currentState!.addChanters(entry.count);

    // add to the list
    setState(() {
      _chantersEntries.insert(0, entry);
    });

    // update database asynchronously
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/Harinaam/$dbdate/Chanters/$dbtime";
    FB().setJson(path: dbpath, json: entry.toJson());
  }

  Widget _createChantersTile(int index) {
    ChantersEntry entry = _chantersEntries[index];
    return Align(
        alignment: Alignment.centerLeft,
        child: IntrinsicWidth(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.brown),
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).cardColor,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: ListTile(
                title: Text(DateFormat("HH:mm").format(entry.timestamp)),
                leading: CircleAvatar(
                  backgroundColor: Colors.brown,
                  child: Text(entry.count.toString()),
                ),
                subtitle: Text(entry.username),
                trailing: Widgets().createContextMenu(
                  ["Edit", "Delete"],
                  (action) {
                    if (action == "Delete") {
                      // delete entry
                      setState(() {
                        _chantersEntries.removeAt(index);
                      });
                      Toaster().info("Entry deleted");
                    }
                  },
                ),
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // stock japamala
              IconButton(
                icon: const Icon(Icons.playlist_add),
                onPressed: () {},
              ),

              // more actions
              Widgets().createContextMenu(
                ["Settlement", "Reports"],
                (action) {
                  // handle context menu actions
                },
              ),
            ],
          ),
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

                      // counter display
                      Widgets().createTopLevelCard(
                        context: context,
                        child: Dashboard(key: keyDashboard),
                      ),

                      // Chanters' club
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Chanters' club",
                        color: Colors.brown,
                        child: Column(
                          children: [
                            // HmiChanters widget
                            HmiChanters(
                                key: keyHmiChanters,
                                onSubmit: (count) {
                                  // create a new entry
                                  ChantersEntry entry = ChantersEntry(
                                    count: count,
                                    timestamp: DateTime.now(),
                                    username: Utils().getUsername(),
                                  );
                                  _addChanters(entry);
                                }),

                            // chanters entries list
                            if (_chantersEntries.isNotEmpty)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(
                                    _chantersEntries.length,
                                    (index) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4.0),
                                      child: _createChantersTile(index),
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),

                      // Japamala sales
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Japamala sales",
                        child: Column(
                          children: [
                            HmiSales(key: keyHmiSales),

                            // grey separator
                            Divider(color: Colors.grey[200]),
                          ],
                        ),
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
        if (_isLoading)
          LoadingOverlay(
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
