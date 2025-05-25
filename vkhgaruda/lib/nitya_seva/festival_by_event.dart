import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class FestivalRecordByEvent extends StatefulWidget {
  final String title;
  final String? splashImage;

  const FestivalRecordByEvent(
      {super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _FestivalRecordByEventState createState() => _FestivalRecordByEventState();
}

class _FestivalRecordByEventState extends State<FestivalRecordByEvent> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists
  final List<String> _festivalNames = [];
  final Map<int, int> _ticketsSold = {}; // <yes, count>

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps
    _festivalNames.clear();
    _ticketsSold.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // populate the festivals list
      List festivalsRaw = await FB()
          .getList(path: "${Const().dbrootGaruda}/Settings/NityaSevaList");
      if (festivalsRaw.isNotEmpty) {
        _festivalNames.clear();
        for (var festival in festivalsRaw) {
          Map<String, dynamic> festivalMap =
              Map<String, dynamic>.from(festival);
          if (festivalMap['name'].isNotEmpty &&
              festivalMap['name'] != 'Nitya Seva' &&
              festivalMap['name'] != 'Testing') {
            _festivalNames.add(festivalMap['name'] ?? '');
          }
        }
      }
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createDataTile(int index) {
    int key = _ticketsSold.keys.toList()[index];
    return ListTile(title: Text("${_ticketsSold[key]}"));
  }

  Widget _createFestivalDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Festival',
        border: OutlineInputBorder(),
      ),
      items: _festivalNames.map((String festival) {
        return DropdownMenuItem<String>(
          value: festival,
          child: Text(festival),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          _onFestivalSelection(newValue);
        }
      },
      hint: Text('Select a festival'),
    );
  }

  Future<void> _onFestivalSelection(String festivalName) async {
    _ticketsSold.clear();

    // this year
    DateTime now = DateTime.now();
    DateTime startOfYear = DateTime(now.year, 1, 1);
    var recordsThisYear = await FB().getValuesByDateRange(
      path: "${Const().dbrootGaruda}/NityaSeva",
      startDate: startOfYear,
    );
    List<String> recordsThisYearKeys = recordsThisYear.keys.toList();
    for (var key in recordsThisYearKeys) {
      var sessionsRaw = recordsThisYear[key];
      var sessionsMap = Utils().convertRawToJson(sessionsRaw);
      List<String> sessionsKeys = sessionsMap.keys.toList();

      for (String sessionKey in sessionsKeys) {
        var sessionMap = Utils().convertRawToJson(sessionsMap[sessionKey]);
        Session sessionSettings = Utils()
            .convertRawToDatatype(sessionMap['Settings'], Session.fromJson);
        int year = int.parse(DateFormat("yyyy").format(now));
        if (sessionSettings.name == festivalName) {
          setState(() {
            if (_ticketsSold[year] == null) {
              _ticketsSold[year] = sessionMap['Tickets'].length;
            } else {
              _ticketsSold[year] =
                  (_ticketsSold[year]! + sessionMap['Tickets'].length).toInt();
            }
          });
        }
      }
    }

    // previous years
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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

                      // your widgets here
                      Widgets().createTopLevelCard(
                          context: context,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(children: [
                              // dropdown
                              _createFestivalDropdown(),

                              // empty record
                              if (_ticketsSold.isEmpty) Text("Not records yet"),

                              // records
                              if (_ticketsSold.isNotEmpty)
                                ...List.generate(_ticketsSold.length,
                                    (index) => _createDataTile(index)),
                            ]),
                          )),

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
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
