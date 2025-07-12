import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/common/const.dart';
import 'package:vkhpackages/widgets/radio_row.dart';

class HmiSales extends StatefulWidget {
  const HmiSales({super.key});

  @override
  State<HmiSales> createState() => HmiSalesState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<SummaryState> summaryKey = GlobalKey<SummaryState>();

class HmiSalesState extends State<HmiSales> {
  final Lock _lock = Lock();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');

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
    // perform async work here

    await _lock.synchronized(() async {
      // perform sync work here
      setState(() {});
    });
  }

  void _incrementQuantity() {
    int currentValue = int.tryParse(_quantityController.text) ?? 1;
    _quantityController.text = (currentValue + 1).toString();
  }

  void _decrementQuantity() {
    int currentValue = int.tryParse(_quantityController.text) ?? 1;
    if (currentValue > 1) {
      _quantityController.text = (currentValue - 1).toString();
    }
  }

  void _onSubmit() {
    // handle submit action
    print('Submitted with quantity: ${_quantityController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioRow(
            items: Const().paymentModes.keys.where((k) => k != "Gift").toList(),
            onChanged: (value) {
              // handle radio selection
            }),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: _decrementQuantity,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ),
            IconButton(
              onPressed: _incrementQuantity,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              onPressed: _onSubmit,
              icon: const Icon(Icons.check),
            ),
            IconButton(
              onPressed: () {
                // handle lock action
              },
              icon: const Icon(Icons.lock),
            ),
          ],
        ),
      ],
    );
  }
}
