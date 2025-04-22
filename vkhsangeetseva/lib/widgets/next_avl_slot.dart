import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

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
