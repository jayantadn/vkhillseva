import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:google_fonts/google_fonts.dart';

class CounterDisplay extends StatefulWidget {
  final double fontSize;
  final Color color;
  const CounterDisplay({
    super.key,
    required this.fontSize,
    this.color = Colors.black,
  });

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
    return Text(
      "1234",
      style: GoogleFonts.orbitron(
        fontSize: widget.fontSize,
        letterSpacing: 2.0,
        color: widget.color,
      ),
    );
  }
}
