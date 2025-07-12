import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  final Function() onIncrement;

  const MyWidget({super.key, required this.onIncrement});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int count = 0;

  void increment() {
    setState(() {
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('Count: $count');
  }
}
