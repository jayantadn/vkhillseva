import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/calendar.dart';
import 'package:vkhgaruda/sangeet_seva/profiles.dart';
import 'package:vkhgaruda/widgets/loading_overlay.dart';
import 'package:vkhgaruda/common/theme.dart';
import 'package:table_calendar/table_calendar.dart';

class SangeetSeva extends StatefulWidget {
  final String title;
  final String? icon;

  const SangeetSeva({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _SangeetSevaState createState() => _SangeetSevaState();
}

class _SangeetSevaState extends State<SangeetSeva> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  final Widget _calendar = Calendar();

  // lists
  List<int> _numBookings = [];
  List<int> _numAvlSlots = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    // set _numBookings and _numAvlSots to 0
    _numBookings = List<int>.filled(31, 0);
    _numAvlSlots = List<int>.filled(31, 0);

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _numBookings.clear();
    _numAvlSlots.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                IconButton(
                  icon: Icon(Icons.group),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Profiles(
                              title: 'Performer Profiles', icon: widget.icon)),
                    );
                  },
                )
              ],
            ),
            body: RefreshIndicator(
                onRefresh: refresh,
                child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(children: [
                          // leave some space at top
                          SizedBox(height: 10),

                          // your widgets here
                          _calendar,

                          // leave some space at bottom
                          SizedBox(height: 100),
                        ])))),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // Add your onPressed code here!
              },
              tooltip: 'Add',
              child: Icon(Icons.add),
            ),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon)
        ],
      ),
    );
  }
}
