import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final List<Ticket> _tickets = [
    Ticket(
        timestamp: DateTime.now(),
        amount: 400,
        mode: "UPI",
        ticketNumber: 2143,
        user: "Guest",
        seva: "Pushpanjali Seva",
        remarks: "",
        image: 'assets/images/LauncherIcons/NityaSeva.png'),
    Ticket(
        timestamp: DateTime.now(),
        amount: 400,
        mode: "UPI",
        ticketNumber: 2143,
        user: "Guest",
        seva: "Pushpanjali Seva",
        remarks: "",
        image: 'assets/images/LauncherIcons/NityaSeva.png'),
  ];

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

  Widget _createTicketTile(int sl, Ticket ticket) {
    double sizeOfContainer = 75;
    String time = DateFormat("HH:mm").format(ticket.timestamp);

    return Row(
      children: [
        // left badge
        Container(
          color: primaryColor,
          child: SizedBox(
            height: sizeOfContainer,
            width: sizeOfContainer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // serial number
                Text(sl.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge!
                        .copyWith(color: backgroundColor)),

                // ticket number
                Text("#${ticket.ticketNumber}",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: backgroundColor)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: sizeOfContainer,
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // seva name headline
                          Text(ticket.seva,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(color: primaryColor)),

                          // other details
                          SizedBox(height: 2),
                          Text(
                            "${ticket.user}, Time: $time, Amount: ${ticket.amount} - ${ticket.mode}",
                            style: Theme.of(context).textTheme.bodySmall,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // right side image
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 1),
                    ),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(
                        ticket.image,
                      ),
                      radius: sizeOfContainer / 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Stack(
        children: [
          Scaffold(
            // app bar
            appBar: AppBar(
              title: Text(widget.session.name),
              actions: [
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
              child: ListView.builder(
                itemCount: _tickets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _createTicketTile(
                        _tickets.length - index, _tickets[index]),
                  );
                },
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

class Ticket {
  final DateTime timestamp;
  final int amount;
  final String mode;
  final int ticketNumber;
  final String user;
  final String remarks;
  final String image;
  final String seva;

  Ticket(
      {required this.timestamp,
      required this.amount,
      required this.mode,
      required this.ticketNumber,
      required this.user,
      required this.remarks,
      required this.image,
      required this.seva});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      timestamp: DateTime.parse(json['timestamp']),
      amount: json['amount'],
      mode: json['mode'],
      ticketNumber: json['ticketNumber'],
      user: json['user'],
      remarks: json['remarks'],
      image: json['image'],
      seva: json['seva'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'mode': mode,
      'ticketNumber': ticketNumber,
      'user': user,
      'remarks': remarks,
      'image': image,
      'seva': seva,
    };
  }
}
