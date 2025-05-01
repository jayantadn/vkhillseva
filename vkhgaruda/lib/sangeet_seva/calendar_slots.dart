import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/pending_requests.dart';
import 'package:vkhgaruda/sangeet_seva/profiles.dart';
import 'package:vkhgaruda/sangeet_seva/request_details.dart';
import 'package:vkhpackages/vkhpackages.dart';

class CalendarSlots extends StatefulWidget {
  final String title;
  final String? icon;

  const CalendarSlots({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarSlotsState createState() => _CalendarSlotsState();
}

class _CalendarSlotsState extends State<CalendarSlots> {
  final GlobalKey<CalendarState> _calendarKey = GlobalKey<CalendarState>();

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
    await _fillBookingLists(_selectedDate);

    // subscribe to notifications
    try {
      await Notifications().setupFirebaseMessaging();
      FirebaseMessaging.instance.subscribeToTopic("SSAdmin");
    } catch (e) {
      // nothing to do
    }

    // refresh all child widgets
    _calendarKey.currentState!.refresh();

    // perform sync operations here
    await _lock.synchronized(() async {});

    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _addFreeSlot(
    String name,
    String startTime,
    String endTime,
  ) async {
    // validations
    if (startTime == "__:__" || endTime == "__:__") {
      Toaster().error("Please enter both start and end time");
      return false;
    }

    // check if end time is greater than start time
    try {
      final DateTime startDateTime =
          Utils().convertStringToTime(_selectedDate, startTime);
      final DateTime endDateTime =
          Utils().convertStringToTime(_selectedDate, endTime);
      if (endDateTime.isBefore(startDateTime)) {
        Toaster().error("End time should be greater than start time");
        return false;
      }
    } catch (e) {
      // Handle parsing errors
      Toaster().error('Error parsing time: $e');
    }

    // add to database
    String dbDate = DateFormat("yyyy-MM-dd").format(_selectedDate);
    await FB().addKVToList(
      path: "${Const().dbrootSangeetSeva}/Slots/$dbDate",
      key: name,
      value: Slot(
              name: name,
              avl: true,
              from: Utils().convertTimeStringTo12HrFormat(startTime),
              to: Utils().convertTimeStringTo12HrFormat(endTime))
          .toJson(),
    );

    // refresh the availability indicators
    _calendarKey.currentState!.fillAvailabilityIndicators(date: _selectedDate);
    await _fillBookingLists(_selectedDate);

    setState(() {});

    return true;
  }

  Future<void> _addWeekendFreeSlots(DateTime date) async {
    if (date.weekday == 6 || date.weekday == 7) {
      // fetch the slots for the date
      String dbDate = DateFormat("yyyy-MM-dd").format(date);
      List slotsRaw = await FB()
          .getList(path: "${Const().dbrootSangeetSeva}/Slots/$dbDate");
      List<Slot> bookedSlots = [];
      for (var slotRaw in slotsRaw) {
        Map<String, dynamic> slotMap = Map<String, dynamic>.from(slotRaw);
        Slot slot = Slot.fromJson(slotMap);
        bookedSlots.add(slot);
      }

      // add the weekend slots if not present
      for (Slot slot in SSConst().weekendSangeetSevaSlots) {
        _avlSlots.add(slot);
        for (Slot bookedSlot in bookedSlots) {
          if (slot.from == bookedSlot.from && slot.to == bookedSlot.to) {
            _avlSlots.remove(slot);
            break;
          }
        }
      }
    }
  }

  Future<void> _fillBookingLists(DateTime date) async {
    // retrieve slots from db
    _bookedSlots.clear();
    _avlSlots.clear();
    String dbDate = DateFormat("yyyy-MM-dd").format(date);
    List<dynamic> slotsRaw = await FB().getList(
      path: "${Const().dbrootSangeetSeva}/Slots/$dbDate",
    );

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
    await _addWeekendFreeSlots(date);
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
              onTap: () async {
                // look in booked slots and determine the Event
                EventRecord? bookedEvent;
                String dbdate = DateFormat("yyyy-MM-dd").format(_selectedDate);
                String dbpath =
                    "${Const().dbrootSangeetSeva}/BookedEvents/$dbdate";
                List eventLinksRaw = await FB().getList(path: dbpath);
                for (var eventLinkRaw in eventLinksRaw) {
                  Map<String, dynamic> eventLink =
                      Map<String, dynamic>.from(eventLinkRaw);
                  String path = eventLink['path'];

                  List eventsRaw = await FB().getList(path: path);
                  var eventRaw = eventsRaw[index];
                  EventRecord event = Utils()
                      .convertRawToDatatype(eventRaw, EventRecord.fromJson);

                  if (event.slot.from == slot.from &&
                      event.slot.to == slot.to) {
                    bookedEvent = event;
                    break;
                  }
                }

                // open the event details page
                if (bookedEvent != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestDetails(
                        title: 'Event details',
                        eventRecord: bookedEvent!,
                        callbackDelete: (action) {
                          // placeholder for rejecting an approved request
                        },
                      ),
                    ),
                  );
                } else {
                  Toaster().error("Event not found");
                }
              },
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
        TextEditingController nameController = TextEditingController(
          text: "Slot${totalSlots + 1}",
        );
        TextEditingController startTimeController = TextEditingController(
          text: "__:__",
        );
        TextEditingController endTimeController = TextEditingController(
          text: "__:__",
        );

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
                                startTimeController.text = picked.format(
                                  context,
                                );
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
                        SizedBox(width: 50, child: Text("To:")),
                        Text(endTimeController.text),
                        IconButton(
                          onPressed: () async {
                            TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                endTimeController.text = picked.format(context);
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
                    bool success = await _addFreeSlot(
                      nameController.text,
                      startTimeController.text,
                      endTimeController.text,
                    );

                    if (success) {
                      Navigator.of(context).pop();
                      nameController.dispose();
                      startTimeController.dispose();
                      endTimeController.dispose();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [],
          ),
          body: RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // leave some space at top
                    SizedBox(height: 10),

                    // calendar
                    Calendar(
                      key: _calendarKey,
                      onDaySelected: (DateTime date) async {
                        await _fillBookingLists(date);

                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),

                    _createSlotDetails(context),

                    // leave some space at bottom
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              _showFreeSlotDialog(context);
            },
            tooltip: 'Add',
            child: Icon(Icons.add),
          ),
        ),

        // circular progress indicator
        if (_isLoading) LoadingOverlay(image: widget.icon),
      ],
    );
  }
}
