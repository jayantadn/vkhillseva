import 'package:flutter/material.dart';
import 'package:vkhgaruda/nitya_seva/laddu/datatypes.dart';
import 'package:vkhgaruda/nitya_seva/laddu/fbl.dart';
import 'package:vkhgaruda/nitya_seva/laddu/utils.dart';
import 'package:vkhgaruda/nitya_seva/session.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Serve extends StatefulWidget {
  final LadduServe? serve; // for update
  final Session? slot;

  const Serve({super.key, this.serve, this.slot});

  @override
  _ServeState createState() => _ServeState();
}

class _ServeState extends State<Serve> {
  List<TextEditingController> _controllersPushpanjali = [];
  List<TextEditingController> _controllersOtherSeva = [];
  List<TextEditingController> _controllerMisc = [];
  final TextEditingController _controllerNote = TextEditingController();
  final TextEditingController _controllerTitle = TextEditingController();

  int _totalLadduPacks = 0;
  final List<String> _misc = ["Miscellaneous"];
  bool _isLoading = false;

  final List<Map<String, int>> _pushpanjaliTickets = [
    // do not delete the default values
    {'amount': 500, 'ladduPacks': 1},
    {'amount': 600, 'ladduPacks': 1},
    {'amount': 1000, 'ladduPacks': 2},
    {'amount': 2500, 'ladduPacks': 3},
  ];

  final List<Map<String, dynamic>> _otherSevaTickets = [
    // do not delete the default values
    {
      'name': "Special Puja",
      'amount': 0,
      'ladduPacks': 1,
    },
    {
      'name': "Festival",
      'amount': 500,
      'ladduPacks': 2,
    },
  ];

  @override
  void initState() {
    super.initState();

    List<int?> pushpanjaliTickets = [];
    List amountsList = Const().nityaSeva['amounts'] as List;
    for (var amountRaw in amountsList) {
      Map<String, dynamic> amountMap = Map<String, dynamic>.from(amountRaw);
      if (amountMap.values.first['obsolete'] == false) {
        pushpanjaliTickets.add(int.parse(amountMap.keys.first));
      }
    }

    // default populate the controllers
    _controllersPushpanjali = List.generate(
        pushpanjaliTickets.length, (index) => TextEditingController());
    _controllersOtherSeva = List.generate(
        _otherSevaTickets.length, (index) => TextEditingController());
    _controllerMisc =
        List.generate(_misc.length, (index) => TextEditingController());

    _refresh();
  }

  Future<void> _refresh() async {
    // load settings from fb
    List pushpanjaliTicketsRaw = await FB().getValue(
      path:
          "${Const().dbrootGaruda}/Settings/LadduDistribution/LadduPackMultiplier/Pushpanjali",
    );
    _pushpanjaliTickets.clear();
    for (var ticket in pushpanjaliTicketsRaw) {
      _pushpanjaliTickets.add(Map<String, int>.from(ticket));
    }
    List otherSevaTicketsRaw = await FB().getValue(
      path:
          "${Const().dbrootGaruda}/Settings/LadduDistribution/LadduPackMultiplier/OtherSevas",
    );
    _otherSevaTickets.clear();
    for (var ticket in otherSevaTicketsRaw) {
      _otherSevaTickets.add(Map<String, dynamic>.from(ticket));
    }

    // in edit mode, prefill all the controllers
    if (widget.serve != null) {
      // assuming that all sequences are correct

      // controllers for other seva
      for (int i = 0; i < widget.serve!.packsOtherSeva.length; i++) {
        int multiplier = _otherSevaTickets[i]['ladduPacks']!;
        int value = widget.serve!.packsOtherSeva[i].values.first ~/ multiplier;
        _controllersOtherSeva[i].text = value.toString();
      }

      // controllers for pushpanjali
      for (int i = 0; i < widget.serve!.packsPushpanjali.length; i++) {
        int multiplier = _pushpanjaliTickets[i]['ladduPacks']!;
        int value =
            widget.serve!.packsPushpanjali[i].values.first ~/ multiplier;
        _controllersPushpanjali[i].text =
            value.toString(); // assuming that there is only one key-value pair
      }

      // controllers for misc
      for (int i = 0; i < widget.serve!.packsMisc.length; i++) {
        _controllerMisc[i].text = widget.serve!.packsMisc[i].values.first
            .toString(); // assuming that there is only one key-value pair
      }

      // controller for title and note
      _controllerTitle.text = widget.serve!.title;
      _controllerNote.text = widget.serve!.note;
    } else {
      // formulate title for the slot
      _controllerTitle.text = widget.slot!.name;
    }

    _calculateTotalLadduPacks();

    setState(() {});
  }

  void _calculateTotalLadduPacks() {
    _totalLadduPacks = 0;

    // add all entries for pushpanjali
    for (int i = 0; i < _controllersPushpanjali.length; i++) {
      if (_controllersPushpanjali[i].text.isNotEmpty) {
        int multiplier = _pushpanjaliTickets[i]['ladduPacks']!;
        _totalLadduPacks +=
            (int.tryParse(_controllersPushpanjali[i].text)! * multiplier);
      }
    }

    // add all entries for other sevas
    for (int i = 0; i < _controllersOtherSeva.length; i++) {
      if (_controllersOtherSeva[i].text.isNotEmpty) {
        int multiplier = _otherSevaTickets[i]['ladduPacks']!;
        _totalLadduPacks +=
            (int.tryParse(_controllersOtherSeva[i].text)! * multiplier);
      }
    }

    // add all entries for misc
    for (int i = 0; i < _controllerMisc.length; i++) {
      _totalLadduPacks += int.tryParse(_controllerMisc[i].text) ?? 0;
    }
  }

  Widget _createTable() {
    List<int?> pushpanjaliTickets =
        _pushpanjaliTickets.map((e) => e['amount']).toList();

    return Table(
      columnWidths: {
        0: FixedColumnWidth(150.0), // Set fixed width for the first column
      },
      children: [
        // Table header
        TableRow(
          children: [
            // seva header
            TableCell(
              verticalAlignment:
                  TableCellVerticalAlignment.middle, // Center vertically
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Seva',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0, // Increase font size
                    ),
                  ),
                ),
              ),
            ),

            // tickets header
            TableCell(
              verticalAlignment:
                  TableCellVerticalAlignment.middle, // Center vertically
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Tickets',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0, // Increase font size
                    ),
                  ),
                ),
              ),
            ),

            // packs header
            TableCell(
              verticalAlignment:
                  TableCellVerticalAlignment.middle, // Center vertically
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Packs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0, // Increase font size
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Table rows for pushpanjali
        for (int i = 0; i < _pushpanjaliTickets.length; i++)
          TableRow(
            children: [
              // seva cell
              TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.middle, // Center vertically
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Seva ${pushpanjaliTickets[i]}'),
                  ),
                ),
              ),

              // number of tickets
              TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.middle, // Center vertically
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: TextField(
                      controller: _controllersPushpanjali[i],
                      keyboardType:
                          TextInputType.number, // Set keyboard to numeric
                      onChanged: (value) {
                        setState(() {
                          _calculateTotalLadduPacks();
                        });
                      },
                      decoration: InputDecoration(
                        border:
                            OutlineInputBorder(), // Add border around the text field
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 8.0), // Reduce vertical height
                      ),
                    ),
                  ),
                ),
              ),

              // number of laddu packs
              TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.middle, // Center vertically
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: _controllersPushpanjali[i].text.isEmpty
                        ? Text("0")
                        : Text((int.parse(_controllersPushpanjali[i].text) *
                                _pushpanjaliTickets[i]['ladduPacks']!)
                            .toString()),
                  ),
                ),
              ),
            ],
          ),

        // Table rows for other sevas
        for (int i = 0; i < _otherSevaTickets.length; i++)
          TableRow(
            children: [
              // seva cell
              TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.middle, // Center vertically
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("${_otherSevaTickets[i]['name']}"),
                  ),
                ),
              ),

              // number of tickets for other Seva
              TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.middle, // Center vertically
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: TextField(
                      controller: _controllersOtherSeva[i],
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _calculateTotalLadduPacks();
                        });
                      },
                      decoration: InputDecoration(
                        border:
                            OutlineInputBorder(), // Add border around the text field
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 8.0), // Reduce vertical height
                      ),
                    ),
                  ),
                ),
              ),

              // number of laddu packs
              TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.middle, // Center vertically
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: _controllersOtherSeva[i].text.isEmpty
                        ? Text("0")
                        : Text((int.parse(_controllersOtherSeva[i].text) *
                                _otherSevaTickets[i]['ladduPacks']!)
                            .toString()),
                  ),
                ),
              ),
            ],
          ),

        // Table rows for Others and Missing
        for (String seva in _misc)
          TableRow(
            children: [
              // seva cell
              TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.middle, // Center vertically
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(seva),
                  ),
                ),
              ),

              // empty tickets cell
              TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.middle, // Center vertically
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(''),
                  ),
                ),
              ),

              // packs cell for misc
              TableCell(
                verticalAlignment:
                    TableCellVerticalAlignment.middle, // Center vertically
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _calculateTotalLadduPacks();
                        });
                      },
                      decoration: InputDecoration(
                        border:
                            OutlineInputBorder(), // Add border around the text field
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 8.0),
                      ),
                      controller: _controllerMisc[_misc.indexOf(seva)],
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _onpressServe() async {
    if (_totalLadduPacks == 0) {
      Toaster().error('Nothing entered');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // calculate available laddu packs
    int available = 0;
    if (widget.serve != null) {
      available = widget.serve!.available ?? 0;
    } else {
      DateTime session = await FBL().readLatestLadduSession();
      await FBL().readLadduStocks(session).then((stocks) {
        for (LadduStock stock in stocks) {
          available += stock.count;
        }
      });
      await FBL().readLadduServes(session).then((serves) {
        for (LadduServe serve in serves) {
          available -= CalculateTotalLadduPacksServed(serve);
        }
      });
    }

    // return if low stock
    if (available < _totalLadduPacks) {
      Toaster().error('Not enough stock');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    List<Map<String, int>> packsPushpanjali = [];
    List<Map<String, int>> packsOtherSeva = [];
    List<Map<String, int>> packsMisc = [];

    List<int?> pushpanjaliTickets =
        _pushpanjaliTickets.map((e) => e['amount']).toList();

    // pushpanjali
    for (int i = 0; i < _controllersPushpanjali.length; i++) {
      if (_controllersPushpanjali[i].text.isEmpty) {
        packsPushpanjali.add({pushpanjaliTickets[i]!.toString(): 0});
        continue;
      }
      packsPushpanjali.add({
        pushpanjaliTickets[i]!.toString():
            int.tryParse(_controllersPushpanjali[i].text)! *
                _pushpanjaliTickets[i]['ladduPacks']!
      });
    }

    // other sevas
    for (int i = 0; i < _controllersOtherSeva.length; i++) {
      // no entries
      if (_controllersOtherSeva[i].text.isEmpty) {
        packsOtherSeva.add({_otherSevaTickets[i]['name']: 0});
        continue;
      }

      // add entries
      int mul = _otherSevaTickets[i]['ladduPacks']!;
      packsOtherSeva.add({
        _otherSevaTickets[i]['name']:
            int.tryParse(_controllersOtherSeva[i].text)! * mul
      });
    }

    // misc
    for (int i = 0; i < _controllerMisc.length; i++) {
      packsMisc.add({_misc[i]: int.tryParse(_controllerMisc[i].text) ?? 0});
    }

    // calculate balance
    int totalProcured = 0;
    int totalServed = 0;
    DateTime session = await FBL().readLatestLadduSession();
    await FBL().readLadduStocks(session).then((stocks) {
      for (LadduStock stock in stocks) {
        totalProcured += stock.count;
      }
    });
    await FBL().readLadduServes(session).then((serves) {
      for (LadduServe serve in serves) {
        totalServed += CalculateTotalLadduPacksServed(serve);
      }
    });
    if (widget.serve != null) {
      // in edit mode, remove the previous serve count
      totalServed -= CalculateTotalLadduPacksServed(widget.serve!);
    }
    totalServed += _totalLadduPacks;

    DateTime now = DateTime.now();
    if (widget.serve != null) {
      now = widget.serve!.timestamp;
    }
    String username = Utils().getUsername();
    LadduServe ladduServe = LadduServe(
      timestamp: now,
      user: username,
      packsPushpanjali: packsPushpanjali,
      packsOtherSeva: packsOtherSeva,
      packsMisc: packsMisc,
      note: _controllerNote.text,
      title: _controllerTitle.text,
      balance: totalProcured - totalServed,
      pushpanjaliSlot: widget.slot!.timestamp,
      available: available,
    );

    if (widget.serve != null) {
      await FBL().editLadduServe(session, ladduServe);
    } else {
      await FBL().addLadduServe(session, ladduServe);
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context);
    if (widget.serve == null) {
      Navigator.pop(context);
    }
  }

  Future<bool?> _createConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Are you sure you want to delete?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Serve laddu'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            // title
            Padding(
              padding: const EdgeInsets.all(
                  8.0), // Adjust the padding value as needed
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Seva slot',
                ),
                controller: _controllerTitle,
              ),
            ),

            // table of entries
            _createTable(),

            SizedBox(height: 16.0), // Add space between children

            // total laddu packs
            Text(
              "Total laddu packs = $_totalLadduPacks",
              style: TextStyle(
                fontSize: 20.0, // Increase the font size
                fontWeight: FontWeight.bold, // Make the text bold
              ),
              textAlign: TextAlign.center, // Center the text
            ),

            SizedBox(height: 16.0), // Add space between children

            // note
            TextField(
              onChanged: (value) {
                // Handle the changes in the text field
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                hintText: 'Enter a note', // Add a hint text to the text field
              ),
              controller: _controllerNote,
            ),

            SizedBox(height: 16.0), // Add space between children

            // serve button
            ElevatedButton(
              onPressed: _isLoading ? null : _onpressServe,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text(widget.serve != null ? 'Update' : 'Serve'),
            ),

            // delete button
            SizedBox(height: 16.0),
            if (widget.serve != null)
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        bool? confirm = await _createConfirmDialog();

                        if (confirm == true) {
                          setState(() {
                            _isLoading = true;
                          });

                          DateTime session =
                              await FBL().readLatestLadduSession();
                          await FBL().deleteLadduServe(session, widget.serve!);

                          setState(() {
                            _isLoading = false;
                          });

                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.red, // Set the background color to red
                ),
                child:
                    _isLoading ? CircularProgressIndicator() : Text('Delete'),
              ),

            // leave some gaps at the bottom
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
