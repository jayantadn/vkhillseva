import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:synchronized/synchronized.dart';
import 'package:google_fonts/google_fonts.dart';

class CounterDisplay extends StatefulWidget {
  final double fontSize;
  final Color color;
  final int maxValue;
  final int minValue;

  const CounterDisplay({
    super.key,
    required this.fontSize,
    this.color = Colors.black,
    this.maxValue = 999,
    this.minValue = 0,
  });

  @override
  State<CounterDisplay> createState() => CounterDisplayState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<CounterDisplayState> summaryKey = GlobalKey<CounterDisplayState>();

class CounterDisplayState extends State<CounterDisplay> {
  final Lock _lock = Lock();
  late FixedExtentScrollController _scrollController;
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: _currentValue);
    refresh();
  }

  @override
  dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // API method to programmatically set the counter value
  Future<void> setCounterValue(int value) async {
    if (value < widget.minValue || value > widget.maxValue) {
      return; // Value out of range
    }

    await _lock.synchronized(() async {
      _currentValue = value;
      if (_scrollController.hasClients) {
        await _scrollController.animateToItem(
          _currentValue,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      setState(() {});
    });
  }

  // API method to get the current counter value
  int getCurrentValue() {
    return _currentValue;
  }

  // API method to increment the counter
  Future<void> increment() async {
    if (_currentValue < widget.maxValue) {
      await setCounterValue(_currentValue + 1);
    }
  }

  // API method to decrement the counter
  Future<void> decrement() async {
    if (_currentValue > widget.minValue) {
      await setCounterValue(_currentValue - 1);
    }
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
    // Calculate the number of digits needed based on maxValue
    final int digitCount = widget.maxValue.toString().length;

    return SizedBox(
      height: widget.fontSize,
      child: IgnorePointer(
        child: CupertinoPicker(
          scrollController: _scrollController,
          itemExtent: widget.fontSize * 1.5,
          onSelectedItemChanged: null,
          children: List.generate(widget.maxValue - widget.minValue + 1, (
            index,
          ) {
            final value = widget.minValue + index;
            return Center(
              child: Text(
                value.toString().padLeft(
                  digitCount,
                  '0',
                ), // Format based on maxValue digits
                style: TextStyle(
                  fontFamily: 'Digital-7',
                  fontSize: widget.fontSize,
                  letterSpacing: 2.0,
                  color: widget.color,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
