import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TicketSettings extends StatefulWidget {
  final String title;
  final String? splashImage;

  const TicketSettings({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _TicketSettingsState createState() => _TicketSettingsState();
}

class _TicketSettingsState extends State<TicketSettings> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  Map<String, dynamic> _ticketSettings = {};

  // lists
  final Map<String, TextEditingController> _controllerBookNumbers = {};
  final Map<String, TextEditingController> _controllerTicketNumbers = {};
  List<Map<String, dynamic>> _ticketHistory = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _ticketSettings.clear();
    _ticketHistory.clear();

    // clear all controllers and focus nodes
    for (var controller in _controllerTicketNumbers.values) {
      controller.dispose();
    }
    for (var controller in _controllerBookNumbers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here
      String ticketNumbersPath =
          "${Const().dbrootGaruda}/NityaSeva/NextTicketNumbers";
      _ticketSettings =
          await FB().getJson(path: ticketNumbersPath, silent: true);

      // first time use
      if (_ticketSettings.isEmpty) {
        for (var amount in Const().nityaSeva['amounts']!) {
          String key = amount.keys.first;
          if (amount[key]?['obsolete'] == true) {
            continue; // skip obsolete amounts
          }
          _ticketSettings[key] = "1:1"; // default value
        }
      }

      // sort _ticketSettings by amount
      _ticketSettings = Map.fromEntries(
        _ticketSettings.entries.toList()
          ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key))),
      );

      // populate history
      String historyPath =
          "${Const().dbrootGaruda}/NityaSeva/NextTicketNumbersAdminHistory";
      List historyListRaw = await FB().getList(
        path: historyPath,
      );
      _ticketHistory = historyListRaw
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList()
        ..sort((a, b) => DateTime.parse(b['timestamp'])
            .compareTo(DateTime.parse(a['timestamp'])));
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createHistoryTile(int index) {
    String datetimeFormatted = DateFormat("dd/MM/yyyy HH:mm")
        .format(DateTime.parse(_ticketHistory[index]['timestamp']));

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
          title: Text(
            "${_ticketHistory[index]['user']} - $datetimeFormatted",
          ),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "Note: ${_ticketHistory[index]['note']}",
            ),
            Text(
              "Ticket numbers: ${_ticketHistory[index]['ticketNumbers'].toString()}",
            ),
          ])),
    );
  }

  Widget _createTicketSettingRow(int index) {
    String key = _ticketSettings.keys.elementAt(index);
    String value = _ticketSettings[key] ?? "1:1";

    int labelWidth = 4;

    _controllerBookNumbers[key] =
        TextEditingController(text: value.split(":").first.trim());
    _controllerTicketNumbers[key] =
        TextEditingController(text: value.split(":").last.trim());

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            flex: labelWidth,
            child: Text(
              "Amount: ₹$key",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          // book
          SizedBox(width: 5),
          Expanded(
            flex: ((10 - labelWidth) / 2).round(),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Book",
              ),
              controller: _controllerBookNumbers[key],
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // hack: two variables are holding the same values - _ticketSettings and _controllerBookNumbers
                // following hack is to update both at the same time
                _ticketSettings[key] =
                    "${value.trim()}:${_controllerTicketNumbers[key]!.text.trim()}";
              },
            ),
          ),

          // ticket
          SizedBox(width: 5),
          Expanded(
            flex: ((10 - labelWidth) / 2).round(),
            child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Ticket",
                ),
                controller: _controllerTicketNumbers[key],
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  // hack: two variables are holding the same values - _ticketSettings and _controllerBookNumbers
                  // following hack is to update both at the same time
                  _ticketSettings[key] =
                      "${_controllerBookNumbers[key]!.text.trim()}:$value";
                }),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    String note = "";

    await Widgets().showResponsiveDialog(
      context: context,
      child: TextField(
        autofocus: true,
        onChanged: (value) => note = value,
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            // validate input
            if (note.trim().isEmpty) {
              Toaster().error("Please enter some remarks");
              return;
            }

            // save the ticket numbers
            Map<String, dynamic> ticketNumbers = {};
            for (var entry in _controllerTicketNumbers.entries) {
              String key = entry.key;
              int book = int.parse(_controllerBookNumbers[key]!.text.trim());
              int ticket = int.parse(entry.value.text.trim());
              ticketNumbers[key] = "$book:$ticket";
            }

            // push to fb
            String ticketNumbersPath =
                "${Const().dbrootGaruda}/NityaSeva/NextTicketNumbers";
            await FB().setJson(path: ticketNumbersPath, json: ticketNumbers);

            // save history
            String historyPath =
                "${Const().dbrootGaruda}/NityaSeva/NextTicketNumbersAdminHistory";
            UserBasics? user = await Utils().fetchOrGetUserBasics();
            await FB().addToList(listpath: historyPath, data: {
              "user": user?.name ?? "Unknown User",
              "timestamp": DateTime.now().toIso8601String(),
              "ticketNumbers": ticketNumbers,
              "note": note,
            });

            Navigator.of(context).pop(); // close the dialog
            Toaster().info("Saved successfully");
          },
          child: Text("OK"),
        )
      ],
      title: "Enter some remarks",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    children: [
                      // leave some space at top
                      SizedBox(height: 10),

                      // main entry field
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Next ticket numbers",
                        child: Column(
                          children: [
                            // amount rows
                            ...List.generate(_ticketSettings.length,
                                (index) => _createTicketSettingRow(index)),

                            // save button
                            Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                    onPressed: _onSave, child: Text("Save"))),
                          ],
                        ),
                      ),

                      // history
                      Widgets().createTopLevelCard(
                          context: context,
                          title: "History",
                          child: Column(
                            children: [
                              ...List.generate(_ticketHistory.length,
                                  (index) => _createHistoryTile(index))
                            ],
                          )),

                      // leave some space at bottom
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
