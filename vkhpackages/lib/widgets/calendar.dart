import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Calendar extends StatefulWidget {
  final void Function(DateTime) onDaySelected;

  const Calendar({super.key, required this.onDaySelected});

  @override
  State<Calendar> createState() => _CalendarState();
}

// ignore: library_private_types_in_public_api
GlobalKey<_CalendarState> calendarKey = GlobalKey<_CalendarState>();

class _CalendarState extends State<Calendar> {
  final Lock _lock = Lock();
  DateTime _selectedDate = DateTime.now();

  // lists
  List<int> _bookedSlotsCnt = [];
  List<int> _avlSlotsCnt = [];

  @override
  void initState() {
    super.initState();

    // set _numBookings and _numAvlSots to 0
    _bookedSlotsCnt = List.filled(31, 0);
    _avlSlotsCnt = List.filled(31, 0);

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _bookedSlotsCnt = [];
    _avlSlotsCnt = [];

    // dispose all controllers

    super.dispose();
  }

  void refresh() async {
    // perform async work here
    await fillAvailabilityIndicators();

    // perform sync work here
    await _lock.synchronized(() async {
      setState(() {});
    });
  }

  Widget _createCalendarDay({required DateTime day, bool? border, bool? fill}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color:
                (fill != null && fill == true)
                    ? Colors.grey[300]
                    : Colors.transparent,
            border: border == true ? Border.all(color: Colors.grey) : null,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${day.day}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _bookedSlotsCnt[day.day - 1]; i++)
                    Icon(Icons.circle, color: Colors.red, size: 5),
                  for (int i = 0; i < _avlSlotsCnt[day.day - 1]; i++)
                    Icon(Icons.circle, color: Colors.green, size: 5),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fillAvailabilityIndicators({
    DateTime? date,
    DateTime? focusedDay,
  }) async {
    if (date == null) {
      // generate for whole month
      focusedDay ??= DateTime.now();
      int startDay = focusedDay.day - 1;
      for (int day = startDay; day < 31; day++) {
        DateTime givenDate = DateTime(
          focusedDay.year,
          focusedDay.month,
          day + 1,
        );
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

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(Duration(days: 90)),
      focusedDay: _selectedDate,
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
            border:
                now.day == day.day &&
                now.month == day.month &&
                now.year == day.year,
            fill: true,
          );
        },
      ),
      onDaySelected: (selectedDay, focusedDay) async {
        widget.onDaySelected(selectedDay);

        setState(() {
          _selectedDate = selectedDay;
        });
      },
      onPageChanged: (focusedDay) async {
        setState(() {
          _selectedDate = focusedDay;
          _avlSlotsCnt = List.filled(31, 0);
          _bookedSlotsCnt = List.filled(31, 0);
        });

        await fillAvailabilityIndicators(focusedDay: focusedDay);
      },
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
    );
  }
}

class SlotUtils {
  static final SlotUtils _instance = SlotUtils._internal();

  factory SlotUtils() {
    return _instance;
  }

  SlotUtils._internal() {
    // init
  }

  Future<int> getTotalSlotsCount(DateTime date) async {
    // get slots from database
    String dbDate = DateFormat("yyyy-MM-dd").format(date);
    List<dynamic> slotListRaw = await FB().getList(
      path: "${Const().dbrootSangeetSeva}/Slots/$dbDate",
    );

    int cnt = slotListRaw.length;
    if (Utils().isDateWeekend(date)) {
      for (Slot slotw in Const().weekendSangeetSevaSlots) {
        cnt++;
        for (var slotRaw in slotListRaw) {
          Slot slot = Utils().convertRawToDatatype(slotRaw, Slot.fromJson);
          if (slot.from == slotw.from && slot.to == slotw.to) {
            cnt--;
          }
        }
      }
    }

    return cnt;
  }

  Future<int> getBookedSlotsCount(DateTime date) async {
    String dbDate = DateFormat("yyyy-MM-dd").format(date);
    List<dynamic> slotList = await FB().getList(
      path: "${Const().dbrootSangeetSeva}/Slots/$dbDate",
    );

    int cnt = 0;
    for (var slotRaw in slotList) {
      Slot slot = Utils().convertRawToDatatype(slotRaw, Slot.fromJson);
      if (slot.avl == false) {
        cnt++;
      }
    }

    return cnt;
  }
}
