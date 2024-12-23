import 'package:flutter/material.dart';
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
  String _selectedSeva = '';

  @override
  initState() {
    super.initState();

    // initialize seva list
    _sevaList.insert(0, 'Morning Nitya Seva');
    _sevaList.insert(1, 'Evening Nitya Seva');

    // select default seva
    DateTime now = DateTime.now();
    if (now.hour < 14) {
      _selectedSeva = _sevaList.first;
    } else {
      _selectedSeva = _sevaList[1];
    }

    refresh();
  }

  @override
  dispose() {
    _sevaList.clear();

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createSession() async {
    final double padding = 8.0;

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
                  value: _selectedSeva, // Set the default value here
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
                      if (newValue != null) _selectedSeva = newValue;
                    });
                  },
                ),

                SizedBox(height: padding),

                SizedBox(height: padding),

                // default amount
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Sample Data'),
                  items:
                      ['Option 1', 'Option 2', 'Option 3'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {},
                ),

                SizedBox(height: padding),

                // default payment mode
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Sample Data'),
                  items:
                      ['Option 1', 'Option 2', 'Option 3'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {},
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                // Handle the add session logic here
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
