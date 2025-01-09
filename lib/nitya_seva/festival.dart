import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/common/fb.dart';
import 'package:vkhillseva/common/utils.dart';
import 'package:vkhillseva/nitya_seva/session.dart';
import 'package:vkhillseva/nitya_seva/ticket_page.dart';
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
  final Map<String, List<String>> _sessions = {};

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

    Utils().fetchFestivalIcons();

    // perform sync operations here
    await _lock.synchronized(() async {
      _sessions.clear();
      for (var dateRaw in datesRaw) {
        Map<String, dynamic> dateMap = Map<String, dynamic>.from(dateRaw);

        dateMap.forEach((key, valueRaw) async {
          Map<String, dynamic> sessionMap = Map<String, dynamic>.from(valueRaw);
          Map<String, dynamic> sessionJson =
              Map<String, dynamic>.from(sessionMap['Settings']);
          Session session = Session.fromJson(sessionJson);
          if (session.name != "Nitya Seva" && session.name != "Testing") {
            // session label
            String label = "";
            String date = DateFormat("dd-MMM-yyyy").format(session.timestamp);
            if (session.timestamp.hour < Const().morningCutoff) {
              label = "$date ${session.type} Morning";
            } else {
              label = "$date ${session.type} Evening";
            }

            // read all tickets for the session
            String dbDate = DateFormat("yyyy-MM-dd").format(session.timestamp);
            String dbSession =
                session.timestamp.toIso8601String().replaceAll(".", "^");
            List ticketsRaw = await FB()
                .getList(path: "NityaSeva/$dbDate/$dbSession/Tickets");
            int numTickets = 0;
            int sumAmount = 0;
            for (var ticketRaw in ticketsRaw) {
              Map<String, dynamic> ticketMap =
                  Map<String, dynamic>.from(ticketRaw);

              Ticket ticket = Ticket.fromJson(ticketMap);
              sumAmount += ticket.amount;
              numTickets++;
            }
            label +=
                ": tickets - $numTickets, amount - ${Utils().formatIndianCurrency(sumAmount.toString())}";

            if (_sessions.containsKey(session.name)) {
              _sessions[session.name]!.add(label);
            } else {
              _sessions[session.name] = [label];
            }
          }
        });
      }
    });

    // sort _sessions by the date in the label of the first item in each list
    var sortedSessions = Map.fromEntries(_sessions.entries.toList()
      ..sort((a, b) {
        DateTime dateA =
            DateFormat("dd-MMM-yyyy").parse(a.value.first.substring(0, 11));
        DateTime dateB =
            DateFormat("dd-MMM-yyyy").parse(b.value.first.substring(0, 11));
        return dateA.compareTo(dateB);
      }));

    // sort each list inside the map
    sortedSessions.forEach((key, value) {
      value.sort((a, b) {
        DateTime dateA = DateFormat("dd-MMM-yyyy").parse(a.substring(0, 11));
        DateTime dateB = DateFormat("dd-MMM-yyyy").parse(b.substring(0, 11));
        return dateA.compareTo(dateB);
      });
    });

    // update _sorted
    _sessions
      ..clear()
      ..addAll(sortedSessions);

    // clear all lists
    datesRaw.clear();

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createFestivalCards(String festival, List<String> sessions) {
    return Card(
      child: ListTile(
        title: Column(
          children: [
            Row(
              children: [
                // image
                CircleAvatar(
                  backgroundImage:
                      AssetImage(Utils().getFestivalIcon(festival)),
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
                          Expanded(
                            child: Text(session,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
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
