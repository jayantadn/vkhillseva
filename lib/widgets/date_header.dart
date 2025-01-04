import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateHeader extends StatefulWidget {
  final DateHeaderCallbacks? callbacks;

  const DateHeader({super.key, this.callbacks});

  @override
  State<DateHeader> createState() => _DateHeaderState();
}

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

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              child: child,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _date = DateTime.now();
                });
                if (widget.callbacks != null) {
                  widget.callbacks!.onChange(_date);
                }
              },
              child: Text('Today'),
            ),
          ],
        );
      },
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
      if (widget.callbacks != null) {
        widget.callbacks!.onChange(_date);
      }
    }
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
              child: Icon(
                Icons.play_arrow,
                color: Theme.of(context).iconTheme.color,
              ),
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
          PopupMenuButton<void>(
            onSelected: (_) {},
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<void>(
                enabled: false,
                child: Column(
                  children: [
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: CalendarDatePicker(
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        onDateChanged: (DateTime picked) {
                          setState(() {
                            _date = picked;
                          });
                          if (widget.callbacks != null) {
                            widget.callbacks!.onChange(_date);
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _date = DateTime.now();
                        });
                        if (widget.callbacks != null) {
                          widget.callbacks!.onChange(_date);
                        }
                        Navigator.pop(context);
                      },
                      child: Text('Today'),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 150.0,
              alignment: Alignment.center,
              child: Text(
                DateFormat('EEE, dd MMM').format(_date),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          // next day button
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ), // Default points right
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
