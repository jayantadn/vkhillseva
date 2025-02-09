import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/common/const.dart';
import 'package:vkhgaruda/common/fb.dart';
import 'package:vkhgaruda/common/toaster.dart';
import 'package:vkhgaruda/sangeet_seva/profiles.dart';
import 'package:vkhgaruda/sangeet_seva/slot.dart';
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
  final List<Slot> _bookedSlots = [];
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
    _bookedSlots.clear();
    _avlSlots.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here
    await _fillAvailabilityIndicators();
    await _fillBookingLists(_selectedDate);

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
    _bookedSlots.clear();
    _avlSlots.clear();
    String dbDate = DateFormat("yyyy-MM-dd").format(date);
    List<dynamic> slotsRaw = await FB().getList(path: "Slots/$dbDate");

    // add the slots from database
    for (var slotRaw in slotsRaw) {
      Map<String, dynamic> slotMap = Map<String, dynamic>.from(slotRaw);
      Slot slot = Slot.fromJson(slotMap);

      if (slot.avl) {
        _avlSlots.add(slot);
      } else {
        _bookedSlots.add(slot);
      }
    }
    slotsRaw.clear();

    // add the weekend fixed slots
    int totalSlots = _avlSlots.length + _bookedSlots.length;
    for (int i = 2; i > totalSlots; i--) {
      // _avlSlots.add(Slot(name: "Slot$i", avl: true, from: ""))
    }
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
        // booked slots
        ...List.generate(_bookedSlots.length, (index) {
          Slot slot = _bookedSlots[index];
          return Card(
            color: Colors.red[50],
            child: ListTile(
              title: Text(slot.name),
              subtitle: Text('${slot.from} - ${slot.to}'),
            ),
          );
        }),

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

  Future<void> _addFreeSlot(
      String name, String startTime, String endTime) async {
    // validations
    if (startTime == "__:__" || endTime == "__:__") {
      Toaster().error("Please enter both start and end time");
      return;
    }

    // check if end time is greater than start time
    final DateFormat timeFormat = DateFormat('hh:mm a');
    try {
      final DateTime startDateTime = timeFormat.parse(startTime);
      final DateTime endDateTime = timeFormat.parse(endTime);
      if (endDateTime.isBefore(startDateTime)) {
        Toaster().error("End time should be greater than start time");
        return;
      }
    } catch (e) {
      // Handle parsing errors
      Toaster().error('Error parsing time: $e');
    }

    // add to database
    String dbDate = DateFormat("yyyy-MM-dd").format(_selectedDate);
    await FB().addKVToList(
        dbroot: Const().dbrootSangeetSeva,
        path: "Slots/$dbDate",
        key: name,
        value:
            Slot(name: name, avl: true, from: startTime, to: endTime).toJson());

    // refresh the availability indicators
    await _fillAvailabilityIndicators(date: _selectedDate);
  }

  Widget _createCalendar(BuildContext context) {
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

  Future<void> _showFreeSlotDialog(BuildContext context) async {
    // validation if selected date is in the past
    if (_selectedDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      Toaster().error("Date is in the past");
      return;
    }

    // get the total number of slots
    int totalSlots = await SlotUtils().getTotalSlotsCount(_selectedDate);

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

                      await _addFreeSlot(nameController.text,
                          startTimeController.text, endTimeController.text);

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
                          _createCalendar(context),
                          _createSlotDetails(context),

                          // leave some space at bottom
                          SizedBox(height: 100),
                        ])))),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                _showFreeSlotDialog(context);
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
