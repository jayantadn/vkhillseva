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
    int year = _ticketsSold.keys.toList()[index];
    int value = _ticketsSold[year] ?? 0;

    // Find the max value for scaling
    int maxValue = _ticketsSold.values.isNotEmpty
        ? _ticketsSold.values.reduce((a, b) => a > b ? a : b)
        : 1;

    // Calculate bar width as a fraction of available width
    double barFraction = maxValue > 0 ? value / maxValue : 0;

    return ListTile(
      leading: Text(year.toString(),
          style: Theme.of(context).textTheme.headlineSmall),
      title: LayoutBuilder(
        builder: (context, constraints) {
          double barWidth = constraints.maxWidth * barFraction;
          return Stack(
            children: [
              Container(
                height: 24,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 24,
                width: barWidth,
                decoration: BoxDecoration(
                  color: Utils().getRandomDarkColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      color: barFraction > 0.5 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black26,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      trailing: SizedBox.shrink(),
    );
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
    setState(() {
      _isLoading = true;
      _ticketsSold.clear();
    });

    // this year
    DateTime now = DateTime.now();
    DateTime startOfYear = DateTime(now.year, 1, 1);
    DateTime? end;
    while (true) {
      var recordsThisYear = await FB().getValuesByDateRange(
          path: "${Const().dbrootGaruda}/NityaSeva",
          startDate: startOfYear,
          endDate: end ?? now);
      if (recordsThisYear.isEmpty) {
        // no records found for this year, break the loop
        setState(() {});
        break;
      }

      List<String> recordsThisYearKeys = recordsThisYear.keys.toList();
      for (var key in recordsThisYearKeys) {
        var sessionsRaw = recordsThisYear[key];
        var sessionsMap = Utils().convertRawToJson(sessionsRaw);
        List<String> sessionsKeys = sessionsMap.keys.toList();

        for (String sessionKey in sessionsKeys) {
          var sessionMap = Utils().convertRawToJson(sessionsMap[sessionKey]);
          Session sessionSettings = Utils()
              .convertRawToDatatype(sessionMap['Settings'], Session.fromJson);
          int year = int.parse(DateFormat("yyyy").format(startOfYear));
          if (sessionSettings.name == festivalName) {
            setState(() {
              if (_ticketsSold[year] == null) {
                _ticketsSold[year] = sessionMap['Tickets'].length;
              } else {
                _ticketsSold[year] =
                    (_ticketsSold[year]! + sessionMap['Tickets'].length)
                        .toInt();
              }
            });
          }
        }
      }

      // rewind 1 year
      startOfYear = DateTime(startOfYear.year - 1, 1, 1);
      end = DateTime(startOfYear.year, 12, 31);
    }

    setState(() {
      _isLoading = false;
    });
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
            image: widget.splashImage,
          ),
      ],
    );
  }
}
