import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhsangeetseva/common/const.dart';
import 'package:vkhsangeetseva/common/fb.dart';
import 'package:vkhsangeetseva/widgets/loading_overlay.dart';
import 'package:vkhsangeetseva/common/theme.dart';
import 'package:table_calendar/table_calendar.dart';

class Register extends StatefulWidget {
  final String title;
  final String? icon;

  const Register({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // lists
  List<int> _bookedSlotsCnt = [];
  List<int> _avlSlotsCnt = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    // set _numBookings and _numAvlSots to 0
    _bookedSlotsCnt = List.filled(31, 0);
    _avlSlotsCnt = List.filled(31, 0);

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _bookedSlotsCnt.clear();
    _avlSlotsCnt.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here
    _fillAvailabilityIndicators();

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createAvlSlotsList(BuildContext context) {}

  Widget _createCalendar() {
    DateTime now = DateTime.now();

    return TableCalendar(
      firstDay: DateTime(2024),
      lastDay: DateTime.now().add(Duration(days: 90)),
      focusedDay: DateTime.now(),
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDate, day);
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
          _selectedDate = selectedDay;
        });
      },
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },
    );
  }

  Widget _createCalendarDay({
    required DateTime day,
    bool? border,
    bool? fill,
  }) {
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
                  for (int i = 0; i < _bookedSlotsCnt[day.day - 1]; i++)
                    Icon(
                      Icons.circle,
                      color: Colors.red,
                      size: 5,
                    ),
                  for (int i = 0; i < _avlSlotsCnt[day.day - 1]; i++)
                    Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 5,
                    )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fillAvailabilityIndicators({DateTime? date}) async {
    if (date == null) {
      // generate for whole month
      int startDay = DateTime.now().day - 1;
      for (int day = startDay; day < 31; day++) {
        DateTime givenDate =
            DateTime(_selectedDate.year, _selectedDate.month, day + 1);
        int booked = await _getBookedSlotsCount(date: givenDate);
        int total = await _getTotalSlotsCount(date: givenDate);

        setState(() {
          _bookedSlotsCnt[day] = booked;
          _avlSlotsCnt[day] = total - _bookedSlotsCnt[day];
        });
      }
    } else {
      // fill for a single day
      int booked = await _getBookedSlotsCount(date: date);
      int total = await _getTotalSlotsCount(date: date);

      setState(() {
        _bookedSlotsCnt[date.day - 1] = booked;
        _avlSlotsCnt[date.day - 1] = total - _bookedSlotsCnt[date.day - 1];
      });
    }
  }

  Future<int> _getTotalSlotsCount({DateTime? date}) async {
    date ??= _selectedDate;

    // get slots from database
    String dbDate = DateFormat("yyyy-MM-dd").format(date);
    List<dynamic> slotList =
        await FB().getList(dbroot: Const().dbroot, path: "Slots/$dbDate");

    // add slots for weekend
    bool isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return slotList.length + (isWeekend ? 2 : 0);
  }

  Future<int> _getBookedSlotsCount({DateTime? date}) async {
    date ??= _selectedDate;

    // TODO: implementation pending
    return 0;
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
            body: RefreshIndicator(
                onRefresh: refresh,
                child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // leave some space at top
                              SizedBox(height: 10),

                              _createCalendar(),
                              _createAvlSlotsList(context),

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
