import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class SangeetSeva extends StatefulWidget {
  final String title;
  final String? splashImagePath;

  const SangeetSeva({super.key, required this.title, this.splashImagePath});

  @override
  // ignore: library_private_types_in_public_api
  _SangeetSevaState createState() => _SangeetSevaState();
}

class _SangeetSevaState extends State<SangeetSeva> {
  // global keys

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
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    // perform async operations here

    await _lock.synchronized(() async {
      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    // perform any remaining async operations here

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = ThemeCreator(primaryColor: Color(0xFF800000)).create();
    return Theme(
      data: theme,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text(widget.title)),
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

                        Widgets().createResponsiveTopLevelContainer(context, [
                          // your widgets here
                          Widgets().createTopLevelCard(context, SSWelcome()),
                        ]),

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
              image: widget.splashImagePath ??
                  "assets/images/Logo/KrishnaLilaPark_circle.png",
            ),
        ],
      ),
    );
  }
}
