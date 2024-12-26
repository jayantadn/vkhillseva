import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';

class NityaSeva extends StatefulWidget {
  final String title;
  final String icon;

  const NityaSeva({super.key, required this.title, required this.icon});

  @override
  _NityaSevaState createState() => _NityaSevaState();
}

class _NityaSevaState extends State<NityaSeva> {
  bool _isLoading = true;
  final DateTime _selectedDate = DateTime.now();

  // lists

  // controllers, listeners and focus nodes
  // ignore: prefer_final_fields
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes
    for (var listener in _listeners) {
      listener.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

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
            ),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                children: [
                  const Placeholder(),
                ],
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon)
        ],
      ),
    );
  }
}
