import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhillseva/common/const.dart';
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
        note: "",
        image: 'assets/images/LauncherIcons/NityaSeva.png'),
    Ticket(
        timestamp: DateTime.now().add(Duration(minutes: 5)),
        amount: 400,
        mode: "UPI",
        ticketNumber: 2144,
        user: "Guest",
        seva: "Pushpanjali Seva",
        note: "",
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
      _tickets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

  List<String> _getSevaNames(int amount) {
    List<String> ret = [];

    for (var seva in Const().nityaSeva['amounts']!) {
      if (seva.keys.first == amount.toString()) {
        List sevas = seva.values.first['sevas'] as List;
        for (var seva in sevas) {
          ret.add(seva['name']);
        }
      }
    }

    return ret;
  }

  void _createAddEditDialog(context) {
    // locals
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    int amount = widget.session.defaultAmount;
    int ticketNumber = 0;
    String mode = widget.session.defaultPaymentMode;

    // lists
    List<String> sevaNames = [];
    List<Ticket> filteredTickets =
        _tickets.where((ticket) => ticket.amount == amount).toList();

    // controllers
    TextEditingController ticketNumberController = TextEditingController();

    // field values
    if (filteredTickets.isNotEmpty) {
      ticketNumber = filteredTickets.first.ticketNumber + 1;
    }
    ticketNumberController.text = ticketNumber.toString();
    sevaNames = _getSevaNames(amount);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Ticket number
              SizedBox(height: 10),
              TextField(
                controller: ticketNumberController,
                decoration: InputDecoration(labelText: "Ticket Number"),
              ),

              // Seva amount
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Seva Amount",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: accentColor),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...Const().nityaSeva['amounts']!.map((seva) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              amount = int.parse(seva.keys.first);
                              filteredTickets = _tickets
                                  .where((ticket) => ticket.amount == amount)
                                  .toList();
                              ticketNumberController.text = (filteredTickets
                                          .isNotEmpty
                                      ? filteredTickets.first.ticketNumber + 1
                                      : 0)
                                  .toString();
                              sevaNames = _getSevaNames(amount);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: amount.toString() == seva.keys.first
                                  ? seva.values.first['color']! as Color
                                  : Colors.transparent,
                              border: Border.all(
                                  color: seva.values.first['color']! as Color),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                seva.keys.first,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                        color:
                                            amount.toString() == seva.keys.first
                                                ? Colors.white
                                                : primaryColor),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Payment mode
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Payment Mode",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: accentColor),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...Const().paymentModes.keys.map((m) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: primaryColor),
                            color:
                                mode == m ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image.asset(
                                      Const().paymentModes[m]!['icon']!),
                                ),
                                Text(
                                  m,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                        color: mode == m
                                            ? Colors.white
                                            : primaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // seva name
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Seva Name",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: accentColor),
                ),
              ),
              DropdownButton<String>(
                isExpanded: true,
                value: sevaNames.isNotEmpty ? sevaNames[0] : null,
                items: sevaNames.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    // Handle the selected value
                  });
                },
                hint: Text(
                  "Select Seva",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              // buttons
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      // clear all lists
                      sevaNames.clear();
                      filteredTickets.clear();

                      // dispose all controllers and focus nodes
                      ticketNumberController.dispose();
                    },
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      // clear all lists
                      sevaNames.clear();
                      filteredTickets.clear();

                      // dispose all controllers and focus nodes
                    },
                    child: Text("Add"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
                _createAddEditDialog(context);
              },
            ),
          ),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(image: 'assets/images/LauncherIcons/NityaSeva.png')
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
  final String note;
  final String image;
  final String seva;

  Ticket(
      {required this.timestamp,
      required this.amount,
      required this.mode,
      required this.ticketNumber,
      required this.user,
      required this.note,
      required this.image,
      required this.seva});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      timestamp: DateTime.parse(json['timestamp']),
      amount: json['amount'],
      mode: json['mode'],
      ticketNumber: json['ticketNumber'],
      user: json['user'],
      note: json['note'],
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
      'note': note,
      'image': image,
      'seva': seva,
    };
  }
}
