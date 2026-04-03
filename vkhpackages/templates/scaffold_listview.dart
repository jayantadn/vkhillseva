import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class NotificationPage extends StatefulWidget {
  final String title;
  final String? splashImage;
  final List<NotificationEntry>? prefilledNotifications;

  const NotificationPage(
      {super.key,
      required this.title,
      this.splashImage,
      this.prefilledNotifications});

  @override
  // ignore: library_private_types_in_public_api
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  final Set _loadedKeys = {};

  // lists
  final List<NotificationEntry> _notifications = [];

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
    _notifications.clear();

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
      UserBasics? basics = await Utils().fetchOrGetUserBasics();

      // read database and populate data
      if (basics != null) {
        _notifications.clear();
        String dbpath =
            "${Const().dbrootSangeetSeva}/Notifications/Performers/${basics.mobile}";
        if (widget.prefilledNotifications != null) {
          _notifications.addAll(widget.prefilledNotifications!);
        } else {
          Map<String, dynamic> notificationsRaw =
              await FB().getJson(path: dbpath, silent: true);
          _notifications.addAll(notificationsRaw.entries.map(
            (entry) {
              return Utils().convertRawToDatatype(
                  entry.value, NotificationEntry.fromJson);
            },
          ));
          _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }

        // refresh all child widgets

        // listen for database events
        _addListeners(dbpath);
      }
    });

    setState(() {
      _isLoading = false;
    });
  }

  void _addData(Map data) {
    setState(() {
      _notifications
          .add(Utils().convertRawToDatatype(data, NotificationEntry.fromJson));
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
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

  Widget _createNotificationTile(int index) {
    return Placeholder();
  }

  void _deleteData(Map data) {
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveScaffold(
          // title
          title: widget.title,

          // toolbar icons
          toolbarActions: [
            // ResponsiveToolbarAction(
            //   icon: const Icon(Icons.playlist_add),
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => Placeholder()),
            //     );
            //   },
            // ),
          ],

          // body
          body: RefreshIndicator(
            onRefresh: refresh,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child: ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (BuildContext context, int index) =>
                          _createNotificationTile(index))),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading) LoadingOverlay(image: widget.splashImage),
      ],
    );
  }
}
