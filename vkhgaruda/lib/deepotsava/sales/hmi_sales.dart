import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/deepotsava/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

class HmiSales extends StatefulWidget {
  final void Function(SalesEntry) onSubmit;
  final Color color;
  const HmiSales({super.key, required this.onSubmit, required this.color});

  @override
  State<HmiSales> createState() => HmiSalesState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<SummaryState> summaryKey = GlobalKey<SummaryState>();

class HmiSalesState extends State<HmiSales> {
  final Lock _lock = Lock();
  final TextEditingController _quantityController =
      TextEditingController(text: '0');
  bool _isLocked = false;
  bool _isPlateIncluded = false;

  final GlobalKey<RadioRowState> keyRadioRow = GlobalKey<RadioRowState>();

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _quantityController.dispose();

    // dispose all controllers

    super.dispose();
  }

  Future<void> refresh() async {
    await _lock.synchronized(() async {
      // perform your work here

      setState(() {});
    });
  }

  void _incrementQuantity() {
    int currentValue = int.tryParse(_quantityController.text) ?? 1;
    _quantityController.text = (currentValue + 1).toString();
  }

  void _decrementQuantity() {
    int currentValue = int.tryParse(_quantityController.text) ?? 0;
    if (currentValue > 0) {
      _quantityController.text = (currentValue - 1).toString();
    }
  }

  Future<void> _onSubmit() async {
    // validations
    String value = _quantityController.text.trim();
    if (value.isEmpty) {
      Toaster().error('Please enter a quantity');
      return;
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue <= 0) {
      Toaster().error('Please enter a valid quantity');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      Toaster().error('Only numbers are allowed');
      return;
    }

    // clear the text field
    _quantityController.text = '0';
    keyRadioRow.currentState?.resetSelection();

    SalesEntry newEntry = SalesEntry(
        timestamp: DateTime.now(),
        username: Utils().getUsername(),
        count: _quantityController.text.isEmpty
            ? 0
            : int.parse(_quantityController.text),
        paymentMode: "Unknown",
        isPlateIncluded: false // FIXME: get this value from UI
        );

    // handle submit action
    widget.onSubmit(newEntry);
  }

  void setLockState(bool isLocked) {
    setState(() {
      _isLocked = isLocked;
    });
  }

  Future<void> _showCustomEntryDialog(BuildContext context) async {
    await Widgets().showResponsiveDialog(
      context: context,
      title: 'Enter Quantity',
      child: TextFormField(
        autofocus: true,
        controller: _quantityController,
      ),
      actions: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Submit'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // radio buttons
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: RadioRow(
              key: keyRadioRow,
              items: ["1", "2", "5", "10"],
              selectedIndex: -1, // skip selection
              color: widget.color,
              onChanged: (value) {
                setState(() {
                  _quantityController.text = value;

                  // if value is 5 or more, set plate included to true
                  if (int.tryParse(value) != null) {
                    if (int.parse(value) >= 5) {
                      _isPlateIncluded = true;
                    } else {
                      _isPlateIncluded = false;
                    }
                  }
                });
              }),
        ),

        // text field with increment and decrement buttons
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // plates button
            GestureDetector(
              onTap: _isLocked
                  ? null
                  : () {
                      setState(() {
                        _isPlateIncluded = !_isPlateIncluded;
                      });
                    },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color, width: 2),
                  color: _isPlateIncluded ? widget.color : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  'P',
                  style: TextStyle(
                    color: _isPlateIncluded ? Colors.white : widget.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            // decrement
            IconButton(
              onPressed: _isLocked ? null : _decrementQuantity,
              icon: const Icon(Icons.remove),
              color: widget.color,
            ),

            // text field
            SizedBox(
              width: 80,
              child: GestureDetector(
                onTap: _isLocked ? null : () => _showCustomEntryDialog(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ),
            ),

            // increment
            IconButton(
              onPressed: _isLocked ? null : _incrementQuantity,
              icon: const Icon(Icons.add),
              color: widget.color,
            ),

            // submit button
            IconButton(
              onPressed: _isLocked ? null : _onSubmit,
              icon: Icon(
                Icons.check,
              ),
              color: widget.color,
            ),
          ],
        ),
      ],
    );
  }
}
