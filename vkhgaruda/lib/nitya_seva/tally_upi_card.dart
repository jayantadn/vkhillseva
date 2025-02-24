import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhgaruda/nitya_seva/ticket_page.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TallyUpiCardPage extends StatefulWidget {
  const TallyUpiCardPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TallyNotesPageState createState() => _TallyNotesPageState();
}

class _TallyNotesPageState extends State<TallyUpiCardPage> {
  final TextEditingController _controller400 = TextEditingController(text: '0');
  final TextEditingController _controller500 = TextEditingController(text: '0');
  final TextEditingController _controller1000 =
      TextEditingController(text: '0');
  final TextEditingController _controller2500 =
      TextEditingController(text: '0');

  bool _validationSuccess = false;
  int? _sumCash;
  DateTime? _timestampSlot;

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

        // calculate the sum of _money
        _sumCash = 0;
        for (Ticket sevaticket in sevatickets) {
          if (sevaticket.mode == 'Card' || sevaticket.mode == 'UPI') {
            _sumCash = _sumCash! + sevaticket.amount;
          }
        }

        // set the _money values
        FB()
            .getValue(
                path:
                    "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/TallyUpiCard")
            .then((value) {
          if (value != null && value.isNotEmpty) {
            _controller400.text = value['400'].toString();
            _controller500.text = value['500'].toString();
            _controller1000.text = value['1000'].toString();
            _controller2500.text = value['2500'].toString();
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
                {'value': 400, 'controller': _controller400},
                {'value': 500, 'controller': _controller500},
                {'value': 1000, 'controller': _controller1000},
                {'value': 2500, 'controller': _controller2500},
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
                color: _validationSuccess
                    ? Colors.green
                    : Colors.red, // Set the background color to green or red
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
          {'value': 400, 'controller': _controller400},
          {'value': 500, 'controller': _controller500},
          {'value': 1000, 'controller': _controller1000},
          {'value': 2500, 'controller': _controller2500},
        ]);
        _validationSuccess = (total == _sumCash);
      } else {
        _validationSuccess = false;
      }
    });
  }

  void _dialogSave(BuildContext context) {
    // decide the content of the dialog box
    var total = _calculateTotal([
      {'value': 400, 'controller': _controller400},
      {'value': 500, 'controller': _controller500},
      {'value': 1000, 'controller': _controller1000},
      {'value': 2500, 'controller': _controller2500},
    ]);
    var diff = total - _sumCash!;
    var msg = Text(
      'Do you want to save?',
      style: TextStyle(color: primaryColor),
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
                if (_timestampSlot != null) {
                  Map<String, int> json = {
                    '400': int.tryParse(_controller400.text) ?? 0,
                    '500': int.tryParse(_controller500.text) ?? 0,
                    '1000': int.tryParse(_controller1000.text) ?? 0,
                    '2500': int.tryParse(_controller2500.text) ?? 0,
                  };

                  // write to db
                  String dbDate =
                      DateFormat("yyyy-MM-dd").format(_timestampSlot!);
                  String dbSession =
                      _timestampSlot!.toIso8601String().replaceAll(".", "^");
                  FB().setJson(
                      path:
                          "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/TallyUpiCard",
                      json: json);
                } else {
                  Toaster().error('Unable to save');
                }

                Navigator.of(context).pop(); // Close the dialog
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
            width: 60, // Adjust the width as needed to fit 3 digits
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: primaryColor, // Set background color to brown
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: Text(
                denomination,
                style: const TextStyle(
                  color: Colors.white, // Set font color to white
                  fontWeight: FontWeight.bold, // Make the font bold
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
      data: themeDefault,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tally UPI / Card'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                _buildDenominationField('400', _controller400),
                _buildDenominationField('500', _controller500),
                _buildDenominationField('1000', _controller1000),
                _buildDenominationField('2500', _controller2500),

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
