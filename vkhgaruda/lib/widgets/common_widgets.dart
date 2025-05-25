import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NSWidgetsOld {
  static final NSWidgetsOld _instance = NSWidgetsOld._internal();

  factory NSWidgetsOld() {
    return _instance;
  }

  NSWidgetsOld._internal() {
    // init
  }

  void confirm(
      {required BuildContext context,
      String? msg,
      required ConfirmationCallbacks callbacks}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Text('Confirm'),
            ],
          ),
          content: Text(msg ?? 'Are you sure?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                if (callbacks.onCancel != null) {
                  callbacks.onCancel!();
                }
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                callbacks.onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  PopupMenuButton<String> createPopupMenu(List<MyPopupMenuItem> items) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 32),
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
                      Icon(item.icon,
                          size: 20, color: Theme.of(context).iconTheme.color),
                      const SizedBox(width: 8),
                      Text(item.text),
                    ],
                  ),
                ))
            .toList();
      },
    );
  }

  Future<String?> createErrorDialog({
    required BuildContext context,
    required List<String> errors,
    bool post = false,
  }) async {
    Completer<String?> action = Completer<String?>();

    // populate skipErrorCheck
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sk = prefs.getString('SkipErrorCheck');
    if (sk != null) {
      DateTime today = DateTime.now();
      DateTime skDate = DateTime.parse(sk);
      if (today.year == skDate.year &&
          today.month == skDate.month &&
          today.day == skDate.day) {
        return 'Proceed';
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('WARNING',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(color: Colors.red)),
            ],
          ),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start, // Add this line
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("The following errors are detected:"),
                ),
                for (var error in errors)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(" - $error"),
                  ),
                if (post == false)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        "\nClick 'Proceed' to ignore the errors and continue"),
                  ),
                if (post == true)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("\nPlease take necessary action"),
                  ),
              ],
            ),
          ),
          actions: [
            // cancel button
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                action.complete('Cancel');
              },
            ),

            // create button
            if (post == false)
              TextButton(
                child: Text('Proceed'),
                onPressed: () {
                  Navigator.of(context).pop();
                  action.complete('Proceed');
                },
              ),

            // skip button
            TextButton(
              child: Text(
                  post == true ? 'Disable error' : 'Proceed & disable error'),
              onPressed: () {
                Navigator.of(context).pop();
                action.complete('Proceed');
                prefs.setString(
                    'SkipErrorCheck', DateTime.now().toIso8601String());
              },
            ),
          ],
        );
      },
    );

    return action.future;
  }
}

class ConfirmationCallbacks {
  final Function onConfirm;
  Function? onCancel;

  ConfirmationCallbacks({required this.onConfirm, this.onCancel});
}

class MyPopupMenuItem {
  final String text;
  final IconData icon;
  final Function() onPressed;

  MyPopupMenuItem(
      {required this.text, required this.icon, required this.onPressed});
}
