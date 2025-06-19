import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class FestivalRecordByYear extends StatefulWidget {
  final String title;
  final String icon;

  const FestivalRecordByYear(
      {super.key, required this.title, required this.icon});

  @override
  _FestivalRecordByYearState createState() => _FestivalRecordByYearState();
}

class _FestivalRecordByYearState extends State<FestivalRecordByYear> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  String _selectedYear = "";

  final List<Map<String, dynamic>> _festivals = [];

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
    List datesRaw = await FB().getListByYear(
        path: "${Const().dbrootGaruda}/NityaSeva", year: _selectedYear);

    await Utils().fetchFestivalIcons();

    // perform sync operations here
    await _lock.synchronized(() async {
      _festivals.clear();
      for (var dateRaw in datesRaw) {
        Map<String, dynamic> dateMap = Map<String, dynamic>.from(dateRaw);

        dateMap.forEach((key, valueRaw) {
          Map<String, dynamic> sessionMap = Map<String, dynamic>.from(valueRaw);
          Map<String, dynamic> sessionJson =
              Map<String, dynamic>.from(sessionMap['Settings']);
          Session session = Session.fromJson(sessionJson);
          if (session.name != "Nitya Seva" && session.name != "Testing") {
            Map<String, dynamic> festival = {
              "name": session.name,
              "icon": Utils().getFestivalIcon(session.name),
              "sessions": [
                {
                  'settings': session,
                  "numTickets": 0,
                  "sumAmount": 0,
                }
              ]
            };

            // check if festival already exists
            bool found = false;
            for (var entry in _festivals) {
              if (entry['name'] == festival['name']) {
                entry['sessions'].add(festival['sessions'][0]);
                found = true;
                break;
              }
            }

            if (!found) {
              _festivals.add(festival);
            }
          }
        });
      }
    });

    // sort _festivals by festival['sessions'][0]['settings'].timestamp
    _festivals.sort((a, b) => a['sessions'][0]['settings']
        .timestamp
        .compareTo(b['sessions'][0]['settings'].timestamp));

    // sort sessions inside festivals by timestamp
    for (var festival in _festivals) {
      List<Map<String, dynamic>> sessions = festival['sessions'];
      sessions.sort(
          (a, b) => a['settings'].timestamp.compareTo(b['settings'].timestamp));
    }

    // inject the ticket details
    for (var festival in _festivals) {
      for (var ss in festival['sessions']) {
        Session session = ss['settings'];
        String dbDate = DateFormat("yyyy-MM-dd").format(session.timestamp);
        String dbSession =
            session.timestamp.toIso8601String().replaceAll(".", "^");
        List ticketsRaw = await FB().getList(
            path:
                "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/Tickets");
        int numTickets = 0;
        int sumAmount = 0;
        for (var ticketRaw in ticketsRaw) {
          Map<String, dynamic> ticketMap = Map<String, dynamic>.from(ticketRaw);

          Ticket ticket = Ticket.fromJson(ticketMap);
          sumAmount += ticket.amount;
          numTickets++;
        }

        ss['numTickets'] = numTickets;
        ss['sumAmount'] = sumAmount;
      }
    }

    // clear all lists
    datesRaw.clear();

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createFestivalCard(Map<String, dynamic> festival) {
    return Card(
      child: ListTile(
        title: Column(
          children: [
            Row(
              children: [
                // image
                if (festival['icon'].isNotEmpty)
                  CircleAvatar(
                    backgroundImage: AssetImage(festival['icon']),
                  ),

                // festival name
                SizedBox(width: 10),
                Text(festival['name'],
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            Divider(),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var session in festival['sessions'])
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(4),
                        child: Column(
                          children: [
                            // date
                            Text(
                                DateFormat("dd")
                                    .format(session['settings'].timestamp),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(fontWeight: FontWeight.bold)),

                            // month
                            Text(
                                DateFormat("MMM")
                                    .format(session['settings'].timestamp),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 10),
                          // seva name
                          Row(
                            children: [
                              Text(session['settings'].type,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                  session['settings'].timestamp.hour <
                                          Const().morningCutoff
                                      ? " Morning"
                                      : " Evening",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              // tickets
                              Text("Tickets: ${session['numTickets']}",
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),

                              // amount
                              SizedBox(width: 10),
                              Text(
                                  "Amount: ${Utils().formatIndianCurrency(session['sumAmount'])}",
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(),
                ],
              ),
          ],
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
      data: themeGaruda,
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
                  for (var entry in _festivals) _createFestivalCard(entry),
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
