import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<DashboardState> summaryKey = GlobalKey<DashboardState>();

class DashboardState extends State<Dashboard> {
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
