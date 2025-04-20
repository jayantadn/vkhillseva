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
  int _pendingRequests = 0;
  DateTime _lastCallbackInvoked = DateTime.now();

  // lists
  List<int> _bookedSlotsCnt = [];
  List<int> _avlSlotsCnt = [];
  final List<Slot> _bookedSlots = [];
  final List<Slot> _avlSlots = [];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    // set _numBookings and _numAvlSots to 0
    _bookedSlotsCnt = List.filled(31, 0);
    _avlSlotsCnt = List.filled(31, 0);

// listed to database events
    FB().listenForChange(
        "${Const().dbrootSangeetSeva}/PendingRequests",
        FBCallbacks(
          // add
          add: (data) {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();
            }

            // process the received data
            _incrementPendingRequests();
          },

          // edit
          edit: () {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              refresh();
            }
          },

          // delete
          delete: (data) async {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              // process the received data
              _decrementPendingRequests();

              List eventsRaw = await FB().getList(path: data['path']);
              var eventRaw = eventsRaw[data['index']];
              EventRecord event =
                  Utils().convertRawToDatatype(eventRaw, EventRecord.fromJson);
              calendarKey.currentState!
                  .fillAvailabilityIndicators(date: event.date);
            }
          },

          // get listeners
          getListeners: (listeners) {
            _listeners = listeners;
          },
        ));

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
    for (var element in _listeners) {
      element.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here
    await _fillBookingLists(_selectedDate);
    _pendingRequests = await _getPendingRequestsCount();

    // subscribe to notifications
    try {
      await Notifications().setupFirebaseMessaging();
      FirebaseMessaging.instance.subscribeToTopic("SSAdmin");
    } catch (e) {
      // nothing to do
    }

    // refresh all child widgets
    calendarKey.currentState!.refresh();

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
          Utils().getTimeFromString(_selectedDate, startTime);
      final DateTime endDateTime =
          Utils().getTimeFromString(_selectedDate, endTime);
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
    calendarKey.currentState!.fillAvailabilityIndicators(date: _selectedDate);
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
      for (Slot slot in Const().weekendSangeetSevaSlots) {
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

  void _decrementPendingRequests() {
    setState(() {
      _pendingRequests--;
    });
  }

  void _incrementPendingRequests() {
    setState(() {
      _pendingRequests++;
    });
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
                  int index = eventLink['index'];

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
                        callback: (action) {
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

  Future<int> _getPendingRequestsCount() async {
    int pendingRequests = 0;

    // get the list of pending requests
    List<dynamic> pendingRequestsRaw = await FB()
        .getList(path: "${Const().dbrootSangeetSeva}/PendingRequests");
    for (var pendingRequestLinkRaw in pendingRequestsRaw) {
      Map<String, dynamic> pendingRequestLink =
          Map<String, dynamic>.from(pendingRequestLinkRaw);
      String path = pendingRequestLink['path'];
      int index = pendingRequestLink['index'];

      List pendingRequestsPerUserRaw = await FB().getList(path: path);
      var pendingRequestPerUserRaw = pendingRequestsPerUserRaw[index];
      EventRecord pendingRequest = Utils()
          .convertRawToDatatype(pendingRequestPerUserRaw, EventRecord.fromJson);

      // discard if pending request is in the past
      if (pendingRequest.date.isBefore(DateTime.now())) {
        continue;
      }

      pendingRequests++;
    }

    return pendingRequests;
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
    return Theme(
      data: themeDefault,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                // pending users
                Stack(children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PendingRequests(
                            title: 'Pending requests',
                            icon: widget.icon,
                          ),
                        ),
                      );
                    },
                  ),
                  if (_pendingRequests > 0)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PendingRequests(
                                title: 'Pending requests',
                                icon: widget.icon,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.only(left: 4, right: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 10,
                            minHeight: 10,
                          ),
                          child: Text(
                            '$_pendingRequests',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                ]),

                // registered users
                IconButton(
                  icon: Icon(Icons.group),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profiles(
                          title: 'Performer Profiles',
                          icon: widget.icon,
                        ),
                      ),
                    );
                  },
                ),
              ],
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
                        key: calendarKey,
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
      ),
    );
  }
}
