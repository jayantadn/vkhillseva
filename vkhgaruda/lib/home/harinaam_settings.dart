import 'dart:async';

import 'package:flutter/material.dart';
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
  final List<Japamala> _japamalas = [];

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
      _japamalas.clear();
      String dbpath = "${Const().dbrootGaruda}/Settings/Harinaam/Japamalas";
      List japamalasRaw = await FB().getList(path: dbpath);
      for (var japamalaRaw in japamalasRaw) {
        Japamala japamala =
            Utils().convertRawToDatatype(japamalaRaw, Japamala.fromJson);
        _japamalas.add(japamala);
      }
      _japamalas.sort((a, b) => b.saleValue.compareTo(a.saleValue));
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addNewJapamala(Japamala japamala) async {
    // Add the new japamala to the list
    _japamalas.add(japamala);

    // Sort the list by sale value in descending order
    _japamalas.sort((a, b) => b.saleValue.compareTo(a.saleValue));

    // store to database
    String dbpath = "${Const().dbrootGaruda}/Settings/Harinaam/Japamalas";
    await FB().setList(
      path: dbpath,
      list: _japamalas,
      toJson: (p0) => p0.toJson(),
    );

    // Refresh the UI
    setState(() {});
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
              trailing: Widgets().createContextMenu(
                  items: ["Edit", "Delete"],
                  onPressed: (actionString) {
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

  Future<void> _showNewJapamalaDialog() async {
    TextEditingController japamalaNameController = TextEditingController();
    TextEditingController saleValueController = TextEditingController();

    String selectedColorHex =
        Utils().getRandomDarkColor().value.toRadixString(16).padLeft(8, '0');

    final formKey = GlobalKey<FormState>();

    Widgets().showResponsiveDialog(
        context: context,
        child: Widgets().createTopLevelCard(
            context: context,
            title: "Add new japamala",
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // japamala name
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Japamala name",
                      hintText: "e.g. Basic neem mala",
                    ),
                    controller: japamalaNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a japamala name";
                      }
                      return null;
                    },
                  ),

                  Row(
                    children: [
                      // sale value
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: "Sale value in Rupees",
                            hintText: "e.g. 20",
                          ),
                          controller: saleValueController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter a sale value";
                            }
                            final intValue = int.tryParse(value);
                            if (intValue == null || intValue <= 0) {
                              return "Please enter a valid positive number";
                            }
                            return null;
                          },
                        ),
                      ),

                      // color picker
                      Widgets().showColorpicker(
                          context: context,
                          initialColorHex: selectedColorHex,
                          onColorSelected: (String colorHex) {
                            selectedColorHex = colorHex;
                          }),
                    ],
                  )
                ],
              ),
            )),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Japamala newJapamala = Japamala(
                  name: japamalaNameController.text,
                  saleValue: int.parse(saleValueController.text),
                  colorHex: selectedColorHex,
                );

                _addNewJapamala(newJapamala);

                // Close the dialog
                Navigator.of(context).pop();
              }
            },
            child: const Text("Add"),
          ),
        ]);
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
                            children: [
                              // add new japamala button
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _showNewJapamalaDialog,
                              ),

                              // card for each japamala
                              ...List.generate(_japamalas.length,
                                  (index) => _createJapamalaCard(index)),
                            ],
                          ),
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
            image: widget.splashImage,
          ),
      ],
    );
  }
}
