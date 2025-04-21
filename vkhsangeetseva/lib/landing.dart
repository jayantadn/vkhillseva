import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class LandingPage extends StatefulWidget {
  final String title;

  const LandingPage({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  bool _isChecked = false;

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

    // perform async operations here

    await _lock.synchronized(() async {
      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(onPressed: () {}, icon: Icon(Icons.access_alarm))
            ],
          ),
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
                      Card(
                        child: ListTile(
                          title: const Text("Sangeet Seva"),
                          subtitle: Column(
                            children: [
                              const TextField(
                                decoration: InputDecoration(
                                  labelText: "Enter your name",
                                  hintText: "Name",
                                ),
                              ),
                              ElevatedButton(
                                  onPressed: () {
                                    // nothing to do
                                  },
                                  child: const Text("Submit")),
                              OutlinedButton(
                                  onPressed: () {
                                    // nothing to do
                                  },
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () {
                                    // nothing to do
                                  },
                                  child: const Text("Delete")),
                            ],
                          ),
                          leading: const Icon(Icons.music_note),
                          trailing: Utils().createContextMenu(
                              ["Edit", "Delete"], (value) {}),
                        ),
                      ),
                      CheckboxListTile(
                        title:
                            const Text("I agree to the terms and conditions"),
                        value: _isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isChecked = value ?? false;
                          });
                        },
                      ),

                      // leave some space at bottom
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // nothing to do
            },
            child: const Icon(Icons.add),
          ),
        ),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(
            image: "assets/images/Logo/SangeetSeva.png",
          ),
      ],
    );
  }
}
