import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TicketSettingsPage extends StatefulWidget {
  final String title;
  final String? splashImage;

  const TicketSettingsPage({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _TicketSettingsPageState createState() => _TicketSettingsPageState();
}

class _TicketSettingsPageState extends State<TicketSettingsPage> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  Map<String, dynamic> _ticketSettings = {};

  // lists
  final Map<String, TextEditingController> _controllerTicketNumbers = {};

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes
    for (var controller in _controllerTicketNumbers.values) {
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
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createTicketSettingRow(int index) {
    String key = _ticketSettings.keys.elementAt(index);
    int value = _ticketSettings[key] ?? 1;

    int labelWidth = 4;
    _controllerTicketNumbers[key] =
        TextEditingController(text: value.toString());

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // label - occupies 30% of the available width
          Expanded(
            flex: labelWidth,
            child: Text(
              "Amount: ₹$key",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),

          // input field
          SizedBox(width: 10),
          Expanded(
            flex: 10 - labelWidth,
            child: TextField(
              controller: _controllerTicketNumbers[key],
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
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

                      // your widgets here
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
                                    child: Text("Save"),
                                    onPressed: () async {
                                      // save the ticket numbers
                                      Map<String, dynamic> ticketNumbers = {};
                                      for (var entry
                                          in _controllerTicketNumbers.entries) {
                                        String key = entry.key;
                                        int value =
                                            int.parse(entry.value.text.trim());
                                        ticketNumbers[key] = value;
                                      }

                                      // push to fb
                                      String ticketNumbersPath =
                                          "${Const().dbrootGaruda}/NityaSeva/NextTicketNumbers";
                                      await FB().setJson(
                                          path: ticketNumbersPath,
                                          json: ticketNumbers);

                                      Toaster().info("Saved successfully");
                                    })),
                          ],
                        ),
                      ),

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
