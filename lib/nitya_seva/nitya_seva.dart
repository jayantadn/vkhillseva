import 'package:flutter/material.dart';
import 'package:vkhillseva/common/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:vkhillseva/nitya_seva/day_summary.dart';
import 'package:vkhillseva/widgets/date_header.dart';
import 'package:vkhillseva/widgets/launcher_tile.dart';

class NityaSeva extends StatefulWidget {
  final String title;

  const NityaSeva({super.key, required this.title});

  @override
  _NityaSevaState createState() => _NityaSevaState();
}

class _NityaSevaState extends State<NityaSeva> {
  bool _isLoading = true;

  @override
  initState() {
    super.initState();

    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            children: [
              RefreshIndicator(
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
                            callback: LauncherTileCallback(onClick: () {}),
                          ),
                        ],
                      ),
                    ),

                    // summary
                    DaySummary(),
                  ],
                ),
              ),

              // circular progress indicator
              if (_isLoading)
                LoadingOverlay(
                    image: 'assets/images/LauncherIcons/NityaSeva.png'),
            ],
          ),
        ),
      ),
    );
  }
}
