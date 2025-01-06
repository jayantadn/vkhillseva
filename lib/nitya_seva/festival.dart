import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhillseva/common/fb.dart';
import 'package:vkhillseva/nitya_seva/session.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';

class FestivalRecord extends StatefulWidget {
  final String title;
  final String icon;

  const FestivalRecord({super.key, required this.title, required this.icon});

  @override
  _FestivalRecordState createState() => _FestivalRecordState();
}

class _FestivalRecordState extends State<FestivalRecord> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  String _selectedYear = "";
  Map<String, List<Session>> _sessions = {};

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    _selectedYear = DateFormat("yyyy").format(DateTime.now());

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // dispose all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here
    List datesRaw =
        await FB().getListByYear(path: "NityaSeva", year: _selectedYear);

    // perform sync operations here
    await _lock.synchronized(() async {
      for (var dateRaw in datesRaw) {
        Map<String, dynamic> dateMap = Map<String, dynamic>.from(dateRaw);

        dateMap.forEach((key, valueRaw) {
          Map<String, dynamic> sessionMap = Map<String, dynamic>.from(valueRaw);
          Map<String, dynamic> sessionJson =
              Map<String, dynamic>.from(sessionMap['Settings']);
          Session session = Session.fromJson(sessionJson);
          if (session.name != "Nitya Seva" && session.name != "Testing") {
            if (_sessions.containsKey(session.name)) {
              _sessions[session.name]!.add(session);
            } else {
              _sessions[session.name] = [session];
            }
          }
        });
      }
    });

    // clear all lists
    datesRaw.clear();

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
                DropdownButton<String>(
                  value: _selectedYear,
                  onChanged: (String? newValue) {
                    _selectedYear = newValue!;
                    refresh();
                  },
                  items: List.generate(
                    DateTime.now().year - 2023,
                    (index) => (2024 + index).toString(),
                  ).map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: Theme.of(context).textTheme.bodyLarge),
                    );
                  }).toList(),
                )
              ],
            ),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                children: [],
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
