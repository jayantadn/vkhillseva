import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class HmiChanters extends StatefulWidget {
  final void Function(int) onSubmit;
  const HmiChanters({super.key, required this.onSubmit});

  @override
  State<HmiChanters> createState() => HmiChantersState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<_SummaryState> summaryKey = GlobalKey<_SummaryState>();

class HmiChantersState extends State<HmiChanters> {
  final Lock _lock = Lock();
  final TextEditingController _numberController =
      TextEditingController(text: '0');
  bool _isLocked = false;

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
    if (currentValue > 0) {
      _numberController.text = (currentValue - 1).toString();
    }
  }

  void _increment() {
    int currentValue = int.tryParse(_numberController.text) ?? 0;
    _numberController.text = (currentValue + 1).toString();
  }

  void _increment10x() {
    int currentValue = int.tryParse(_numberController.text) ?? 0;
    _numberController.text = (currentValue + 10).toString();
  }

  void setLockState(bool isLocked) {
    setState(() {
      _isLocked = isLocked;
    });
  }

  void _submit() {
    int value = int.tryParse(_numberController.text) ?? 0;
    if (value <= 0) {
      Toaster().error('Please enter a valid number');
      return;
    }

    // clear the text field
    _numberController.text = '0';

    widget.onSubmit(value);
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
            onPressed: _isLocked ? null : _decrement,
            icon: Icon(
              Icons.remove,
              color: _isLocked ? Colors.grey : Colors.brown,
            ),
            tooltip: 'Decrement',
          ),
          // Numeric input field
          SizedBox(
            width: 100,
            child: TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              readOnly: _isLocked ? true : false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (value) {
                // Additional validation on change
                if (value.isEmpty) {
                  _numberController.text = '0';
                  _numberController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _numberController.text.length),
                  );
                } else {
                  int? intValue = int.tryParse(value);
                  if (intValue == null || intValue < 1) {
                    _numberController.text = '1';
                    _numberController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _numberController.text.length),
                    );
                  }
                }
              },
            ),
          ),

          // Increment button
          IconButton(
            onPressed: _isLocked ? null : _increment,
            icon:
                Icon(Icons.add, color: _isLocked ? Colors.grey : Colors.brown),
            tooltip: 'Increment',
          ),

          // 10x increment button
          IconButton(
            onPressed: _isLocked ? null : _increment10x,
            icon: Icon(Icons.add_box_outlined,
                color: _isLocked ? Colors.grey : Colors.brown),
            tooltip: 'Increment by 10',
          ),

          // Submit button
          IconButton(
            onPressed: _submit,
            icon: Icon(Icons.check,
                color: _isLocked ? Colors.grey : Colors.brown),
            tooltip: 'Submit',
          ),
        ],
      ),
    );
  }
}
