import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

// ignore: library_private_types_in_public_api
GlobalKey<_CalendarState> calendarKey = GlobalKey<_CalendarState>();

class _CalendarState extends State<Calendar> {
  final Lock _lock = Lock();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // dispose all controllers

    super.dispose();
  }

  void refresh() async {
    // perform async work here

    // perform sync work here
    await _lock.synchronized(() async {
      setState(() {});
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
                  Text(
                    redstars != null ? greenstars.toString() : ' ',
                    style: TextStyle(color: Colors.red),
                  ),
                  Text(greenstars != null ? greenstars.toString() : ' ',
                      style: TextStyle(color: Colors.green)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    return TableCalendar(
      firstDay: DateTime(2024),
      lastDay: DateTime.now().add(Duration(days: 90)),
      focusedDay: DateTime.now(),
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
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
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
    );
  }
}
