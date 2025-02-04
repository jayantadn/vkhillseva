import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/profiles.dart';
import 'package:vkhgaruda/widgets/loading_overlay.dart';
import 'package:vkhgaruda/common/theme.dart';
import 'package:table_calendar/table_calendar.dart';

class SangeetSeva extends StatefulWidget {
  final String title;
  final String? icon;

  const SangeetSeva({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _SangeetSevaState createState() => _SangeetSevaState();
}

class _SangeetSevaState extends State<SangeetSeva> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime? _selectedDay;

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createCalendarDay(
      {required DateTime day,
      bool? border,
      bool? fill,
      int? greenstars,
      int? redstars}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: (fill != null && fill == true)
                ? Colors.blue[50]
                : Colors.transparent,
            border: border == true ? Border.all(color: Colors.grey) : null,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("**"),
                  Text("**"),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _createCalendarView(BuildContext context) {
    DateTime now = DateTime.now();

    return TableCalendar(
      firstDay: DateTime(2024),
      lastDay: DateTime.now().add(Duration(days: 90)),
      focusedDay: DateTime.now(),
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay ?? DateTime.now(), day);
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _createCalendarDay(day: day);
        },
        todayBuilder: (context, day, focusedDay) {
          return _createCalendarDay(day: day, border: true);
        },
        selectedBuilder: (context, day, focusedDay) {
          return _createCalendarDay(
              day: day,
              border: now.day == day.day &&
                  now.month == day.month &&
                  now.year == day.year,
              fill: true);
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
        });
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
              actions: [
                IconButton(
                  icon: Icon(Icons.group),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Profiles(
                              title: 'Performer Profiles', icon: widget.icon)),
                    );
                  },
                )
              ],
            ),
            body: RefreshIndicator(
                onRefresh: refresh,
                child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(children: [
                          // leave some space at top
                          SizedBox(height: 10),

                          // your widgets here
                          _createCalendarView(context),

                          // leave some space at bottom
                          SizedBox(height: 100),
                        ])))),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon)
        ],
      ),
    );
  }
}
