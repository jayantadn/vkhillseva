import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateHeader extends StatefulWidget {
  final DateHeaderCallbacks? callbacks;

  const DateHeader({super.key, this.callbacks});

  @override
  State<DateHeader> createState() => _DateHeaderState();
}

// hint: templateKey.currentState!.refresh();
final GlobalKey<_DateHeaderState> HistoryHeaderKey =
    GlobalKey<_DateHeaderState>();

class _DateHeaderState extends State<DateHeader> {
  DateTime _date = DateTime.now();

  @override
  initState() {
    super.initState();

    refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // previous day button
          IconButton(
            icon: Transform.rotate(
              angle: 3.14, // Rotate 180 degrees to point left
              child: Icon(Icons.play_arrow),
            ),
            onPressed: () {
              if (widget.callbacks == null) {
                return;
              }

              setState(() {
                _date = _date.subtract(Duration(days: 1));
              });

              widget.callbacks!.onChange(_date);
            },
          ),

          // date
          GestureDetector(
            onTap: () {
              if (widget.callbacks == null) {
                return;
              }

              setState(() {
                _date = DateTime.now();
              });

              widget.callbacks!.onChange(_date);
            },
            child: Container(
              width: 150.0,
              alignment: Alignment.center,
              child: Text(
                DateFormat('EEE, dd MMM').format(_date),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),

          // next day button
          IconButton(
            icon: Icon(Icons.play_arrow), // Default points right
            onPressed: () {
              if (widget.callbacks == null) {
                return;
              }

              if (_date.year == DateTime.now().year &&
                  _date.month == DateTime.now().month &&
                  _date.day == DateTime.now().day) {
                return;
              }

              setState(() {
                _date = _date.add(Duration(days: 1));
              });

              widget.callbacks!.onChange(_date);
            },
          ),
        ],
      ),
    );
  }
}

class DateHeaderCallbacks {
  void Function(DateTime) onChange;

  DateHeaderCallbacks({
    required this.onChange,
  });
}
