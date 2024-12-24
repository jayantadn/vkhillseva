import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vkhillseva/nitya_seva/session.dart';
import 'package:vkhillseva/widgets/common_widgets.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';

class TicketPage extends StatefulWidget {
  final Session session;

  const TicketPage({super.key, required this.session});

  @override
  _TicketPageState createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  bool _isLoading = true;
  final DateTime _selectedDate = DateTime.now();

  // lists

  // controllers, listeners and focus nodes
  final List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes
    for (var listener in _listeners) {
      listener.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double sizeOfContainer = 75;

    return Theme(
      data: themeDefault,
      child: Stack(
        children: [
          Scaffold(
            // app bar
            appBar: AppBar(
              title: Text(widget.session.name),
              actions: [
                // TAS
                IconButton(
                  icon: Icon(Icons.eco),
                  onPressed: () {
                    // navigate to add ticket page
                  },
                ),

                // laddu seva
                IconButton(
                  icon: Icon(Icons.circle),
                  onPressed: () {
                    // navigate to add ticket page
                  },
                ),

                // summary button
                IconButton(
                  icon: Icon(Icons.summarize),
                  onPressed: () {},
                ),

                // menu button
                CommonWidgets().createPopupMenu([
                  // tally cash button
                  MyPopupMenuItem(
                      text: "Tally cash",
                      icon: Icons.money,
                      onPressed: () {
                        print("Tally cash");
                      }),

                  // tally UPI button
                  MyPopupMenuItem(
                      text: "Tally UPI",
                      icon: Icons.payment,
                      onPressed: () {
                        print("Tally UPI");
                      }),
                ]),
              ],
            ),

            // body
            body: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                children: [
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // left badge
                          Container(
                            color: primaryColor,
                            child: SizedBox(
                              height: sizeOfContainer,
                              width: sizeOfContainer * 0.75,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // serial number
                                  Text("1",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge!
                                          .copyWith(color: backgroundColor)),

                                  // ticket number
                                  Text("#2143",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(color: backgroundColor)),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            // right side container
                            child: Container(
                              height: sizeOfContainer,
                              decoration: BoxDecoration(
                                border: Border.all(color: primaryColor),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // seva name headline
                                          Text("Pushpanjali Seva",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall!
                                                  .copyWith(
                                                      color: primaryColor)),

                                          // other details
                                          Text(
                                            "Guest Sevakarta, Time: 10:00, Amt: ₹400, UPI",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          )
                                        ],
                                      ),
                                    ),

                                    // right side image
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: primaryColor, width: 2),
                                      ),
                                      child: CircleAvatar(
                                        backgroundImage: AssetImage(
                                            'assets/images/LauncherIcons/NityaSeva.png'),
                                        radius: sizeOfContainer / 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),

            // floating action button
            floatingActionButton: FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                // navigate to add ticket page
              },
            ),
          ),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(
                image: 'assets/images/Logo/KrishnaLilaPark_square.png')
        ],
      ),
    );
  }
}
