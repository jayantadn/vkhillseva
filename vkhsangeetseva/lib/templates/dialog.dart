import 'package:flutter/material.dart';

Future<void> _createSomeDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add New Session',
            style: Theme.of(context).textTheme.headlineMedium),
        content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              // clear all local lists

              // clear all local controllers and focus nodes

              // close the dialog
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              // Handle the add session logic here

              // clear all local lists

              // clear all local controllers and focus nodes

              // close the dialog
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
