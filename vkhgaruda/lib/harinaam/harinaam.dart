import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/counter_display.dart';
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
  final GlobalKey<CounterDisplayState> keyCounterDisplay =
      GlobalKey<CounterDisplayState>();

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

    // clear all controllers and focus nodes

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
                        child: CounterDisplay(key: keyCounterDisplay),
                      ),

                      // Chanters' club
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Chanters' club",
                        color: Colors.brown,
                        child: Column(
                          children: [
                            // HmiChanters widget
                            HmiChanters(key: keyHmiChanters),

                            // grey separator
                            Divider(color: Colors.grey[200]),
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
