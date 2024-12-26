import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/common/fb.dart';
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
  // locals
  bool _isLoading = true;
  DateTime _lastCallbackInvoked = DateTime.now();

  // lists
  final List<Ticket> _tickets = [];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    String dbDate = DateFormat('yyyy-MM-dd').format(widget.session.timestamp);
    String sessionKey =
        widget.session.timestamp.toIso8601String().replaceAll(".", "^");
    FB().listenForChange(
        "NityaSeva/$dbDate/$sessionKey/Tickets",
        FBCallbacks(
          // add
          add: (data) {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              print(data);
            }
          },

          // edit
          edit: () {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              refresh();
            }
          },

          // delete
          delete: (data) {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();
            }
          },

          // get listeners
          getListeners: (listeners) {
            _listeners = listeners;
          },
        ));

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

    // fetch tickets
    _tickets.clear();
    String dbDate = DateFormat("yyyy-MM-dd").format(widget.session.timestamp);
    String dbSession =
        widget.session.timestamp.toIso8601String().replaceAll(".", "^");
    List ticketsJson =
        await FB().getList(path: "NityaSeva/$dbDate/$dbSession/Tickets");
    for (var t in ticketsJson) {
      Map<String, dynamic> ticket = Map<String, dynamic>.from(t);
      _tickets.add(Ticket.fromJson(ticket));
    }

    setState(() {
      _tickets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _isLoading = false;
    });
  }

  Widget _createTicketTile(int sl, Ticket ticket) {
    double sizeOfContainer = 75;
    String time = DateFormat("HH:mm").format(ticket.timestamp);

    Color color = Const()
        .nityaSeva['amounts']!
        .firstWhere((element) => element.keys.first == ticket.amount.toString())
        .values
        .first['color']! as Color;

    return Row(
      children: [
        // left badge
        Container(
          color: color,
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
              border: Border.all(color: color),
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
                          Row(
                            children: [
                              // seva name headline
                              Text(ticket.seva,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(color: primaryColor)),

                              // note icon
                              SizedBox(width: 4),
                              if (ticket.note.isNotEmpty)
                                Icon(Icons.note,
                                    color: Colors.orange, size: 16),
                            ],
                          ),

                          // other details
                          SizedBox(height: 2),
                          Text(
                            "${ticket.user}, Time: $time, Amount: ${ticket.amount} - ${ticket.mode}",
                            style: Theme.of(context).textTheme.bodySmall,
                            softWrap: true,
                          ),

                          // note
                          if (ticket.note.isNotEmpty)
                            Text(
                              "Note: ${ticket.note}",
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

  List<String> _prevalidateTicket(Ticket ticket) {
    List<String> errors = [];
    List<Ticket> filteredTickets =
        _tickets.where((t) => t.amount == ticket.amount).toList();

    // check if ticket number is > 0
    if (ticket.ticketNumber <= 0) {
      errors.add("Ticket number should be greater than 0");
    }

    // check if ticket number is unique
    if (filteredTickets
        .where((t) => t.ticketNumber == ticket.ticketNumber)
        .isNotEmpty) {
      errors.add("Ticket number already exists");
    }

    // check if ticket number is contiguous
    if (filteredTickets.isNotEmpty && filteredTickets.length > 1) {
      if (ticket.ticketNumber - filteredTickets.first.ticketNumber != 1) {
        errors.add("Ticket number should be contiguous");
      }
    }

    return errors;
  }

  Future<List<String>> _postvalidateTicket() async {
    List<String> errors = [];

    await refresh();

    // create a map of tickets as per amount
    Map<int, List<Ticket>> ticketsMap = {};
    for (var ticket in _tickets) {
      if (!ticketsMap.containsKey(ticket.amount)) {
        ticketsMap[ticket.amount] = [];
      }
      ticketsMap[ticket.amount]!.add(ticket);
    }

    // check if ticket numbers are unique
    if (_tickets.length != _tickets.toSet().length) {
      errors.add("Duplicate ticket numbers found");
    }

    // check for each key, whether the list of tickets have contiguous numbers
    ticketsMap.forEach((amount, tickets) {
      tickets.sort((a, b) => a.ticketNumber.compareTo(b.ticketNumber));
      for (int i = 0; i < tickets.length - 1; i++) {
        if (tickets[i + 1].ticketNumber - tickets[i].ticketNumber != 1) {
          errors.add("Ticket numbers for amount $amount are not contiguous");
          break;
        }
      }
    });

    // check if ticket is created in the correct session
    String dbDate = DateFormat("yyyy-MM-dd").format(DateTime.now());
    var sessions = await FB().getList(path: "NityaSeva/$dbDate");
    if (sessions.isEmpty) {
      errors.add("No sessions found for today");
    } else {
      DateTime lastSession =
          DateTime.parse(sessions.last['Settings']['timestamp']);
      if (lastSession != widget.session.timestamp) {
        errors.add("Ticket created in wrong session");
      }
    }

    return errors;
  }

  void _deleteTicket(Ticket ticket) {}

  void _addEditTicket(context) {
    // locals
    int amount = widget.session.defaultAmount;
    int ticketNumber = 0;
    String mode = widget.session.defaultPaymentMode;
    String sevaName = "";

    // lists
    List<String> sevaNames = [];
    List<Ticket> filteredTickets =
        _tickets.where((ticket) => ticket.amount == amount).toList();

    // controllers
    TextEditingController ticketNumberController = TextEditingController();
    TextEditingController noteController = TextEditingController();

    // field values
    if (filteredTickets.isNotEmpty) {
      ticketNumber = filteredTickets.first.ticketNumber + 1;
    }
    ticketNumberController.text = ticketNumber.toString();
    sevaNames = _getSevaNames(amount);
    sevaName = sevaNames.isNotEmpty ? sevaNames[0] : "";

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    // Ticket number
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ticketNumberController,
                            decoration:
                                InputDecoration(labelText: "Ticket Number"),
                          ),
                        ),
                      ],
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
                                  setModalState(() {
                                    amount = int.parse(seva.keys.first);
                                    filteredTickets = _tickets
                                        .where(
                                            (ticket) => ticket.amount == amount)
                                        .toList();
                                    ticketNumberController.text =
                                        (filteredTickets.isNotEmpty
                                                ? filteredTickets
                                                        .first.ticketNumber +
                                                    1
                                                : 0)
                                            .toString();
                                    sevaNames = _getSevaNames(amount);
                                    sevaName = sevaNames.isNotEmpty
                                        ? sevaNames[0]
                                        : "";
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: amount.toString() == seva.keys.first
                                        ? seva.values.first['color']! as Color
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: seva.values.first['color']!
                                            as Color),
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
                                              color: amount.toString() ==
                                                      seva.keys.first
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
                            if (m == "Gift") return Container();
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    mode = m;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: primaryColor),
                                    color: mode == m
                                        ? primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Image.asset(Const()
                                              .paymentModes[m]!['icon']!),
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
                        sevaName = newValue!;
                      },
                      hint: Text(
                        "Select Seva",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),

                    // note
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: noteController,
                            decoration: InputDecoration(labelText: "Note"),
                          ),
                        ),

                        // ok button
                        SizedBox(width: 10),
                        ElevatedButton(
                          child: Text("Add"),
                          onPressed: () async {
                            Navigator.pop(context);

                            // fetch the icon
                            List sevas = Const()
                                .nityaSeva['amounts']!
                                .firstWhere((element) =>
                                    element.keys.first == amount.toString())
                                .values
                                .first['sevas'] as List;
                            String icon = sevas.firstWhere((element) =>
                                element['name'] == sevaName)['icon'];

                            // create ticket
                            Ticket ticket = Ticket(
                              timestamp: DateTime.now(),
                              amount: amount,
                              mode: mode,
                              ticketNumber:
                                  int.parse(ticketNumberController.text),
                              user: "Guest",
                              note: noteController.text,
                              image: icon,
                              seva: sevaName,
                            );

                            // pre validations
                            List<String> errors = _prevalidateTicket(ticket);
                            if (errors.isNotEmpty) {
                              String? action = await CommonWidgets()
                                  .createErrorDialog(
                                      context: context, errors: errors);
                              if (action == "Cancel") {
                                return;
                              }
                            }

                            // add ticket to list
                            setState(() {
                              _tickets.insert(0, ticket);
                            });

                            // add ticket to database
                            String dbDate = DateFormat("yyyy-MM-dd")
                                .format(widget.session.timestamp)
                                .toString();
                            String dbSession = widget.session.timestamp
                                .toIso8601String()
                                .replaceAll(".", "^");
                            FB().addToList(
                                path: "NityaSeva/$dbDate/$dbSession/Tickets",
                                data: ticket.toJson());

                            // post validations
                            if (errors.isEmpty) {
                              errors = await _postvalidateTicket();
                              if (errors.isNotEmpty) {
                                String? action = await CommonWidgets()
                                    .createErrorDialog(
                                        context: context,
                                        errors: errors,
                                        post: true);

                                if (action == "Delete") {
                                  _deleteTicket(ticket);
                                } else if (action == "Edit") {
                                  _addEditTicket(ticket);
                                }
                              }
                            }

                            // clear all lists
                            sevaNames.clear();
                            filteredTickets.clear();
                            errors.clear();

                            // dispose all controllers and focus nodes
                            ticketNumberController.dispose();
                            noteController.dispose();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
                _addEditTicket(context);
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
