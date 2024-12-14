import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class DaySummary extends StatefulWidget {
  const DaySummary({super.key});

  @override
  State<DaySummary> createState() => _DaySummaryState();
}

GlobalKey<_DaySummaryState> daySummaryKey = GlobalKey<_DaySummaryState>();

class _DaySummaryState extends State<DaySummary> {
  final Lock _lock = Lock();

  @override
  void initState() {
    super.initState();

    refresh();
  }

  void refresh() async {
    await _lock.synchronized(() async {
      // all you need to do
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity, // Stretch to full width
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Summary",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Add your remaining widgets here
                Text("Content goes here"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
