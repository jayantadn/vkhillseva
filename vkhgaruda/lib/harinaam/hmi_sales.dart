import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

class HmiSales extends StatefulWidget {
  final void Function(SalesEntry) onSubmit;
  const HmiSales({super.key, required this.onSubmit});

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
  String _selectedPaymentMode = Const().paymentModes.keys.first;

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

    // read ticket from db
    String dbpath = "${Const().dbrootGaruda}/Settings/Harinaam/Japamalas";
    List japamalasRaw = await FB().getList(path: dbpath);
    Japamala japamala =
        Utils().convertRawToDatatype(japamalasRaw.first, Japamala.fromJson);

    SalesEntry newEntry = SalesEntry(
      count: intValue,
      japamala: japamala,
      timestamp: DateTime.now(),
      paymentMode: _selectedPaymentMode,
      sevakarta: Utils().getUsername(),
    );

    // handle submit action
    widget.onSubmit(newEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: RadioRow(
              items: Const().paymentModes.keys.toList(growable: false),
              onChanged: (value) {
                _selectedPaymentMode = value;
              }),
        ),
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
              icon: const Icon(Icons.lock_open),
            ),
          ],
        ),
      ],
    );
  }
}
