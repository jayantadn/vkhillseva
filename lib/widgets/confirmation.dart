import 'package:flutter/material.dart';

class Confirmation {
  static final Confirmation _instance = Confirmation._internal();

  factory Confirmation() {
    return _instance;
  }

  Confirmation._internal() {
    // init
  }

  void show(
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
}

class ConfirmationCallbacks {
  final Function onConfirm;
  Function? onCancel;

  ConfirmationCallbacks({required this.onConfirm, this.onCancel});
}
