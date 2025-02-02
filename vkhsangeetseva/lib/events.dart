import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class Events extends StatefulWidget {
  const Events({super.key});

  @override
  State<Events> createState() => _EventsState();
}

// hint: instantiate the class with a global key
// ignore: library_private_types_in_public_api
GlobalKey<_EventsState> eventsKey = GlobalKey<_EventsState>();

class _EventsState extends State<Events> {
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

    // perform sync work here
    await _lock.synchronized(() async {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
