import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhsangeetseva/common/const.dart';
import 'package:vkhsangeetseva/common/datatypes.dart';
import 'package:vkhsangeetseva/common/fb.dart';
import 'package:vkhsangeetseva/widgets/calendar.dart';
import 'package:vkhsangeetseva/widgets/loading_overlay.dart';
import 'package:vkhsangeetseva/common/theme.dart';
import 'package:table_calendar/table_calendar.dart';

class Registration extends StatefulWidget {
  final String title;
  final String? icon;

  const Registration({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // lists
  List<int> _bookedSlotsCnt = [];
  List<int> _avlSlotsCnt = [];
  final List<Slot> _avlSlots = [];

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
    _avlSlots.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here
    await _fillBookingLists(_selectedDate);

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addWeekendFreeSlots(DateTime date) async {
    if (date.weekday == 6 || date.weekday == 7) {
      // fetch the slots for the date
      String dbDate = DateFormat("yyyy-MM-dd").format(date);
      List slotsRaw = await FB().getList(path: "Slots/$dbDate");
      List<Slot> bookedSlots = [];
      for (var slotRaw in slotsRaw) {
        Map<String, dynamic> slotMap = Map<String, dynamic>.from(slotRaw);
        Slot slot = Slot.fromJson(slotMap);
        bookedSlots.add(slot);
      }

      // add the weekend slots if not present
      for (Slot slot in Const().weekendSangeetSevaSlots) {
        if (!bookedSlots.contains(slot) && !_avlSlots.contains(slot)) {
          _avlSlots.add(slot);
        }
      }
    }
  }

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

  Widget _createSlotDetails(BuildContext context) {
    return Column(
      children: [
        // available slots
        ...List.generate(_avlSlots.length, (index) {
          Slot slot = _avlSlots[index];
          return Card(
            color: Colors.green[50],
            child: ListTile(
              title: Text(slot.name),
              subtitle: Text('${slot.from} - ${slot.to}'),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _fillAvailabilityIndicators({DateTime? date}) async {
    if (date == null) {
      // generate for whole month
      int startDay = DateTime.now().day - 1;
      for (int day = startDay; day < 31; day++) {
        DateTime givenDate =
            DateTime(_selectedDate.year, _selectedDate.month, day + 1);
        int booked = await SlotUtils().getBookedSlotsCount(givenDate);
        int total = await SlotUtils().getTotalSlotsCount(givenDate);

        setState(() {
          _bookedSlotsCnt[day] = booked;
          _avlSlotsCnt[day] = total - _bookedSlotsCnt[day];
        });
      }
    } else {
      // fill for a single day
      int booked = await SlotUtils().getBookedSlotsCount(date);
      int total = await SlotUtils().getTotalSlotsCount(date);

      setState(() {
        _bookedSlotsCnt[date.day - 1] = booked;
        _avlSlotsCnt[date.day - 1] = total - _bookedSlotsCnt[date.day - 1];
      });
    }
  }

  Future<void> _fillBookingLists(DateTime date) async {
    // retrieve slots from db
    _avlSlots.clear();
    String dbDate = DateFormat("yyyy-MM-dd").format(date);
    List<dynamic> slotsRaw =
        await FB().getList(dbroot: Const().dbroot, path: "Slots/$dbDate");

    // add the slots from database
    for (var slotRaw in slotsRaw) {
      Map<String, dynamic> slotMap = Map<String, dynamic>.from(slotRaw);
      Slot slot = Slot.fromJson(slotMap);

      if (slot.avl) {
        _avlSlots.add(slot);
      }
    }
    slotsRaw.clear();

    // add the weekend fixed slots
    await _addWeekendFreeSlots(date);
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

                              Calendar(
                                  key: calendarKey,
                                  onDaySelected: (date) async {
                                    await _fillBookingLists(date);

                                    setState(() {
                                      _selectedDate = date;
                                    });
                                  }),
                              _createSlotDetails(context),

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
