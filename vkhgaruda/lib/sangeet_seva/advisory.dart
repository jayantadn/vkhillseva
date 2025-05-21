import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Advisory extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Advisory({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _AdvisoryState createState() => _AdvisoryState();
}

class _AdvisoryState extends State<Advisory> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists
  final List<String> _advisories = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _advisories.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // populate the list of advisories
      _advisories.clear();
      List<dynamic> result = await FB()
          .getList(path: "${Const().dbrootSangeetSeva}/Settings/Advisory");
      _advisories.addAll(result.whereType<String>());
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _onAdd() async {}

  Future<void> _onDelete(int index) async {}

  Future<void> _onEdit(int index) async {
    final TextEditingController controller =
        TextEditingController(text: _advisories[index]);

    Widgets().showResponsiveDialog(
        context: context,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "Advisory",
            hintText: "Enter advisory",
          ),
          autofocus: true,
          maxLines: 4,
        ),
        actions: [
          TextButton(
              onPressed: () async {
                setState(() {
                  _advisories[index] = controller.text;
                });

                Navigator.of(context).pop();

                await FB().setValue(
                    path: "${Const().dbrootSangeetSeva}/Settings/Advisory",
                    value: _advisories);
              },
              child: Text("Save"))
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
                      ...List.generate(
                        _advisories.length,
                        (index) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Widgets().createTopLevelCard(
                            context: context,
                            child: ListTile(
                              title: Text(_advisories[index]),
                              leading: Text("${index + 1}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              trailing: Widgets().createContextMenu(
                                  ["Edit", "Delete"], (String command) {
                                if (command == "Edit") {
                                  _onEdit(index);
                                } else if (command == "Delete") {
                                  _onDelete(index);
                                }
                              }),
                            ),
                          ),
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
