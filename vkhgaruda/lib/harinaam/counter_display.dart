import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class CounterDisplay extends StatefulWidget {
  const CounterDisplay({super.key});

  @override
  State<CounterDisplay> createState() => CounterDisplayState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<CounterDisplayState> summaryKey = GlobalKey<CounterDisplayState>();

class CounterDisplayState extends State<CounterDisplay> {
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
    return const Placeholder();
  }
}
