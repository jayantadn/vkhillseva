import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

class HarinaamSettings extends StatefulWidget {
  final String title;
  final String? splashImage;

  const HarinaamSettings({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _HarinaamSettingsState createState() => _HarinaamSettingsState();
}

class _HarinaamSettingsState extends State<HarinaamSettings> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists
  final List<Japamala> _japamalas = [
    Japamala(name: "Neem mala", saleValue: 20, colorHex: "0000FF"),
    Japamala(name: "Tulsi mala", saleValue: 25, colorHex: "FF0000"),
  ];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps
    _japamalas.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createJapamalaCard(int index) {
    return SizedBox(
      width: 200, // Fixed width for each item to avoid exception
      child: Card(
        color: Theme.of(context).colorScheme.secondary,
        child: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: ListTile(
              // color
              leading: SizedBox(
                width: 20,
                height: 20,
                child: CircleAvatar(
                  backgroundColor:
                      Color(int.parse("0xff${_japamalas[index].colorHex}")),
                  radius: 25,
                ),
              ),

              // mala amount
              title: Text(_japamalas[index].name),
              subtitle: Text(
                "Sale value: ₹${_japamalas[index].saleValue}",
              ),

              // context menu
              trailing: Widgets().createContextMenu(["Edit", "Delete"],
                  (actionString) {
                if (actionString == "Edit") {
                  // Handle edit action
                } else if (actionString == "Delete") {
                  // Handle delete action
                }
              })),
        ),
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
                        title: "Japamala sale value",
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              children: List.generate(_japamalas.length,
                                  (index) => _createJapamalaCard(index))),
                        ),
                      ),

                      // leave some space at bottom
                      SizedBox(height: 500),
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
