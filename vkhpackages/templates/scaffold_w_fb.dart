import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Sales extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Sales({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _SalesState createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  final Set _loadedKeys = {};

  // lists

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps

    // dispose all controllers and focus nodes

    // listeners
    for (var listener in _listeners) {
      listener.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here

      // read database and populate data
      String dbdate = DateFormat("yyyy-MM-dd").format(DateTime.now());
      String dbpath = "${Const().dbrootGaruda}/Deepotsava/Sales/$dbdate";


      // listen for database events
      _addListeners(dbpath);
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  void _addData(Map data) {
    setState(() {});
  }

  void _addListeners(String dbpath) {
    for (var listener in _listeners) {
      listener.cancel();
    }
    FB().listenForChange(
      dbpath,
      FBCallbacks(
        // add
        add: (data) {
          // workaround to avoid duplicate entries during initial load
          if (_loadedKeys.contains(data['timestamp'])) {
            return;
          }
          _loadedKeys.add(data['timestamp']);

          // process the received data
          _addData(data);
        },

        // edit
        edit: () {
          refresh();
        },

        // delete
        delete: (data) async {
          // workaround to avoid duplicate entries during initial load
          if (_loadedKeys.contains(data['timestamp'])) {
            _loadedKeys.remove(data['timestamp']);

            // process the received data
            _deleteData(data);
          }
        },

        // get listeners
        getListeners: (listeners) {
          _listeners = listeners;
        },
      ),
    );
  }

  void _deleteData(Map data) {
    setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveScaffold(
          // title
          title: widget.title,

          // toolbar icons
          toolbarActions: [],

          // body
          body: RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    children: [
                      // leave some space at top
                      SizedBox(height: 10),

                      // your widgets here

                      // leave some space at bottom
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading) LoadingOverlay(image: widget.splashImage),
      ],
    );
  }
}
