import 'package:flutter/material.dart';
import 'package:vkhpackages/vkhpackages.dart';

class LadduSettings extends StatefulWidget {
  const LadduSettings({super.key});

  @override
  _LadduSettingsState createState() => _LadduSettingsState();
}

class _LadduSettingsState extends State<LadduSettings> {
  List<TextEditingController> _controllersPushpanjali = [];
  List<TextEditingController> _controllersOtherSeva = [];

  bool _isLoading = true;

  final List<Map<String, int>> _pushpanjaliTickets = [
    // do not delete the default values
    {'amount': 500, 'ladduPacks': 1},
    {'amount': 600, 'ladduPacks': 1},
    {'amount': 1000, 'ladduPacks': 2},
    {'amount': 2500, 'ladduPacks': 3},
  ];

  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _otherSevaTickets = [
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
      pushpanjaliTickets.add(int.parse(amountMap.keys.first));
    }
    // List<int?> pushpanjaliTickets =
    // _pushpanjaliTickets.map((e) => e['amount']).toList();

    // default populate the controllers
    _controllersPushpanjali = List.generate(
        pushpanjaliTickets.length, (index) => TextEditingController());
    _controllersOtherSeva = List.generate(
        _otherSevaTickets.length, (index) => TextEditingController());

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

    // assuming that all sequences are correct
    setState(() {
      // controllers for pushpanjali
      for (int i = 0; i < _pushpanjaliTickets.length; i++) {
        int multiplier = _pushpanjaliTickets[i]['ladduPacks']!;
        _controllersPushpanjali[i].text = multiplier.toString();
      }

      // controllers for other seva
      for (int i = 0; i < _otherSevaTickets.length; i++) {
        int multiplier = _otherSevaTickets[i]['ladduPacks']!;
        _controllersOtherSeva[i].text = multiplier.toString();
      }

      _isLoading = false;
    });
  }

  Widget _createTable() {
    List<int?> pushpanjaliTickets =
        _pushpanjaliTickets.map((e) => e['amount']).toList();

    return Table(
      columnWidths: {
        0: FixedColumnWidth(150.0),
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
                    'Laddu packs',
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
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 8.0),
                      ),
                    ),
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
                      textAlign: TextAlign.center,
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
            ],
          ),
      ],
    );
  }

  void _onpressSave() {
    // controllers for pushpanjali
    for (int i = 0; i < _pushpanjaliTickets.length; i++) {
      _pushpanjaliTickets[i]['ladduPacks'] =
          _controllersPushpanjali[i].text.isEmpty
              ? 0
              : int.parse(_controllersPushpanjali[i].text);
    }

    // controllers for other seva
    for (int i = 0; i < _otherSevaTickets.length; i++) {
      _otherSevaTickets[i]['ladduPacks'] = _controllersOtherSeva[i].text.isEmpty
          ? 0
          : int.parse(_controllersOtherSeva[i].text);
    }

    FB().setValue(
        path:
            "${Const().dbrootGaruda}/Settings/LadduDistribution/LadduPackMultiplier/Pushpanjali",
        value: _pushpanjaliTickets);
    FB().setValue(
        path:
            "${Const().dbrootGaruda}/Settings/LadduDistribution/LadduPackMultiplier/OtherSevas",
        value: _otherSevaTickets);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laddu Pack Settings'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            // table of entries
            _createTable(),

            // serve button
            ElevatedButton(
              onPressed: _isLoading ? null : _onpressSave,
              child: _isLoading ? CircularProgressIndicator() : Text('Save'),
            ),

            // leave some gaps at the bottom
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
