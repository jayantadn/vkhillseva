import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
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

  @override
  Widget build(BuildContext context) {
    ThemeData? theme;
    if (widget.stall == "RKC") {
      theme = ThemeCreator(primaryColor: Colors.pink).create();
    } else if (widget.stall == "RRG") {
      theme = ThemeCreator(primaryColor: Colors.black).create();
    }

    return Theme(
      data: theme ?? Theme.of(context),
      child: Stack(
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
                        Widgets().createTopLevelCard(
                          context: context,
                          child: ListTile(
                            title: Text("Hello World"),
                            subtitle: Text("This is a sample card"),
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
          if (_isLoading) LoadingOverlay(image: widget.splashImage),
        ],
      ),
    );
  }
}
