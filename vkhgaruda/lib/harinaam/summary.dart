import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Summary extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Summary({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _SummaryState createState() => _SummaryState();
}

class _SummaryState extends State<Summary> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  String _period = "daily";
  String _periodDetails = DateFormat("dd MMM, yyyy").format(DateTime.now());

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createHMI() {
    return Widgets().createTopLevelCard(
      context: context,
      child: ListTile(
          // previous button
          leading: IconButton(
            icon: Transform.rotate(
              angle: 3.14, // Rotate 180 degrees to point left
              child: Icon(
                Icons.play_arrow,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            onPressed: _prev,
          ),

          // dropdown
          title: Center(
            child: DropdownButton<String>(
              value: _period,
              items: const [
                DropdownMenuItem(value: "daily", child: Text("Daily")),
                DropdownMenuItem(value: "weekly", child: Text("Weekly")),
                DropdownMenuItem(value: "monthly", child: Text("Monthly")),
                DropdownMenuItem(value: "yearly", child: Text("Yearly")),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _period = newValue ?? _period;

                  switch (_period) {
                    case "daily":
                      _periodDetails =
                          DateFormat("dd MMM, yyyy").format(DateTime.now());
                      break;
                    case "weekly":
                      String cutoffDate = _getLastCutoffDate(DateTime.now());

                      String today =
                          DateFormat("dd MMM, yyyy").format(DateTime.now());

                      _periodDetails = "$cutoffDate - $today";
                      break;
                    case "monthly":
                      _periodDetails =
                          DateFormat("MMMM yyyy").format(DateTime.now());
                      break;
                    case "yearly":
                      _periodDetails =
                          DateFormat("yyyy").format(DateTime.now());
                      break;
                  }
                });
              },
            ),
          ),

          // selection label
          subtitle: Center(
              child: Text(
            _periodDetails,
            style: Theme.of(context).textTheme.bodyMedium,
          )),

          // next button
          trailing: IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ), // Default points right
            onPressed: _next,
          )),
    );
  }

  String _getLastCutoffDate(DateTime date) {
    // Find the last occurrence of the settlement day and return the day after
    DateTime current = date;
    String targetDay = Const().weeklyHarinaamSettlementDay;

    // Convert day names to weekday numbers (Monday = 1, Sunday = 7)
    Map<String, int> dayToWeekday = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };

    int targetWeekday = dayToWeekday[targetDay] ?? 1;

    // Scroll backwards to find the last occurrence of the target day
    do {
      current = current.subtract(Duration(days: 1));
    } while (current.weekday != targetWeekday);

    // Return the date 1 day after the settlement day
    DateTime cutoffDate = current.add(Duration(days: 1));
    return DateFormat("dd MMM, yyyy").format(cutoffDate);
  }

  Future<void> _prev() async {
    switch (_period) {
      case "daily":
        DateTime currentDate = DateFormat("dd MMM, yyyy").parse(_periodDetails);
        DateTime previousDate = currentDate.subtract(Duration(days: 1));

        setState(() {
          _periodDetails = DateFormat("dd MMM, yyyy").format(previousDate);
        });

        break;
      case "weekly":
        String startOfWeek = _periodDetails.split('-')[0].trim();
        DateTime currentStartDate =
            DateFormat("dd MMM, yyyy").parse(startOfWeek);
        DateTime previousStartDate =
            currentStartDate.subtract(Duration(days: 7));
        DateTime previousEndDate = previousStartDate.add(Duration(days: 6));

        setState(() {
          _periodDetails =
              "${DateFormat("dd MMM, yyyy").format(previousStartDate)} - ${DateFormat("dd MMM, yyyy").format(previousEndDate)}";
        });

        break;
      case "monthly":
        break;
      case "yearly":
        break;
    }
  }

  Future<void> _next() async {
    switch (_period) {
      case "daily":
        DateTime currentDate = DateFormat("dd MMM, yyyy").parse(_periodDetails);

        DateTime today = DateTime.now();
        if (currentDate.year == today.year &&
            currentDate.month == today.month &&
            currentDate.day == today.day) {
          return;
        }

        DateTime nextDate = currentDate.add(Duration(days: 1));

        setState(() {
          _periodDetails = DateFormat("dd MMM, yyyy").format(nextDate);
        });

        break;
      case "weekly":
        break;
      case "monthly":
        break;
      case "yearly":
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveScaffold(
          // title
          title: widget.title,

          // toolbar icons
          toolbarActions: [
            // ResponsiveToolbarAction(
            //   icon: Icon(Icons.refresh),
            // ),
          ],

          // body
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
                      _createHMI(),

                      // leave some space at bottom
                      SizedBox(height: 500),
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
