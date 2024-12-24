import 'package:flutter/material.dart';

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
