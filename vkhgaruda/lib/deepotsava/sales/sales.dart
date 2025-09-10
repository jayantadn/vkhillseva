import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/deepotsava/sales/inventory.dart';
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

  // lists

  // controllers, listeners and focus nodes

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

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createHMI(String paymentMode) {
    Color color =
        Const().paymentModes[paymentMode]?['color'] as Color? ?? Colors.grey;

    return Widgets().createTopLevelCard(
      context: context,
      title: paymentMode,
      color: color,
      child: Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData? theme;
    if (widget.stall == "RKC") {
      theme = ThemeCreator(primaryColor: Colors.pink).create();
    } else if (widget.stall == "RRG") {
      theme = ThemeCreator(primaryColor: Colors.black).create();
    }

    List<String> paymentModes = Const().paymentModes.keys.toList();

    return Theme(
      data: theme ?? Theme.of(context),
      child: Stack(
        children: [
          ResponsiveScaffold(
            // title
            title: widget.title,

            // toolbar icons
            toolbarActions: [
              // inventory management
              ResponsiveToolbarAction(
                icon: const Icon(Icons.playlist_add),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Inventory(
                              title: "Inventory",
                              splashImage: widget.splashImage)));
                },
              ),

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
                              title: "Inventory",
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
