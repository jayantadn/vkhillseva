import 'package:flutter/material.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/common/fb.dart';
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

  // seva dropdown
  final List<String> _sevaList = [];

  // controllers

  @override
  initState() {
    super.initState();

    // initialize seva list
    _sevaList.insert(0, 'Morning Nitya Seva');
    _sevaList.insert(1, 'Evening Nitya Seva');

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _sevaList.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // fetch festival sevas from db
    dynamic data = await FB().get("Config/Festivals");
    for (var element in List<dynamic>.from(data)) {
      Map map = Map<String, dynamic>.from(element);
      _sevaList.add(map['name']);
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
      selectedSeva = _sevaList.first;
    } else {
      selectedSeva = _sevaList[1];
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
                  items: _sevaList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                      ),
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
                // clear all lists

                // clear all controllers and focus nodes

                // close the dialog
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                // Handle the add session logic here
                print(
                    "Seva: ${selectedSeva}, Amount: $sevaAmount, Mode: $paymentMode");

                // clear all lists

                // clear all controllers and focus nodes

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
