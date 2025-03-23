import 'package:flutter/material.dart';

Future<void> _showDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        // title for the dialog
        title: Text(
          'Add New Session',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              // stateful widgets
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(children: []);
                },
              ),

              // Stateless widgets
              const Placeholder(),
            ],
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
