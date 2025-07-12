import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

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
  final GlobalKey<CounterDisplayState> counterChantersKey =
      GlobalKey<CounterDisplayState>();
  final GlobalKey<CounterDisplayState> counterSalesKey =
      GlobalKey<CounterDisplayState>();

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
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Column(
              children: [
                CounterDisplay(
                  key: counterChantersKey,
                  fontSize: 48,
                  color: Colors.brown,
                  maxValue: 9999,
                ),
                Text("Chanters count",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: Colors.brown)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              children: [
                CounterDisplay(
                    key: counterSalesKey,
                    fontSize: 48,
                    maxValue: 999,
                    color: Theme.of(context).colorScheme.primary),
                Text("Japamala sold",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
