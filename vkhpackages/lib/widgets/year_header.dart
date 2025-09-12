import 'package:flutter/material.dart';

class YearHeader extends StatefulWidget {
  final YearHeaderCallbacks? callbacks;

  const YearHeader({super.key, this.callbacks});

  @override
  State<YearHeader> createState() => _YearHeaderState();
}

class _YearHeaderState extends State<YearHeader> {
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {});
  }

  void _selectYear(BuildContext context) async {
    int? picked = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int tempYear = _year;
        return AlertDialog(
          title: Text('Select Year'),
          content: SizedBox(
            width: 200,
            height: 250,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime(DateTime.now().year + 10),
              selectedDate: DateTime(_year),
              onChanged: (DateTime dateTime) {
                tempYear = dateTime.year;
                Navigator.pop(context, tempYear);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, DateTime.now().year);
              },
              child: Text('This Year'),
            ),
          ],
        );
      },
    );
    if (picked != null && picked != _year) {
      setState(() {
        _year = picked;
      });
      if (widget.callbacks != null) {
        widget.callbacks!.onChange(_year);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // previous year button
          IconButton(
            icon: Transform.rotate(
              angle: 3.14, // Rotate 180 degrees to point left
              child: Icon(
                Icons.play_arrow,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            onPressed: () {
              setState(() {
                _year = _year - 1;
              });
              if (widget.callbacks != null) {
                widget.callbacks!.onChange(_year);
              }
            },
          ),

          // year display and picker
          GestureDetector(
            onTap: () => _selectYear(context),
            child: Container(
              width: 100.0,
              alignment: Alignment.center,
              child: Text(
                _year.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          // next year button
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ), // Default points right
            onPressed: () {
              setState(() {
                _year = _year + 1;
              });
              if (widget.callbacks != null) {
                widget.callbacks!.onChange(_year);
              }
            },
          ),
        ],
      ),
    );
  }
}

class YearHeaderCallbacks {
  void Function(int) onChange;

  YearHeaderCallbacks({required this.onChange});
}
