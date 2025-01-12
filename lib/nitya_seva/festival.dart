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

  final List<Map<String, dynamic>> _festivals = [
    {
      "name": "Vaikuntha Ekadashi",
      "icon": "assets/images/VKHillDieties/Govinda.png",
      "sessions": [
        {
          'settings': Session.fromJson({
            'name': "name",
            'type': "Kumkum Archana",
            'defaultAmount': 500,
            'defaultPaymentMode': "UPI",
            'icon': "assets/images/VKHillDieties/Govinda.png",
            'sevakarta': "Guest",
            'timestamp': DateTime.now().toIso8601String(),
          }),
          "numTickets": 100,
          "sumAmount": 50000,
        }
      ]
    }
  ];

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
        List ticketsRaw =
            await FB().getList(path: "NityaSeva/$dbDate/$dbSession/Tickets");
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

  Widget _createFestivalCards(Map<String, dynamic> festival) {
    return Card(
      child: ListTile(
        title: Column(
          children: [
            Row(
              children: [
                // image
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
                    children: [
                      // date
                      Text(
                          DateFormat("dd-MMM-yyyy")
                              .format(session['settings'].timestamp),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontWeight: FontWeight.bold)),

                      // seva name
                      SizedBox(width: 10),
                      Text(session['settings'].type,
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(session['settings'].timestamp.hour <
                              Const().morningCutoff
                          ? " Morning"
                          : " Evening"),
                    ],
                  ),
                  Row(
                    children: [
                      // tickets
                      Text("Tickets: ${session['numTickets']}",
                          style: Theme.of(context).textTheme.bodyMedium),

                      // amount
                      SizedBox(width: 10),
                      Text(
                          "Amount: ${Utils().formatIndianCurrency(session['sumAmount'])}",
                          style: Theme.of(context).textTheme.bodyMedium),
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
                  for (var entry in _festivals) _createFestivalCards(entry),
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
