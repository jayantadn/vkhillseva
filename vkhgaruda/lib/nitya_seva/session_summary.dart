import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class SessionSummary extends StatefulWidget {
  final String title;
  final String icon;
  final Session session;

  const SessionSummary(
      {super.key,
      required this.title,
      required this.icon,
      required this.session});

  @override
  _SessionSummaryState createState() => _SessionSummaryState();
}

class _SessionSummaryState extends State<SessionSummary> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists
  final List<List<String>> _items = [];
  final List<Ticket> _listEntries = [];

  // controllers, listeners and focus nodes

  void _appendRow(String col1, String col2, {bool bold = false}) {
    _items.last.add("$col1:   $col2");
  }

  void _appendHeadline(String col1, String col2) {
    List<String> amountDetails = ["$col1 $col2"];
    _items.add(amountDetails);
  }

  void _appendSpace() {
    _items.last.add("-");
  }

  Future<void> _populateTable() async {
    // // get the selected slot
    int totalTickets = 0;
    int totalUpi = 0;
    int totalCash = 0;
    int totalCard = 0;
    int totalAmount = 0;
    int totalUpiAmount = 0;
    int totalCashAmount = 0;
    int totalCardAmount = 0;

    List<int> pushpanjaliTickets = Const().nityaSeva['amounts']!.map((e) {
      return int.parse(e.keys.first);
    }).toList();

    for (int? amount in pushpanjaliTickets) {
      // get a filtered list per amount
      List<Ticket> listFiltered =
          _listEntries.where((e) => e.amount == amount).toList();
      listFiltered.sort((a, b) => a.ticketNumber.compareTo(b.ticketNumber));

      // highest and lowest ticketNumber numbers
      int entryWithLowestTicket = 0;
      int entryWithHighestTicket = 0;
      int total = 0;
      if (listFiltered.isNotEmpty) {
        Ticket entry = listFiltered.reduce((currentLowest, next) =>
            next.ticketNumber < currentLowest.ticketNumber
                ? next
                : currentLowest);
        entryWithLowestTicket = entry.ticketNumber;

        entry = listFiltered.reduce((currentHighest, next) =>
            next.ticketNumber > currentHighest.ticketNumber
                ? next
                : currentHighest);
        entryWithHighestTicket = entry.ticketNumber;
      }

      // print headline
      _appendHeadline("Seva amount", amount.toString());

      // print ticketNumber numbers
      if (entryWithHighestTicket != 0) {
        total = entryWithHighestTicket - entryWithLowestTicket + 1;
      }
      if (total == listFiltered.length) {
        // all tickets are continuous
        _appendRow("Starting no", entryWithLowestTicket.toString());
        _appendRow("Ending no", entryWithHighestTicket.toString());
        _appendRow("Tickets sold", listFiltered.length.toString());
      } else {
        // ticketNumber numbers are not continuous
        listFiltered.sort((a, b) => a.ticketNumber.compareTo(b.ticketNumber));

        int start = listFiltered[0].ticketNumber;
        int end = listFiltered[0].ticketNumber;
        int totalSold = 0;
        for (int i = 1; i < listFiltered.length; i++) {
          if (listFiltered[i].ticketNumber - 1 ==
              listFiltered[i - 1].ticketNumber) {
            end = listFiltered[i].ticketNumber;
          } else {
            _appendRow("Ticket range", "$start - $end");
            int sold = end - start + 1;
            totalSold = totalSold + sold;
            _appendRow("Tickets sold", sold.toString());

            start = listFiltered[i].ticketNumber;
            end = listFiltered[i].ticketNumber;
          }
        }
        _appendRow("Ticket range", "$start - $end");
        int sold = end - start + 1;
        totalSold = totalSold + sold;
        _appendRow("Tickets sold", sold.toString());
        _appendRow("Total tickets sold", totalSold.toString());
      }

      // count of transactions per mode
      int numUpi = listFiltered.where((e) => e.mode == "UPI").length;
      int numCash = listFiltered.where((e) => e.mode == "Cash").length;
      int numCard = listFiltered.where((e) => e.mode == "Card").length;
      totalTickets = totalTickets + numUpi + numCash + numCard;
      totalUpi = totalUpi + numUpi;
      totalCash = totalCash + numCash;
      totalCard = totalCard + numCard;

      // amount per mode
      int amountUpi = listFiltered
          .where((e) => e.mode == "UPI")
          .fold(0, (previousValue, element) => previousValue + element.amount);
      int amountCash = listFiltered
          .where((e) => e.mode == "Cash")
          .fold(0, (previousValue, element) => previousValue + element.amount);
      int amountCard = listFiltered
          .where((e) => e.mode == "Card")
          .fold(0, (previousValue, element) => previousValue + element.amount);
      totalAmount = totalAmount + amountUpi + amountCash + amountCard;
      totalUpiAmount = totalUpiAmount + amountUpi;
      totalCashAmount = totalCashAmount + amountCash;
      totalCardAmount = totalCardAmount + amountCard;

      _appendSpace();
      _appendRow("No. of UPI transactions", numUpi.toString());
      _appendRow("No. of Cash transactions", numCash.toString());
      _appendRow("No. of Card transactions", numCard.toString());

      _appendSpace();
      _appendRow("Amount collected via UPI ", "Rs. ${amountUpi.toString()}");
      _appendRow("Amount collected via Cash ", "Rs. ${amountCash.toString()}");
      _appendRow("Amount collected via Card ", "Rs. ${amountCard.toString()}");

      _appendSpace();
      _appendRow("Total collection",
          "Rs. ${(amountUpi + amountCash + amountCard).toString()}",
          bold: true);
    }

    _appendHeadline("Total", "");
    _appendRow("Total tickets sold", totalTickets.toString(), bold: true);

    _appendSpace();
    _appendRow("Total UPI transactions", totalUpi.toString());
    _appendRow("Total Cash transactions", totalCash.toString());
    _appendRow("Total Card transactions", totalCard.toString());

    _appendSpace();
    _appendRow("Total amount via UPI", "Rs. ${totalUpiAmount.toString()}");
    _appendRow("Total amount via Cash", "Rs. ${totalCashAmount.toString()}");
    _appendRow("Total amount via Card", "Rs. ${totalCardAmount.toString()}");

    _appendSpace();
    _appendRow("Total overall collection", "Rs. ${totalAmount.toString()}",
        bold: true);
  }

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

    // fetch tickets
    String dbDate = DateFormat("yyyy-MM-dd").format(widget.session.timestamp);
    String dbSession =
        widget.session.timestamp.toIso8601String().replaceAll(".", "^");
    List ticketsJson = await FB().getList(
        path: "${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/Tickets");

    await _lock.synchronized(() async {
      _listEntries.clear();
      for (var t in ticketsJson) {
        Map<String, dynamic> ticket = Map<String, dynamic>.from(t);
        _listEntries.add(Ticket.fromJson(ticket));
      }
    });

    _items.clear();
    _populateTable();

    setState(() {
      _isLoading = false;
    });
  }

  Color _getColorBasedOnNumber(String header) {
    // Split the string based on whitespace
    List<String> parts = header.split(' ');

    // Get the last part and convert it to an integer
    int number = 0;
    if (header.trim() != 'Total') {
      number = int.parse(parts.last);
    }

    // Select a color based on the number
    List amounts = Const().nityaSeva['amounts'] as List;
    for (var amount in amounts) {
      if (amount.keys.first == number.toString()) {
        Map<String, dynamic> amountJson =
            Map<String, dynamic>.from(amount.values.first);
        return amountJson['color'] as Color;
      }
    }

    return Colors.grey[300] ?? Colors.grey;
  }

  List<Widget> _getListOfRows(List<String> rows) {
    List<Widget> list = [];
    for (int i = 0; i < rows.skip(1).length; i++) {
      String row = rows.skip(1).elementAt(i);
      if (row == '-') {
        list.add(const Divider()); // Add a divider
      } else {
        list.add(Text(
          row,
          style: TextStyle(
            color: Colors.black, // Text color for the rows
            fontSize: 16.0,
            fontWeight: i == rows.skip(1).length - 1
                ? FontWeight.bold
                : FontWeight.normal, // Make the last item bold
          ),
        ));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeGaruda,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                itemCount: _items.length, // Number of _items in the list
                itemBuilder: (BuildContext context, int index) {
                  // skip if no tickets sold
                  if (_items[index][3].contains("Tickets sold:   0")) {
                    return Container();
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0), // Adjust margin to remove top gap
                    decoration: BoxDecoration(
                      color: Colors.white, // Background color for the container
                      borderRadius:
                          BorderRadius.circular(8.0), // Rounded corners
                      border: Border.all(
                        color: Colors.grey, // Border color
                        width: 1.0, // Border width
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display the title
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: _getColorBasedOnNumber(_items[index][0]),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8.0),
                              topRight: Radius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            _items[index][0],
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // display the remaining rows
                        const SizedBox(height: 8.0),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _getListOfRows(_items[index]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon)
        ],
      ),
    );
  }
}
