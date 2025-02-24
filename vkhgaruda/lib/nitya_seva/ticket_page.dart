import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/nitya_seva/session.dart';
import 'package:vkhgaruda/nitya_seva/session_summary.dart';
import 'package:vkhgaruda/nitya_seva/tally_cash.dart';
import 'package:vkhgaruda/nitya_seva/tally_upi_card.dart';
import 'package:vkhgaruda/widgets/common_widgets.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TicketPage extends StatefulWidget {
  final Session session;

  const TicketPage({super.key, required this.session});

  @override
  _TicketPageState createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  // locals
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _lastCallbackInvoked = DateTime.now();
  String _username = "Guest";

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
        "${Const().dbrootGaruda}/NityaSeva/$dbDate/$sessionKey/Tickets",
        FBCallbacks(
          // add
          add: (data) {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              Map<String, dynamic> ticket = Map<String, dynamic>.from(data);
              setState(() {
                if (_tickets.indexWhere((element) =>
                        element.timestamp ==
                        DateTime.parse(ticket['timestamp'])) ==
                    -1) {
                  _tickets.add(Ticket.fromJson(ticket));
                  _tickets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                }
              });
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

            Map<String, dynamic> ticket = Map<String, dynamic>.from(data);
            setState(() {
              if (_tickets.indexWhere((element) =>
                      element.timestamp ==
                      DateTime.parse(ticket['timestamp'])) ==
                  -1) {
                _tickets.remove(Ticket.fromJson(ticket));
                _tickets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              }
            });
          },

          // get listeners
          getListeners: (listeners) {
            _listeners = listeners;
          },
        ));

    // write the current session to LS
    // this is used by tally cash and tally UPI
    LS().write("selectedSlot", widget.session.timestamp.toIso8601String());

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _tickets.clear();

    // clear all controllers and focus nodes
    for (var listener in _listeners) {
      listener.cancel();
    }

    super.dispose();
  }

  Future<void> refresh({bool? spinner = true}) async {
    if (spinner != null && spinner == true) {
      setState(() {
        _isLoading = true;
      });
    }

    _username = Utils().getUsername();

    // fetch tickets
    String dbDate = DateFormat("yyyy-MM-dd").format(widget.session.timestamp);
    String dbSession =
        widget.session.timestamp.toIso8601String().replaceAll(".", "^");
    List ticketsJson = await FB().getList(
        path: "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/Tickets");
    await _lock.synchronized(() async {
      _tickets.clear();
      for (var t in ticketsJson) {
        Map<String, dynamic> ticket = Map<String, dynamic>.from(t);
        _tickets.add(Ticket.fromJson(ticket));
      }
    });

    setState(() {
      _tickets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _isLoading = false;
    });
  }

  Widget _createTicketTile(int sl, Ticket ticket) {
    double sizeOfContainer = 80;
    String time = DateFormat("HH:mm").format(ticket.timestamp);

    Color color = Const()
        .nityaSeva['amounts']!
        .firstWhere((element) => element.keys.first == ticket.amount.toString())
        .values
        .first['color']! as Color;

    return Dismissible(
      key: Key(ticket.ticketNumber.toString()),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _addEditTicket(context, ticket);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          _deleteTicket(ticket);
          return false;
        }
        return false;
      },
      child: Row(
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
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: backgroundColor, fontWeight: FontWeight.bold)),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            // seva name headline
                            Flexible(
                              child: Text(
                                ticket.seva,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(color: color),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // note icon
                            SizedBox(width: 8),
                            if (ticket.note.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  // Handle note click event
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Note'),
                                        content: Text(ticket.note),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Close'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    color: Colors.yellow,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: Text('Note',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(color: Colors.black)),
                                  ),
                                ),
                              ),
                          ]),

                          // other details
                          SizedBox(height: 2),
                          Text(
                            "${ticket.user}, Time: $time, Amount: ${ticket.amount} - ${ticket.mode}",
                            style: Theme.of(context).textTheme.bodyMedium,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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

    // check if ticket is entered in another date
    DateTime now = DateTime.now();
    if (widget.session.timestamp.day != now.day ||
        widget.session.timestamp.month != now.month ||
        widget.session.timestamp.year != now.year) {
      errors.add("Ticket from another date");
    }

    return errors;
  }

  Future<List<String>> _prevalidateDelete(Ticket ticket) async {
    List<String> errors = [];

    // check if ticket is from another date
    DateTime now = DateTime.now();
    if (ticket.timestamp.day != now.day ||
        ticket.timestamp.month != now.month ||
        ticket.timestamp.year != now.year) {
      errors.add("Ticket created in older date");
    }

    // check if ticket is not from latest session
    String dbDate = DateFormat("yyyy-MM-dd").format(now);
    var sessionsList =
        await FB().getList(path: "${Const().dbrootGaruda}/NityaSeva/$dbDate");
    List<Session> sessions = [];
    for (var sessionRaw in sessionsList) {
      Map<String, dynamic> s =
          Map<String, dynamic>.from(sessionRaw['Settings']);
      sessions.add(Session.fromJson(s));
    }
    sessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (sessions.isNotEmpty) {
      DateTime lastSession = sessions.last.timestamp;
      if (lastSession != widget.session.timestamp) {
        errors.add("Ticket from another session");
      }
    }

    sessions.clear();
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
    var sessionsList =
        await FB().getList(path: "${Const().dbrootGaruda}/NityaSeva/$dbDate");
    if (sessionsList.isEmpty) {
      errors.add("No sessions found for today");
    } else {
      List<Session> sessions = [];
      for (var sessionRaw in sessionsList) {
        Map<String, dynamic> sessionMap =
            Map<String, dynamic>.from(sessionRaw['Settings']);
        sessions.add(Session.fromJson(sessionMap));
      }
      sessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (sessions.last.timestamp != widget.session.timestamp) {
        errors.add("Ticket created in old session");
      }
    }

    return errors;
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    List<String> errors = await _prevalidateDelete(ticket);

    if (errors.isNotEmpty) {
      String? action = await CommonWidgets().createErrorDialog(
        context: context,
        errors: errors,
      );

      if (action == "Cancel") {
        return;
      }
    }

    CommonWidgets().confirm(
        context: context,
        msg: "Are you sure you want to delete this ticket?",
        callbacks: ConfirmationCallbacks(onConfirm: () {
          // delete ticket from list
          setState(() {
            _tickets.remove(ticket);
          });
          _lastCallbackInvoked = DateTime.now();

          // delete ticket from database
          String dbDate =
              DateFormat("yyyy-MM-dd").format(widget.session.timestamp);
          String dbSession =
              widget.session.timestamp.toIso8601String().replaceAll(".", "^");
          String key = ticket.timestamp.toIso8601String().replaceAll(".", "^");
          FB().deleteValue(
              path:
                  "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/Tickets/$key");
        }));
  }

  void _addEditTicket(context, Ticket? ticket) {
    // locals
    int amount = ticket == null ? widget.session.defaultAmount : ticket.amount;
    int ticketNumber = ticket == null ? 0 : ticket.ticketNumber;
    String mode =
        ticket == null ? widget.session.defaultPaymentMode : ticket.mode;
    String sevaName = ticket == null ? "" : ticket.seva;

    // lists
    List<String> sevaNames = [];
    List<Ticket> filteredTickets =
        _tickets.where((ticket) => ticket.amount == amount).toList();

    // controllers
    TextEditingController ticketNumberController = TextEditingController();
    TextEditingController noteController =
        TextEditingController(text: ticket == null ? "" : ticket.note);

    // field values
    if (ticket == null) {
      if (filteredTickets.isNotEmpty) {
        ticketNumber = filteredTickets.first.ticketNumber + 1;
      }
    }
    ticketNumberController.text = ticketNumber.toString();
    sevaNames = _getSevaNames(amount);
    if (ticket == null) {
      sevaName = sevaNames.isNotEmpty ? sevaNames[0] : "";
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation animation,
          Animation secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        // padding at the top
                        SizedBox(height: 32),

                        // Ticket number
                        TextField(
                          controller: ticketNumberController,
                          decoration:
                              InputDecoration(labelText: "Ticket Number"),
                          keyboardType: TextInputType.number,
                        ),

                        // Seva amount label
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

                        // buttons for seva amounts
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...Const().nityaSeva['amounts']!.map((seva) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        amount = int.parse(seva.keys.first);
                                        filteredTickets = _tickets
                                            .where((ticket) =>
                                                ticket.amount == amount)
                                            .toList();
                                        ticketNumberController.text =
                                            (filteredTickets.isNotEmpty
                                                    ? filteredTickets.first
                                                            .ticketNumber +
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
                                        color:
                                            amount.toString() == seva.keys.first
                                                ? seva.values.first['color']!
                                                    as Color
                                                : Colors.transparent,
                                        border: Border.all(
                                            color: seva.values.first['color']!
                                                as Color),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
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

                        // Payment mode label
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

                        // seva amount buttons
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
                                      setDialogState(() {
                                        mode = m;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: primaryColor),
                                        color: mode == m
                                            ? primaryColor
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
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

                        // seva name label
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

                        // seva name dropdown
                        DropdownButton<String>(
                          isExpanded: true,
                          value: sevaName,
                          items: sevaNames.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              sevaName = newValue!;
                            });
                          },
                          hint: Text(
                            "Select Seva",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),

                        // note field
                        SizedBox(height: 8),
                        TextField(
                          controller: noteController,
                          decoration: InputDecoration(labelText: "Note"),
                        ),

                        // buttons
                        SizedBox(height: 8),
                        Row(
                          children: [
                            // cancel button
                            Expanded(
                              child: OutlinedButton(
                                child: Text("Cancel"),
                                onPressed: () {
                                  Navigator.pop(context);
                                  // clear all lists
                                  sevaNames.clear();
                                  filteredTickets.clear();

                                  // dispose all controllers and focus nodes
                                  ticketNumberController.dispose();
                                  noteController.dispose();
                                },
                              ),
                            ),

                            // add button
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                child: Text(ticket == null ? "Add" : "Update"),
                                onPressed: () async {
                                  // close the dialog
                                  Navigator.pop(context);

                                  // fetch the icon
                                  List sevas = Const()
                                      .nityaSeva['amounts']!
                                      .firstWhere((element) =>
                                          element.keys.first ==
                                          amount.toString())
                                      .values
                                      .first['sevas'] as List;
                                  String icon = sevas.firstWhere((element) =>
                                      element['name'] == sevaName)['icon'];

                                  // create ticket
                                  Ticket t = Ticket(
                                    timestamp: ticket == null
                                        ? DateTime.now()
                                        : ticket.timestamp,
                                    amount: amount,
                                    mode: mode,
                                    ticketNumber:
                                        int.parse(ticketNumberController.text),
                                    user: _username,
                                    note: noteController.text,
                                    image: icon,
                                    seva: sevaName,
                                  );

                                  // pre validations
                                  List<String> errors = [];
                                  if (ticket == null) {
                                    errors = _prevalidateTicket(t);
                                    if (errors.isNotEmpty) {
                                      String? action = await CommonWidgets()
                                          .createErrorDialog(
                                              context: context, errors: errors);
                                      if (action == "Cancel") {
                                        return;
                                      }
                                    }
                                  }

                                  // add ticket to list
                                  setState(() {
                                    if (ticket == null) {
                                      _tickets.insert(0, t);
                                    } else {
                                      _tickets[_tickets.indexWhere((element) =>
                                          element.timestamp ==
                                          ticket.timestamp)] = t;
                                    }
                                  });
                                  _lastCallbackInvoked = DateTime.now();

                                  // add ticket to database
                                  String dbDate = DateFormat("yyyy-MM-dd")
                                      .format(widget.session.timestamp)
                                      .toString();
                                  String dbSession = widget.session.timestamp
                                      .toIso8601String()
                                      .replaceAll(".", "^");
                                  if (ticket != null) {
                                    String key = ticket.timestamp
                                        .toIso8601String()
                                        .replaceAll(".", "^");
                                    FB().deleteValue(
                                        path:
                                            "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/Tickets/$key");
                                  }
                                  FB().addMapToList(
                                      path:
                                          "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/Tickets",
                                      data: t.toJson());

                                  // post validations
                                  // if (errors.isEmpty) {
                                  //   errors = await _postvalidateTicket();
                                  //   if (errors.isNotEmpty) {
                                  //     String? action = await CommonWidgets()
                                  //         .createErrorDialog(
                                  //             context: context,
                                  //             errors: errors,
                                  //             post: true);

                                  //     if (action == "Delete") {
                                  //       _deleteTicket(t);
                                  //     } else if (action == "Edit") {
                                  //       _addEditTicket(context, t);
                                  //     }
                                  //   }
                                  // }

                                  // clear all lists
                                  sevaNames.clear();
                                  filteredTickets.clear();
                                  errors.clear();

                                  // dispose all controllers and focus nodes
                                  // TODO: disposing controllers is causing an exception while editing ticket
                                  // ticketNumberController.dispose();
                                  // noteController.dispose();
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -1),
            end: Offset(0, 0),
          ).animate(animation),
          child: child,
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.session.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    DateFormat("dd MMM, yyyy").format(widget.session.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                // add button
                IconButton(
                  icon: Icon(Icons.add, size: 32),
                  onPressed: () {
                    _addEditTicket(context, null);
                  },
                ),

                // summary button
                IconButton(
                  icon: Icon(Icons.article, size: 32),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SessionSummary(
                              title: 'Session summary',
                              icon: 'assets/images/LauncherIcons/NityaSeva.png',
                              session: widget.session)),
                    );
                  },
                ),

                // menu button
                CommonWidgets().createPopupMenu([
                  // tally cash button
                  MyPopupMenuItem(
                      text: "Tally cash",
                      icon: Icons.money,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TallyCashPage()),
                        );
                      }),

                  // tally UPI button
                  MyPopupMenuItem(
                      text: "Tally UPI",
                      icon: Icons.payment,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TallyUpiCardPage()),
                        );
                      }),
                ]),
              ],
            ),

            // body
            body: RefreshIndicator(
              onRefresh: refresh,
              child: _tickets.isEmpty
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          "Click '+' to add a ticket",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    )
                  : ListView.builder(
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
