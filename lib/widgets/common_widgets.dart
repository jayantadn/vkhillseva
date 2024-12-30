import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonWidgets {
  static final CommonWidgets _instance = CommonWidgets._internal();

  factory CommonWidgets() {
    return _instance;
  }

  CommonWidgets._internal() {
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

  Future<String?> createErrorDialog(
      {required BuildContext context,
      required List<String> errors,
      bool post = false,
      bool noaction = false}) async {
    Completer<String?> action = Completer<String?>();

    // populate skipErrorCheck
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sk = prefs.getString('SkipErrorCheck');
    bool skipErrorCheck = false;
    if (sk != null) {
      DateTime today = DateTime.now();
      DateTime skDate = DateTime.parse(sk);
      if (today.year == skDate.year &&
          today.month == skDate.month &&
          today.day == skDate.day) {
        skipErrorCheck = true;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text('ERROR',
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

                // checkbox to skip error checks
                CheckboxListTile(
                  title: Text('Skip error checks for today',
                      style: Theme.of(context).textTheme.bodySmall),
                  value: skipErrorCheck,
                  onChanged: (bool? value) {
                    if (value != null) {
                      if (value) {}
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            // cancel button
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                action.complete('Cancel');
              },
            ),

            // create button
            if (post == false && noaction == false)
              TextButton(
                child: Text('Proceed'),
                onPressed: () {
                  Navigator.of(context).pop();
                  action.complete('Proceed');
                },
              ),

            // Edit button
            if (post == true)
              TextButton(
                child: Text('Edit'),
                onPressed: () {
                  Navigator.of(context).pop();
                  action.complete('Edit');
                },
              ),

            // delete button
            if (post == true)
              TextButton(
                child: Text('Delete'),
                onPressed: () {
                  Navigator.of(context).pop();
                  action.complete('Delete');
                },
              ),
          ],
        );
      },
    );

    return action.future;
  }

  Widget customAppBarTitle(String title) {
    return Container(
      width: double.infinity, // Make the container stretch horizontally
      decoration: BoxDecoration(
        border: Border.all(color: accentColor, width: 2.0),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        // Center the text inside the box
        child: Text(title),
      ),
    );
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
