import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/deepotsava/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

class HmiSales extends StatefulWidget {
  final void Function(SalesEntry) onSubmit;
  final String paymentMode;
  const HmiSales(
      {super.key, required this.onSubmit, required this.paymentMode});

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
  bool _isPlateIncluded = false;
  late Color _color;

  final GlobalKey<RadioRowState> keyRadioRow = GlobalKey<RadioRowState>();

  @override
  void initState() {
    super.initState();

    Const().paymentModes[widget.paymentMode] != null
        ? _color = Const().paymentModes[widget.paymentMode]!['color'] as Color
        : _color = Colors.grey;

    Utils().fetchUserBasics();

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

  Widget _createSubmitButton(BuildContext context) {
    bool isActive = int.tryParse(_quantityController.text) != null &&
        int.parse(_quantityController.text) > 0;
    int amount = (int.tryParse(_quantityController.text) ?? 0) *
        Const().deepotsava['deepamPrice'] as int;
    if (_isPlateIncluded) {
      amount += Const().deepotsava['platePrice'] as int;
      isActive = true;
    }

    return Card(
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: GestureDetector(
          onTap: _onSubmit,
          child: Column(
            children: [
              // amount text
              Text(
                '₹$amount',
                style: TextStyle(
                  color: isActive ? _color : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              // submit text
              Text(
                'Submit',
                style: TextStyle(
                  color: isActive ? _color : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                  decoration:
                      isActive ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: _color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _decrementQuantity() {
    setState(() {
      int currentValue = int.tryParse(_quantityController.text) ?? 0;
      if (currentValue > 0) {
        _quantityController.text = (currentValue - 1).toString();
      }
    });
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

    SalesEntry newEntry = SalesEntry(
      timestamp: DateTime.now(),
      username: Utils().getUsername(),
      count: int.tryParse(_quantityController.text) ?? 0,
      paymentMode: widget.paymentMode,
      isPlateIncluded: _isPlateIncluded,
      deepamPrice: Const().deepotsava['deepamPrice'] as int,
      platePrice: Const().deepotsava['platePrice'] as int,
    );

    // clear the text field
    _quantityController.text = '0';
    _isPlateIncluded = false;
    keyRadioRow.currentState?.resetSelection();
    setState(() {});

    // handle submit action
    widget.onSubmit(newEntry);
  }

  void _incrementQuantity() {
    setState(() {
      int currentValue = int.tryParse(_quantityController.text) ?? 0;
      _quantityController.text = (currentValue + 1).toString();
    });
  }

  Future<void> _showCustomEntryDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();

    await Widgets().showResponsiveDialog(
      context: context,
      title: 'Enter Quantity',
      child: Form(
        key: formKey,
        child: TextFormField(
          autofocus: true,
          controller: _quantityController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a quantity';
            }
            final intValue = int.tryParse(value);
            if (intValue == null || intValue <= 0) {
              return 'Please enter a valid quantity';
            }
            if (!RegExp(r'^\d+$').hasMatch(value)) {
              return 'Only numbers are allowed';
            }
            return null;
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('OK'),
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
              color: _color,
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
              onTap: () {
                setState(() {
                  _isPlateIncluded = !_isPlateIncluded;
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _color, width: 2),
                  color: _isPlateIncluded ? _color : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  'P',
                  style: TextStyle(
                    color: _isPlateIncluded ? Colors.white : _color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            // decrement
            IconButton(
              onPressed: _decrementQuantity,
              icon: const Icon(Icons.remove),
              color: _color,
            ),

            // text field
            SizedBox(
              width: 50,
              child: GestureDetector(
                onTap: () => _showCustomEntryDialog(context),
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
              onPressed: _incrementQuantity,
              icon: const Icon(Icons.add),
              color: _color,
            ),

            // submit button
            _createSubmitButton(context),
          ],
        ),
      ],
    );
  }
}
