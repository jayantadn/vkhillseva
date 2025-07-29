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
      child: Container(
        padding: const EdgeInsets.all(12.0), // Reduced from 16
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Period selector row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button with animation (more compact)
                Container(
                  width: 40, // Fixed width
                  height: 40, // Fixed height
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withOpacity(0.9), // Dark background
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero, // Remove default padding
                    icon: AnimatedRotation(
                      turns: 0.5,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white, // White icon
                        size: 18, // Slightly smaller
                      ),
                    ),
                    onPressed: _prev,
                  ),
                ),

                // Dropdown with enhanced styling (more compact)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 0), // Minimal vertical padding
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: _period,
                    underline: Container(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).primaryColor,
                      size: 20, // Slightly smaller
                    ),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14, // Reduced font size
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "daily",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today, size: 16), // Smaller icons
                            SizedBox(width: 6), // Reduced spacing
                            Text("Daily"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "weekly",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_week, size: 16),
                            SizedBox(width: 6),
                            Text("Weekly"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "monthly",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month, size: 16),
                            SizedBox(width: 6),
                            Text("Monthly"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "yearly",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 16),
                            SizedBox(width: 6),
                            Text("Yearly"),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _period = newValue ?? _period;

                        // Update period details based on selection
                        switch (_period) {
                          case "daily":
                            _periodDetails = DateFormat("dd MMM, yyyy")
                                .format(DateTime.now());
                            break;
                          case "weekly":
                            DateTime now = DateTime.now();
                            DateTime startOfWeek =
                                now.subtract(Duration(days: now.weekday - 1));
                            DateTime endOfWeek =
                                startOfWeek.add(Duration(days: 6));
                            _periodDetails =
                                "${DateFormat("dd MMM, yyyy").format(startOfWeek)} - ${DateFormat("dd MMM, yyyy").format(endOfWeek)}";
                            break;
                          case "monthly":
                            DateTime now = DateTime.now();
                            _periodDetails = DateFormat("MMM yyyy").format(now);
                            break;
                          case "yearly":
                            DateTime now = DateTime.now();
                            _periodDetails = DateFormat("yyyy").format(now);
                            break;
                        }
                      });
                    },
                  ),
                ),

                // Next button with animation (more compact)
                Container(
                  width: 40, // Fixed width
                  height: 40, // Fixed height
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withOpacity(0.9), // Dark background
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero, // Remove default padding
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white, // White icon
                      size: 18, // Slightly smaller
                    ),
                    onPressed: _next,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8), // Reduced from 16

            // Period details with enhanced styling (more compact)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_periodDetails),
                width: double.infinity, // Full width
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6), // Reduced vertical padding
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .primaryColor
                      .withOpacity(0.9), // Dark background
                  borderRadius: BorderRadius.circular(4), // Sharp edges
                ),
                child: Text(
                  _periodDetails,
                  textAlign: TextAlign.center, // Center the text
                  style: TextStyle(
                    color: Colors.white, // White text
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Reduced font size
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this helper method
  IconData _getPeriodIcon() {
    switch (_period) {
      case "daily":
        return Icons.today;
      case "weekly":
        return Icons.view_week;
      case "monthly":
        return Icons.calendar_month;
      case "yearly":
        return Icons.calendar_today;
      default:
        return Icons.calendar_today;
    }
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
        DateTime currentDate = DateFormat("MMM yyyy").parse(_periodDetails);
        DateTime previousMonth =
            DateTime(currentDate.year, currentDate.month - 1, 1);

        setState(() {
          _periodDetails = DateFormat("MMM yyyy").format(previousMonth);
        });
        break;

      case "yearly":
        DateTime currentDate = DateFormat("yyyy").parse(_periodDetails);
        DateTime previousYear = DateTime(currentDate.year - 1, 1, 1);

        setState(() {
          _periodDetails = DateFormat("yyyy").format(previousYear);
        });
        break;
    }
  }

  Future<void> _next() async {
    DateTime today = DateTime.now();

    switch (_period) {
      case "daily":
        DateTime currentDate = DateFormat("dd MMM, yyyy").parse(_periodDetails);

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
        String startOfWeek = _periodDetails.split('-')[0].trim();
        DateTime currentStartDate =
            DateFormat("dd MMM, yyyy").parse(startOfWeek);
        DateTime nextStartDate = currentStartDate.add(Duration(days: 7));

        // Don't go beyond current week
        if (nextStartDate
            .isAfter(today.subtract(Duration(days: today.weekday - 1)))) {
          return;
        }

        DateTime nextEndDate = nextStartDate.add(Duration(days: 6));

        setState(() {
          _periodDetails =
              "${DateFormat("dd MMM, yyyy").format(nextStartDate)} - ${DateFormat("dd MMM, yyyy").format(nextEndDate)}";
        });
        break;

      case "monthly":
        DateTime currentDate = DateFormat("MMM yyyy").parse(_periodDetails);

        // Don't go beyond current month
        if (currentDate.year == today.year &&
            currentDate.month == today.month) {
          return;
        }

        DateTime nextMonth =
            DateTime(currentDate.year, currentDate.month + 1, 1);

        setState(() {
          _periodDetails = DateFormat("MMM yyyy").format(nextMonth);
        });
        break;

      case "yearly":
        DateTime currentDate = DateFormat("yyyy").parse(_periodDetails);

        // Don't go beyond current year
        if (currentDate.year == today.year) {
          return;
        }

        DateTime nextYear = DateTime(currentDate.year + 1, 1, 1);

        setState(() {
          _periodDetails = DateFormat("yyyy").format(nextYear);
        });
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
