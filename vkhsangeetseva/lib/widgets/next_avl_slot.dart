import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/common/const.dart';
import 'package:vkhpackages/common/datatypes.dart';
import 'package:vkhpackages/common/fb.dart';
import 'package:vkhpackages/common/utils.dart';
import 'package:vkhpackages/vkhpackages.dart';

class NextAvlSlot extends StatefulWidget {
  const NextAvlSlot({super.key});

  @override
  State<NextAvlSlot> createState() => _NextAvlSlotState();
}

// hint: instantiate the class with a global key
// ignore: library_private_types_in_public_api
GlobalKey<_NextAvlSlotState> nextavlslotKey = GlobalKey<_NextAvlSlotState>();

class _NextAvlSlotState extends State<NextAvlSlot> {
  final Lock _lock = Lock();
  DateTime? _nextAvailableDate; // Class member to store the last checked date
  Slot? _nextAvailableSlot; // Class member to store the next available slot

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

  Future<void> refresh() async {
    // perform async work here

    await _lock.synchronized(() async {
      // perform sync work here
      setState(() {});
    });
  }

  Future<bool> _isSlotAvailable(DateTime date, Slot slot) async {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    String dbpath = "${Const().dbrootSangeetSeva}/Slots/$dateStr";

    bool exists = await FB().pathExists(dbpath);
    if (!exists) {
      return true;
    }

    var slotsRaw = await FB().getValue(path: dbpath);
    Map<String, dynamic> slots = Map<String, dynamic>.from(slotsRaw);

    for (var slotRaw in slots.entries) {
      Slot slotObj = Utils().convertRawToDatatype(slotRaw.value, Slot.fromJson);
      if (slotObj.from == slot.from && slotObj.to == slot.to) {
        return slotObj.avl;
      }
    }

    return true;
  }

  Future<Map<String, dynamic>> getNextAvailableSlot_() async {
    // fetch all the created slots
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Map<String, dynamic> kvs = await FB().getValuesByDateRange(
        path: "${Const().dbrootSangeetSeva}/Slots", startDate: today);
    List<String> slotDates = kvs.keys.toList();

    DateTime currentDate = _nextAvailableDate?.add(Duration(days: 1)) ??
        DateTime
            .now(); // Start from the day after the last checked date or today
    String? lastCheckedSlot; // Track the last checked slot name

    while (true) {
      String dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

      // Check if the date exists in the slotDates list
      if (slotDates.contains(dateStr)) {
        var slotsRaw = await FB()
            .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dateStr");
        Map<String, dynamic> slots = Map<String, dynamic>.from(slotsRaw);

        // Iterate through slots and return the next available one
        bool foundLastSlot = lastCheckedSlot ==
            null; // Start from the first slot if no last slot
        for (var entry in slots.entries) {
          if (!foundLastSlot) {
            // Skip slots until the last checked slot is found
            if (entry.key == lastCheckedSlot) {
              foundLastSlot = true;
            }
            continue;
          }

          if (entry.value['avl'] == true) {
            _nextAvailableDate = currentDate; // Update last checked date
            lastCheckedSlot = entry.key; // Update last checked slot
            return {
              'date': dateStr,
              'slot': {
                'name': entry.key,
                'from': entry.value['from'],
                'to': entry.value['to']
              }
            };
          }
        }
        lastCheckedSlot =
            null; // Reset last checked slot when all slots are exhausted
      }

      // Check for weekend slots if the current date is a weekend
      if (currentDate.weekday == DateTime.saturday ||
          currentDate.weekday == DateTime.sunday) {
        bool foundLastSlot = lastCheckedSlot ==
            null; // Start from the first slot if no last slot
        for (var slot in Const().weekendSangeetSevaSlots) {
          if (!foundLastSlot) {
            // Skip slots until the last checked slot is found
            if (slot.name == lastCheckedSlot) {
              foundLastSlot = true;
            }
            continue;
          }

          if (slot.avl) {
            _nextAvailableDate = currentDate; // Update last checked date
            lastCheckedSlot = slot.name; // Update last checked slot
            return {
              'date': dateStr,
              'slot': {'name': slot.name, 'from': slot.from, 'to': slot.to}
            };
          }
        }
        lastCheckedSlot =
            null; // Reset last checked slot when all slots are exhausted
      }

      // Move to the next day
      currentDate = currentDate.add(Duration(days: 1));
    }
  }

  Future<void> _fetchNextAvailableSlot() async {
    // set the starting search date and the next weekend date
    if (_nextAvailableDate == null) {
      _nextAvailableDate = DateTime.now();
    } else {
      List<Slot> slots = [];

      // check if any more slots available for the current date
      // if yes, retain the date
      String dbdate = DateFormat('yyyy-MM-dd').format(_nextAvailableDate!);
      var slotsRaw = await FB()
          .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dbdate");
      if (slotsRaw != null) {
        Map<String, dynamic> slotsRawMap = Map<String, dynamic>.from(slotsRaw);
        for (var entry in slotsRawMap.entries) {
          Slot slot = Utils().convertRawToDatatype(entry.value, Slot.fromJson);
          slots.add(slot);
        }
      }

      // is the available date a weekend date?
      // if yes, check if any slots available after this
      if (_nextAvailableDate!.weekday == DateTime.saturday ||
          _nextAvailableDate!.weekday == DateTime.sunday) {
        for (var slotw in Const().weekendSangeetSevaSlots) {
          bool found = false;
          for (var slot in slots) {
            if (slotw.from == slot.from && slotw.to == slot.to) {
              found = true;
              break;
            }
          }

          if (!found) {
            slots.add(slotw);
          }
        }
      }

      // filter for available slots
      slots = slots.where((slot) => slot.avl == true).toList();

      // sort the slots by time
      slots.sort((a, b) {
        DateTime timeA = Utils().convertStringToTime(
            _nextAvailableDate!, a.from); // Convert to DateTime
        DateTime timeB = Utils().convertStringToTime(
            _nextAvailableDate!, b.from); // Convert to DateTime
        return timeA.compareTo(timeB); // Compare the times
      });

      // set the starting search date
      if (_nextAvailableSlot == null) {
        if (slots.isEmpty) {
          _nextAvailableDate = _nextAvailableDate!.add(Duration(days: 1));
        } else {
          _nextAvailableSlot = slots[0];
          return;
        }
      } else {
        if (slots.isEmpty) {
          _nextAvailableDate = _nextAvailableDate!.add(Duration(days: 1));
        } else {
          for (Slot slot in slots) {
            DateTime currentSlot = Utils().convertStringToTime(
                _nextAvailableDate!, _nextAvailableSlot!.from);
            DateTime newSlot =
                Utils().convertStringToTime(_nextAvailableDate!, slot.from);

            if (newSlot.isAfter(currentSlot)) {
              _nextAvailableSlot = slot;
              return;
            }
          }

          // no available slots found, so move to the next date
          _nextAvailableDate = _nextAvailableDate!.add(Duration(days: 1));
        }
      }
    }

    // weekend date after the next available date
    DateTime nextWeekendDate = DateTime(
      _nextAvailableDate!.year,
      _nextAvailableDate!.month,
      _nextAvailableDate!.day,
    );
    while (nextWeekendDate.weekday != DateTime.saturday &&
        nextWeekendDate.weekday != DateTime.sunday) {
      nextWeekendDate = nextWeekendDate.add(Duration(days: 1));
    }

    // fetch all the created slots
    String today = DateFormat('yyyy-MM-dd').format(_nextAvailableDate!);
    Map<String, dynamic> kvs = await FB().getValuesByDateRange(
        path: "${Const().dbrootSangeetSeva}/Slots", startDate: today);
    List<String> slotDates = kvs.keys.toList();

    // find the next available slots from the created slots
    bool found = false;
    for (String dateStr in slotDates) {
      DateTime date = DateFormat('yyyy-MM-dd').parse(dateStr);
      if (date.isAfter(_nextAvailableDate!)) {
        var slotsRaw = await FB()
            .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dateStr");
        Map<String, dynamic> slots = Map<String, dynamic>.from(slotsRaw);

        for (var entry in slots.entries) {
          Slot slot = Utils().convertRawToDatatype(entry.value, Slot.fromJson);

          if (_nextAvailableSlot == null && slot.avl == true) {
            _nextAvailableDate = date;
            _nextAvailableSlot = slot;
            found = true;
            break;
          } else if (_nextAvailableSlot != null) {
            if (slot.avl == true) {
              if (Utils().convertStringToTime(date, slot.from).isAfter(Utils()
                  .convertStringToTime(
                      _nextAvailableDate!, _nextAvailableSlot!.from))) {
                _nextAvailableDate = date;
                _nextAvailableSlot = slot;
                found = true;
                break;
              }
            }
          }
        }
      }
      if (found) {
        break;
      }
    }

    // arbitrate against the weekend slots
    bool foundWeekend = false;
    for (int i = 0; i < 10; i++) {
      for (var slot in Const().weekendSangeetSevaSlots) {
        bool avl = await _isSlotAvailable(nextWeekendDate, slot);
        if (avl) {
          if (_nextAvailableSlot == null) {
            _nextAvailableDate = nextWeekendDate;
            _nextAvailableSlot = slot;
            foundWeekend = true;
            break;
          } else if (_nextAvailableDate!.isAfter(nextWeekendDate)) {
            _nextAvailableDate = nextWeekendDate;
            _nextAvailableSlot = slot;
            foundWeekend = true;
            break;
          } else {
            DateTime nextslot = Utils().convertStringToTime(
                _nextAvailableDate!, _nextAvailableSlot!.from);
            DateTime nextweekendslot =
                Utils().convertStringToTime(nextWeekendDate, slot.from);
            if (nextslot.isAfter(nextweekendslot)) {
              _nextAvailableDate = nextWeekendDate;
              _nextAvailableSlot = slot;
              foundWeekend = true;
              break;
            }
          }
        }
      }

      if (foundWeekend) {
        break;
      }
      // go to next weekend
      do {
        nextWeekendDate = nextWeekendDate.add(Duration(days: 1));
      } while (nextWeekendDate.weekday != DateTime.saturday &&
          nextWeekendDate.weekday != DateTime.sunday);
    }

    // if no slot is found, set the next available date to null
    if (_nextAvailableSlot == null) {
      _nextAvailableDate = null;
      _nextAvailableSlot = null;
      Toaster().error("Unable to find available slot.");
    }
  }

  Future<void> _fetchNextAvailableSlot_() async {
    // fetch all the created slots
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Map<String, dynamic> kvs = await FB().getValuesByDateRange(
        path: "${Const().dbrootSangeetSeva}/Slots", startDate: today);
    List<String> slotDates = kvs.keys.toList();

    // next weekend date
    DateTime nextWeekendDate = DateTime.now();
    while (nextWeekendDate.weekday != DateTime.saturday &&
        nextWeekendDate.weekday != DateTime.sunday) {
      nextWeekendDate = nextWeekendDate.add(Duration(days: 1));
    }

    // set the starting search date
    if (slotDates.isNotEmpty) {
      DateTime firstDate = DateFormat('yyyy-MM-dd').parse(slotDates[0]);
      if (firstDate.isAfter(nextWeekendDate)) {
        _nextAvailableDate = nextWeekendDate;
      } else {
        _nextAvailableDate = firstDate;
      }
    }

    // find the next available slots from the created slots
    bool found = false;
    for (String dateStr in slotDates) {
      DateTime date = DateFormat('yyyy-MM-dd').parse(dateStr);
      if (date.isAfter(_nextAvailableDate!)) {
        var slotsRaw = await FB()
            .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dateStr");
        Map<String, dynamic> slots = Map<String, dynamic>.from(slotsRaw);

        for (var entry in slots.entries) {
          Slot slot = Utils().convertRawToDatatype(entry.value, Slot.fromJson);

          if (_nextAvailableSlot == null && slot.avl == true) {
            _nextAvailableDate = date;
            _nextAvailableSlot = slot;
            found = true;
            break;
          } else if (_nextAvailableSlot != null) {
            if (slot.avl == true) {
              if (Utils().convertStringToTime(date, slot.from).isAfter(Utils()
                  .convertStringToTime(
                      _nextAvailableDate!, _nextAvailableSlot!.from))) {
                _nextAvailableDate = date;
                _nextAvailableSlot = slot;
                found = true;
                break;
              }
            }
          }
        }
      }
      if (found) {
        break;
      }
    }

    // arbitrate against the weekend slots
    bool foundWeekend = false;
    for (int i = 0; i < 10; i++) {
      if (_nextAvailableSlot == null ||
          _nextAvailableDate!.isAfter(nextWeekendDate)) {
        for (var slot in Const().weekendSangeetSevaSlots) {
          if (await _isSlotAvailable(nextWeekendDate, slot)) {
            if (_nextAvailableSlot == null) {
              _nextAvailableDate = nextWeekendDate;
              _nextAvailableSlot = slot;
              foundWeekend = true;
              break;
            } else if (Utils()
                .convertStringToTime(
                    _nextAvailableDate!, _nextAvailableSlot!.from)
                .isAfter(
                    Utils().convertStringToTime(nextWeekendDate, slot.from))) {
              _nextAvailableDate = nextWeekendDate;
              _nextAvailableSlot = slot;
              foundWeekend = true;
              break;
            }
          }
        }
      } else {
        break;
      }
      if (foundWeekend) {
        break;
      }
      // go to next weekend
      do {
        nextWeekendDate = nextWeekendDate.add(Duration(days: 1));
      } while (nextWeekendDate.weekday != DateTime.saturday &&
          nextWeekendDate.weekday != DateTime.sunday);
    }

    // if no slot is found, set the next available date to null
    if (_nextAvailableSlot == null) {
      _nextAvailableDate = null;
      _nextAvailableSlot = null;
      Toaster().error("Unable to find available slot.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // previous available slot
        IconButton(
          icon: Transform.rotate(
            angle: 3.14, // Rotate 180 degrees to point left
            child: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          onPressed: () {},
        ),

        // slot details
        Column(
          children: [
            Text(
              "26 Mar, 2024",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("10:00 AM - 01:00 PM"),
          ],
        ),

        // next available slot
        IconButton(
          icon: Transform.rotate(
            angle: 0, // Rotate 0 degrees to point right
            child: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          onPressed: () async {
            await _fetchNextAvailableSlot();
            if (_nextAvailableSlot != null) {
              print(
                  "Next available slot: ${_nextAvailableDate} ${_nextAvailableSlot!.from} - ${_nextAvailableSlot!.to}");
            }
          },
        ),
      ],
    );
  }
}
