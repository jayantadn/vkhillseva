import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TallyCashPage extends StatefulWidget {
  const TallyCashPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TallyNotesPageState createState() => _TallyNotesPageState();
}

class _TallyNotesPageState extends State<TallyCashPage> {
  final TextEditingController _controller500 = TextEditingController(text: '0');
  final TextEditingController _controller200 = TextEditingController(text: '0');
  final TextEditingController _controller100 = TextEditingController(text: '0');
  final TextEditingController _controller50 = TextEditingController(text: '0');
  final TextEditingController _controller20 = TextEditingController(text: '0');
  final TextEditingController _controller10 = TextEditingController(text: '0');

  bool _validationSuccess = false;
  int? _sumCash;
  DateTime? _timestampSlot;
  late Map<String, int> _cash;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    LS().read("selectedSlot").then((value) async {
      if (value != null) {
        // get the selected slot
        _timestampSlot = DateTime.parse(value);
        if (_timestampSlot == null) {
          Toaster().error('Could not read session');
          return;
        }

        // get the tickets
        List<Ticket> sevatickets = [];
        String dbDate = DateFormat("yyyy-MM-dd").format(_timestampSlot!);
        String dbSession =
            _timestampSlot!.toIso8601String().replaceAll(".", "^");
        List ticketsRaw = await FB().getList(
            path:
                "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/Tickets");
        for (var t in ticketsRaw) {
          Map<String, dynamic> ticket = Map<String, dynamic>.from(t);
          sevatickets.add(Ticket.fromJson(ticket));
        }

        // calculate the sum of _cash
        _sumCash = 0;
        for (Ticket sevaticket in sevatickets) {
          if (sevaticket.mode == 'Cash') {
            _sumCash = _sumCash! + sevaticket.amount;
          }
        }

        // set the _cash values
        FB()
            .getValue(
                path:
                    "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/TallyCash")
            .then((value) {
          if (value != null && value.isNotEmpty) {
            _cash = Map<String, int>.from(value as Map);
            _controller500.text = _cash['500'].toString();
            _controller200.text = _cash['200'].toString();
            _controller100.text = _cash['100'].toString();
            _controller50.text = _cash['50'].toString();
            _controller20.text = _cash['20'].toString();
            _controller10.text = _cash['10'].toString();
            _validateTotal();
          }
        });
      }
    });
  }

  Widget _widgetTotal() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0, // Increase the font size
          ),
        ),
        Row(
          children: [
            // sum of the entries
            Text(
              _calculateTotal([
                {'value': 500, 'controller': _controller500},
                {'value': 200, 'controller': _controller200},
                {'value': 100, 'controller': _controller100},
                {'value': 50, 'controller': _controller50},
                {'value': 20, 'controller': _controller20},
                {'value': 10, 'controller': _controller10},
              ]).toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0, // Increase the font size
              ),
            ),

            const SizedBox(
                width:
                    8), // Add some space between the icon and the total amount

            Container(
              // validation success icon
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _validationSuccess ? Colors.green : Colors.red,
              ),
              padding:
                  const EdgeInsets.all(1.0), // Adjust the padding as needed
              child: Icon(
                _validationSuccess ? Icons.check : Icons.close,
                color:
                    Colors.white, // Icon color to contrast with the background
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _validateTotal() {
    setState(() {
      if (_sumCash != null) {
        var total = _calculateTotal([
          {'value': 500, 'controller': _controller500},
          {'value': 200, 'controller': _controller200},
          {'value': 100, 'controller': _controller100},
          {'value': 50, 'controller': _controller50},
          {'value': 20, 'controller': _controller20},
          {'value': 10, 'controller': _controller10},
        ]);
        _validationSuccess = (total == _sumCash);
      } else {
        _validationSuccess = false;
      }
    });
  }

  void _saveCash() {
    if (_timestampSlot != null) {
      Map<String, int> json = {
        '500': int.tryParse(_controller500.text) ?? 0,
        '200': int.tryParse(_controller200.text) ?? 0,
        '100': int.tryParse(_controller100.text) ?? 0,
        '50': int.tryParse(_controller50.text) ?? 0,
        '20': int.tryParse(_controller20.text) ?? 0,
        '10': int.tryParse(_controller10.text) ?? 0,
      };

      // write to db
      String dbDate = DateFormat("yyyy-MM-dd").format(_timestampSlot!);
      String dbSession = _timestampSlot!.toIso8601String().replaceAll(".", "^");
      FB().setJson(
          path:
              "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/TallyCash",
          json: json);
    } else {
      Toaster().error('Unable to save');
    }

    Navigator.of(context).pop(); // Close the dialog
  }

  void _dialogSave(BuildContext context) {
    // decide the content of the dialog box
    var total = _calculateTotal([
      {'value': 500, 'controller': _controller500},
      {'value': 200, 'controller': _controller200},
      {'value': 100, 'controller': _controller100},
      {'value': 50, 'controller': _controller50},
      {'value': 20, 'controller': _controller20},
      {'value': 10, 'controller': _controller10},
    ]);
    var diff = total - _sumCash!;
    var msg = Text(
      'Do you want to save?',
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
    );
    if (diff > 0) {
      msg = Text(
        'Total money is excess by $diff.\nAre you sure you want to save?',
        style: const TextStyle(color: Colors.red),
      );
    } else if (diff < 0) {
      msg = Text(
        'Total money is short by ${diff.abs()}.\nAre you sure you want to save?',
        style: const TextStyle(color: Colors.red),
      );
    }

    // dont show dialog if diff is 0
    if (diff == 0) {
      _saveCash();

      return;
    }

    // show the dialog box
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: msg,
          actions: <Widget>[
            // No button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),

            // Yes button
            TextButton(
              onPressed: () {
                _saveCash();
                Navigator.of(context).pop(); // Go back to summary page
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDenominationField(
      String denomination, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          // denomination label
          Container(
            width: 60,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: Text(
                denomination,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // subtract button
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              int currentValue = int.tryParse(controller.text) ?? 0;
              if (currentValue > 0) {
                setState(() {
                  controller.text = (currentValue - 1).toString();
                });
              }
              _validateTotal();
            },
          ),

          // number of notes
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _validateTotal();
                });
              },
            ),
          ),

          // add button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              int currentValue = int.tryParse(controller.text) ?? 0;
              setState(() {
                controller.text = (currentValue + 1).toString();
              });
              _validateTotal();
            },
          ),

          // total amount
          const SizedBox(width: 8),
          Container(
            width: 60, // Adjust the width as needed to fit 5 digits
            alignment: Alignment.center, // Center the text within the container
            child: Text(
              '${(int.tryParse(controller.text) ?? 0) * int.parse(denomination)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold, // Make the font bold
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotal(List<Map<String, dynamic>> denominations) {
    int total = 0;
    for (var denomination in denominations) {
      int value = denomination['value'];
      TextEditingController controller = denomination['controller'];
      int count = int.tryParse(controller.text) ?? 0;
      total += value * count;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeGaruda,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tally Cash'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                _buildDenominationField('500', _controller500),
                _buildDenominationField('200', _controller200),
                _buildDenominationField('100', _controller100),
                _buildDenominationField('50', _controller50),
                _buildDenominationField('20', _controller20),
                _buildDenominationField('10', _controller10),

                // the sum total
                const Divider(),
                _widgetTotal(),
                const Divider(),

                // save button
                ElevatedButton(
                  onPressed: () {
                    _dialogSave(context);
                  },
                  child: const Text('Verify & Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
