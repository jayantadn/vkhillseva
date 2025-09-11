import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vkhpackages/vkhpackages.dart';

class RegisteredEvents extends StatefulWidget {
  const RegisteredEvents({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisteredEventsState createState() => _RegisteredEventsState();
}

class _RegisteredEventsState extends State<RegisteredEvents> {
  // scalars
  DateTime _lastDataModification = DateTime.now();

  // lists

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    FB().listenForChange(
      "${Const().dbrootGaruda}/PendingRequests",
      FBCallbacks(
        // add
        add: (data) {
          if (_lastDataModification.isBefore(
            DateTime.now().subtract(Duration(seconds: Const().fbListenerDelay)),
          )) {
            _lastDataModification = DateTime.now();

            // process the received data
            print(data);
          }


        },

        // edit
        edit: () {
          if (_lastDataModification.isBefore(
            DateTime.now().subtract(Duration(seconds: Const().fbListenerDelay)),
          )) {
            _lastDataModification = DateTime.now();

            refresh();
          }
        },

        // delete
        delete: (data) async {
          if (_lastDataModification.isBefore(
            DateTime.now().subtract(Duration(seconds: Const().fbListenerDelay)),
          )) {
            _lastDataModification = DateTime.now();

            // process the received data
            print(data);
          }
        },

        // get listeners
        getListeners: (listeners) {
          _listeners = listeners;
        },
      ),
    );
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes
    for (var element in _listeners) {
      element.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }

  Future<void> refresh() async {}
}
