import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vkhillseva/nitya_seva/session.dart';
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

  PopupMenuButton<String> _createPopupMenu(List<MyPopupMenuItem> items) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (String value) {
        final selectedItem = items.firstWhere((item) => item.text == value);
        selectedItem.onPressed();
      },
      itemBuilder: (BuildContext context) {
        return items
            .map((item) => PopupMenuItem<String>(
                  value: item.text,
                  child: Row(
                    children: <Widget>[
                      Icon(item.icon, color: Theme.of(context).iconTheme.color),
                      const SizedBox(width: 8),
                      Text(item.text),
                    ],
                  ),
                ))
            .toList();
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
                _createPopupMenu([
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
                  const Placeholder(),
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

class MyPopupMenuItem {
  final String text;
  final IconData icon;
  final Function() onPressed;

  MyPopupMenuItem(
      {required this.text, required this.icon, required this.onPressed});
}
