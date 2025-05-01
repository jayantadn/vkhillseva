import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class Summary extends StatefulWidget {
  const Summary({super.key});

  @override
  State<Summary> createState() => SummaryState();
}

// hint: put the global key as a member of the calling class
// instantiate the class with a global key
// final GlobalKey<_SummaryState> summaryKey = GlobalKey<_SummaryState>();

class SummaryState extends State<Summary> {
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
