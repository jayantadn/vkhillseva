import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/common/const.dart';
import 'package:vkhgaruda/common/fb.dart';
import 'package:vkhgaruda/common/toaster.dart';
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
    await _fillAvailabilityIndicators();

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
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
    List<dynamic> slotList = await FB()
        .getList(dbroot: Const().dbrootSangeetSeva, path: "Slots/$dbDate");

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

  Widget _createCalendar() {
    DateTime now = DateTime.now();

    return TableCalendar(
      firstDay: DateTime.now(),
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

  Future<void> _addFreeSlot(BuildContext context) async {
    // validation if selected date is in the past
    if (_selectedDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      Toaster().error("Date is in the past");
      return;
    }

    // get the total number of slots
    int totalSlots = await _getTotalSlotsCount();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          TextEditingController nameController =
              TextEditingController(text: "Slot${totalSlots + 1}");
          TextEditingController startTimeController =
              TextEditingController(text: "__:__");
          TextEditingController endTimeController =
              TextEditingController(text: "__:__");

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Add a free slot'),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      // slot name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(hintText: "Slot name"),
                      ),

                      // start time
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: 50, child: Text("From:")),
                          Text(startTimeController.text),
                          IconButton(
                            onPressed: () async {
                              TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  startTimeController.text =
                                      picked.format(context);
                                });
                              }
                            },
                            icon: Icon(Icons.access_time),
                          ),
                        ],
                      ),

                      // end time
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text("To:"),
                          ),
                          Text(endTimeController.text),
                          IconButton(
                            onPressed: () async {
                              TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  endTimeController.text =
                                      picked.format(context);
                                });
                              }
                            },
                            icon: Icon(Icons.access_time),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // buttons
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Add'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      String dbDate =
                          DateFormat("yyyy-MM-dd").format(_selectedDate);
                      await FB().addKVToList(
                          dbroot: Const().dbrootSangeetSeva,
                          path: "Slots/$dbDate",
                          key: nameController.text,
                          value: "");

                      // refresh the availability indicators
                      await _fillAvailabilityIndicators(date: _selectedDate);

                      // clean up
                      nameController.dispose();
                      startTimeController.dispose();
                      endTimeController.dispose();
                    },
                  ),
                ],
              );
            },
          );
        });
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
                          _createCalendar(),

                          // leave some space at bottom
                          SizedBox(height: 100),
                        ])))),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                _addFreeSlot(context);
              },
              tooltip: 'Add',
              child: Icon(Icons.add),
            ),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon)
        ],
      ),
    );
  }
}
