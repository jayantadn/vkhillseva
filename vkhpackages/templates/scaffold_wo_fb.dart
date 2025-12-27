import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Inventory extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Inventory({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _ProcurementState createState() => _ProcurementState();
}

class _ProcurementState extends State<Inventory> {
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

      // refresh all child widgets
    });

    setState(() {
      _isLoading = false;
    });
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
    );
  }
}
