import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class HmiChanters extends StatefulWidget {
  const HmiChanters({super.key});

  @override
  State<HmiChanters> createState() => HmiChantersState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<_SummaryState> summaryKey = GlobalKey<_SummaryState>();

class HmiChantersState extends State<HmiChanters> {
  final Lock _lock = Lock();
  final TextEditingController _numberController =
      TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // dispose all controllers
    _numberController.dispose();

    super.dispose();
  }

  Future<void> refresh() async {
    // perform async work here

    await _lock.synchronized(() async {
      // perform sync work here
      setState(() {});
    });
  }

  void _decrement() {
    int currentValue = int.tryParse(_numberController.text) ?? 0;
    _numberController.text = (currentValue - 1).toString();
  }

  void _increment() {
    int currentValue = int.tryParse(_numberController.text) ?? 0;
    _numberController.text = (currentValue + 1).toString();
  }

  void _increment10x() {
    int currentValue = int.tryParse(_numberController.text) ?? 0;
    _numberController.text = (currentValue + 10).toString();
  }

  void _submit() {
    // Handle submit action
    print('Submitted value: ${_numberController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decrement button
          IconButton(
            onPressed: _decrement,
            icon: const Icon(Icons.remove, color: Colors.brown),
            tooltip: 'Decrement',
          ),
          // Numeric input field
          SizedBox(
            width: 100,
            child: TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          // Increment button
          IconButton(
            onPressed: _increment,
            icon: const Icon(Icons.add, color: Colors.brown),
            tooltip: 'Increment',
          ),
          // 10x increment button
          IconButton(
            onPressed: _increment10x,
            icon: const Icon(Icons.add_box_outlined, color: Colors.brown),
            tooltip: 'Increment by 10',
          ),
          // Submit button
          IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.check, color: Colors.brown),
            tooltip: 'Submit',
          ),
        ],
      ),
    );
  }
}
