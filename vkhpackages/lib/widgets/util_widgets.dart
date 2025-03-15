import 'package:flutter/material.dart';

class UtilWidgets {
  static final UtilWidgets _instance = UtilWidgets._internal();

  factory UtilWidgets() {
    return _instance;
  }

  UtilWidgets._internal() {
    // init
  }

  Future<void> showMessage(BuildContext context, String msg) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(msg),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
