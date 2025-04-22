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
  List<String> _slotDates = []; // Class member to store slot dates
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
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Map<String, dynamic> kvs = await FB().getValuesByDateRange(
        path: "${Const().dbrootSangeetSeva}/Slots", startDate: today);
    _slotDates = kvs.keys.toList();
    await fetchNextAvailableSlot();
    print("$_nextAvailableDate ${_nextAvailableSlot!.name}");
    print("****************");
    await fetchNextAvailableSlot();
    print("$_nextAvailableDate ${_nextAvailableSlot!.name}");

    await _lock.synchronized(() async {
      // perform sync work here
      setState(() {});
    });
  }

  Future<bool> _isSlotAvailable(DateTime date, Slot slot) async {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    var slotsRaw = await FB()
        .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dateStr");
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
    DateTime currentDate = _nextAvailableDate?.add(Duration(days: 1)) ??
        DateTime
            .now(); // Start from the day after the last checked date or today
    String? lastCheckedSlot; // Track the last checked slot name

    while (true) {
      String dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

      // Check if the date exists in the _slotDates list
      if (_slotDates.contains(dateStr)) {
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

  Future<void> fetchNextAvailableSlot() async {
    // set the starting search date and the next weekend date
    _nextAvailableDate ??= DateTime.now();
    DateTime nextWeekendDate = _nextAvailableDate!;
    while (nextWeekendDate.weekday != DateTime.saturday &&
        nextWeekendDate.weekday != DateTime.sunday) {
      nextWeekendDate = nextWeekendDate.add(Duration(days: 1));
    }

    // find the next available slots from the created slots
    bool found = false;
    for (String dateStr in _slotDates) {
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
              if (Utils().getTimeFromString(date, slot.from).isAfter(Utils()
                  .getTimeFromString(
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
    if (_nextAvailableDate!.isAfter(nextWeekendDate)) {
      for (var slot in Const().weekendSangeetSevaSlots) {
        if (_nextAvailableSlot == null) {
          _nextAvailableDate = nextWeekendDate;
          _nextAvailableSlot = slot;
          break;
        } else if (Utils()
            .getTimeFromString(_nextAvailableDate!, _nextAvailableSlot!.from)
            .isAfter(Utils().getTimeFromString(nextWeekendDate, slot.from))) {
          if (await _isSlotAvailable(nextWeekendDate, slot)) {
            _nextAvailableDate = nextWeekendDate;
            _nextAvailableSlot = slot;
            break;
          }
        }
      }
    }

    // check if availability is found
    if (_nextAvailableDate == null || _nextAvailableSlot == null) {
      Toaster().error("No available slots found");
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
          onPressed: () {},
        ),
      ],
    );
  }
}
