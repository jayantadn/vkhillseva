import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/common/const.dart';
import 'package:vkhpackages/common/fb.dart';

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
  DateTime? _lastCheckedDate; // Class member to store the last checked date

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
    print(await getNextAvailableSlot());
    print("****************");
    print(await getNextAvailableSlot());

    await _lock.synchronized(() async {
      // perform sync work here
      setState(() {});
    });
  }

  Future<Map<String, dynamic>> getNextAvailableSlot() async {
    DateTime currentDate = _lastCheckedDate?.add(Duration(days: 1)) ??
        DateTime
            .now(); // Start from the day after the last checked date or today

    while (true) {
      String dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

      // Check if the date exists in the _slotDates list
      if (_slotDates.contains(dateStr)) {
        var slotsRaw = await FB()
            .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dateStr");
        Map<String, dynamic> slots = Map<String, dynamic>.from(slotsRaw);

        // Check if any slot is available
        for (var entry in slots.entries) {
          if (entry.value['avl'] == true) {
            _lastCheckedDate = currentDate; // Update last checked date
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
      }

      // Check for weekend slots if the current date is a weekend
      if (currentDate.weekday == DateTime.saturday ||
          currentDate.weekday == DateTime.sunday) {
        for (var slot in Const().weekendSangeetSevaSlots) {
          if (slot.avl) {
            _lastCheckedDate = currentDate; // Update last checked date
            return {
              'date': dateStr,
              'slot': {'name': slot.name, 'from': slot.from, 'to': slot.to}
            };
          }
        }
      }

      // Move to the next day
      currentDate = currentDate.add(Duration(days: 1));
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
