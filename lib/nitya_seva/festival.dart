import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhillseva/common/const.dart';
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
      _sessions.clear();
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

    // sort all sessions
    _sessions.forEach((key, value) {
      value.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    // clear all lists
    datesRaw.clear();

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createFestivalCards(String festival, List<Session> sessions) {
    return Card(
      child: ListTile(
        title: Column(
          children: [
            Row(
              children: [
                // image
                CircleAvatar(
                  backgroundImage: AssetImage(sessions[0].icon),
                ),

                // festival name
                SizedBox(width: 10),
                Text(festival,
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            Divider(),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sessions
              .map((session) => Column(
                    children: [
                      Row(
                        children: [
                          // date
                          Text(DateFormat("dd-MMM-yyyy")
                              .format(session.timestamp)
                              .toString()),

                          // seva type
                          SizedBox(width: 10),
                          Text(session.type),

                          // session timing
                          SizedBox(width: 10),
                          session.timestamp.hour < Const().morningCutoff
                              ? Text("Morning: ")
                              : Text("Evening: "),
                        ],
                      ),
                      Divider(),
                    ],
                  ))
              .toList(),
        ),
        onTap: () {
          // handle tap
        },
      ),
    );
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
                children: [
                  for (var entry in _sessions.entries)
                    _createFestivalCards(entry.key, entry.value),
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
