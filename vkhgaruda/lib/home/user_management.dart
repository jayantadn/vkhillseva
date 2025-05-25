import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class UserManagement extends StatefulWidget {
  final String title;
  final String? splashImage;

  const UserManagement({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists

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
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(children: [
                            // dropdown for category
                            SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: DropdownButton<String>(
                                  onChanged: (value) {},
                                  value: null,
                                  hint: const Text('Select an option',
                                      textAlign: TextAlign.center),
                                  isExpanded: true,
                                  alignment: Alignment.center,
                                  items: <String>[
                                    'Option 1',
                                    'Option 2',
                                    'Option 3'
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Center(
                                          child: Text(value,
                                              textAlign: TextAlign.center)),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                            Row(
                              children: [
                                // mobile number field
                                Expanded(
                                  flex: 8,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Enter mobile number',
                                    ),
                                    keyboardType: TextInputType.phone,
                                    onChanged: (value) {},
                                  ),
                                ),

                                // circular add button
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Material(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary, // dark background
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        icon: Icon(Icons.add,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary), // white icon
                                        onPressed: () {
                                          // add user logic
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ]),
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
