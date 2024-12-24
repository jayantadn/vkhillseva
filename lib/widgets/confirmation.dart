import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class Confirmation extends StatefulWidget {
  final String? msg;
  final ConfirmationCallbacks callbacks;

  const Confirmation({super.key, this.msg, required this.callbacks});

  @override
  State<Confirmation> createState() => _ConfirmationState();
}

// ignore: library_private_types_in_public_api
GlobalKey<_ConfirmationState> summaryKey = GlobalKey<_ConfirmationState>();

class _ConfirmationState extends State<Confirmation> {
  final Lock _lock = Lock();

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers

    super.dispose();
  }

  void refresh() async {
    await _lock.synchronized(() async {
      showDialog(
        context: context!,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                Text('Confirm'),
              ],
            ),
            content: Text(widget.msg ?? 'Are you sure?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget.callbacks.onCancel != null) {
                    widget.callbacks.onCancel!();
                  }
                },
              ),
              TextButton(
                child: Text('Confirm'),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.callbacks.onConfirm();
                },
              ),
            ],
          );
        },
      );
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class ConfirmationCallbacks {
  final Function onConfirm;
  Function? onCancel;

  ConfirmationCallbacks({required this.onConfirm, this.onCancel});
}
