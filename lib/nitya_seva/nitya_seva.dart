import 'package:flutter/material.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/common/datatypes.dart';
import 'package:vkhillseva/common/fb.dart';
import 'package:vkhillseva/nitya_seva/session.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:vkhillseva/nitya_seva/day_summary.dart';
import 'package:vkhillseva/widgets/date_header.dart';
import 'package:vkhillseva/widgets/launcher_tile.dart';

class NityaSeva extends StatefulWidget {
  final String title;

  const NityaSeva({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _NityaSevaState createState() => _NityaSevaState();
}

class _NityaSevaState extends State<NityaSeva> {
  bool _isLoading = true;

  // lists
  final List<FestivalSettings> _sevaList = [];
  final List<Session> _sessions = [];

  // controllers

  @override
  initState() {
    super.initState();

    // initialize seva list
    _sevaList.insert(
        0,
        FestivalSettings(
            id: 999, // dummy id
            name: 'Morning Nitya Seva',
            icon: "assets/images/Common/morning.png"));
    _sevaList.insert(
        1,
        FestivalSettings(
            id: 998,
            name: 'Evening Nitya Seva',
            icon: "assets/images/Common/morning.png"));

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _sevaList.clear();
    _sessions.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // fetch festival sevas from db
    dynamic data = await FB().get("Config/Festivals");
    if (data != null) {
      for (var element in List<dynamic>.from(data)) {
        Map<String, dynamic> map = Map<String, dynamic>.from(element);
        _sevaList.add(FestivalSettings.fromJson(map));
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createSession() async {
    final double padding = 10.0;

    // select default seva
    String selectedSeva = '';
    DateTime now = DateTime.now();
    if (now.hour < 14) {
      selectedSeva = _sevaList.first.name;
    } else {
      selectedSeva = _sevaList[1].name;
    }

    // seva amount
    List<String> sevaAmounts = [];
    Const().nityaSeva['amounts']?.forEach((element) {
      element.forEach((key, value) {
        sevaAmounts.add(key);
      });
    });
    String sevaAmount = sevaAmounts.first;

    // payment mode
    List<String> paymentModes = [];
    Const().paymentModes.forEach(
      (key, value) {
        paymentModes.add(key);
      },
    );
    String paymentMode = paymentModes.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Session',
              style: Theme.of(context).textTheme.headlineMedium),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                // drop down for seva
                DropdownButtonFormField<String>(
                  value: selectedSeva, // Set the default value here
                  decoration: InputDecoration(labelText: 'Seva'),
                  // items: _sevaList.map((String value) {
                  //   return DropdownMenuItem<String>(
                  //     value: value,
                  //     child: Text(
                  //       value,
                  //     ),
                  //   );
                  // }).toList(),
                  items: _sevaList.map((FestivalSettings value) {
                    return DropdownMenuItem<String>(
                      value: value.name,
                      child: Text(value.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      if (newValue != null) {
                        selectedSeva = newValue;
                      }
                    });
                  },
                ),

                // default amount
                SizedBox(height: padding),
                DropdownButtonFormField<String>(
                  value: sevaAmount, // Set the default value here
                  decoration: InputDecoration(labelText: 'Default seva amount'),
                  items: sevaAmounts.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    sevaAmount = newValue ?? sevaAmounts.first;
                  },
                ),

                // default payment mode
                SizedBox(height: padding),
                DropdownButtonFormField<String>(
                  value: paymentMode,
                  decoration:
                      InputDecoration(labelText: 'Default payment mode'),
                  items: paymentModes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    paymentMode = newValue ?? paymentModes.first;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                // clear all local lists

                // clear all local controllers and focus nodes

                // close the dialog
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                // find the icon for the selected seva
                String icon = '';
                for (var element in _sevaList) {
                  if (element.name == selectedSeva) {
                    icon = element.icon;
                    break;
                  }
                }

                // Handle the add session logic here
                _sessions.add(
                  Session(
                    seva: selectedSeva,
                    defaultAmount: sevaAmount,
                    defaultPaymentMode: paymentMode,
                    icon: icon,
                    sevakarta: 'Unknown',
                    timestamp: now,
                  ),
                );

                // clear all local lists

                // clear all local controllers and focus nodes

                // close the dialog
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
            ),
            body: Padding(
              padding: const EdgeInsets.all(4.0),
              child: RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                  children: [
                    // date header
                    DateHeader(
                        callbacks:
                            DateHeaderCallbacks(onChange: (DateTime date) {})),

                    // slot tiles
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // slot 1
                          LauncherTile2(
                            image: 'assets/images/Common/morning.png',
                            title: 'Sat Morning',
                            text: "Sumitra Krishna Dasa, 14-12-2024 10:15",
                            callback: LauncherTileCallback(onClick: () {}),
                          ),

                          // slot 2
                          LauncherTile2(
                            image: 'assets/images/Common/evening.png',
                            title: 'Sat Evening',
                            text: "Jayanta Debnath, 14-12-2024 16:15",
                            callback: LauncherTileCallback(onClick: () {}),
                          ),

                          // add slot
                          LauncherTile2(
                            image: 'assets/images/Common/add.png',
                            title: 'New Session',
                            text: "Add a new session",
                            callback: LauncherTileCallback(onClick: () {
                              _createSession();
                            }),
                          ),
                        ],
                      ),
                    ),

                    // summary
                    DaySummary(),
                  ],
                ),
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(image: 'assets/images/LauncherIcons/NityaSeva.png'),
        ],
      ),
    );
  }
}
