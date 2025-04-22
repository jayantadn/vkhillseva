import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/widgets/next_avl_slot.dart';

class SlotSelection extends StatefulWidget {
  final String title;

  const SlotSelection({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _SlotSelectionState createState() => _SlotSelectionState();
}

class _SlotSelectionState extends State<SlotSelection> {
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

                      Widgets().createResponsiveTopLevelContainer(context, [
                        // your widgets here
                        Widgets().createTopLevelCard(
                            context,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Next available slot:"),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    NextAvlSlot(key: nextavlslotKey),
                                    const SizedBox(width: 10),
                                    IconButton(
                                        onPressed: () {},
                                        icon: Icon(Icons.calendar_month))
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                      onPressed: () {},
                                      child: Text("Select slot")),
                                ),
                              ],
                            )),
                      ]),

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
            image: "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
