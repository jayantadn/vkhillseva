import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/common/toaster.dart';

class FB {
  static final FB _instance = FB._internal();

  factory FB() {
    return _instance;
  }

  FB._internal() {
    // init
  }

  Future<void> listenForChange(String path, FBCallbacks callbacks) async {
    final dbRef = FirebaseDatabase.instance.ref("${Const().dbroot}/$path");

    bool initialLoad = true;

    // Check if the path exists
    try {
      await dbRef.get();
    } catch (e) {
      Toaster().error("Database path doesn't exist or no access");
      return;
    }

    List<StreamSubscription<DatabaseEvent>> listeners = [];

    var listener = dbRef.onChildAdded.listen((event) {
      if (!initialLoad) {
        callbacks.add(event.snapshot.value);
      }
    });
    listeners.add(listener);

    listener = dbRef.onChildChanged.listen((event) {
      if (!initialLoad) {
        callbacks.edit();
      }
    });
    listeners.add(listener);

    listener = dbRef.onChildRemoved.listen((event) {
      if (!initialLoad) {
        callbacks.delete(event.snapshot.value);
      }
    });
    listeners.add(listener);

    if (callbacks.getListeners != null) {
      callbacks.getListeners!(listeners);
    }

    // Set initialLoad to false after the first set of events
    dbRef.once().then((_) {
      initialLoad = false;
    });
  }

  Future<dynamic> getValue({required String path}) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      DataSnapshot snapshot = await dbref.get();
      return snapshot.value;
    } catch (e) {
      Toaster().error("Error getting data: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> getJson({required String path}) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      DataSnapshot snapshot = await dbref.get();
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      Toaster().error("Error getting data: $e");
      return {};
    }
  }

  Future<List<dynamic>> getList({required String path}) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      DataSnapshot snapshot = await dbref.get();
      if (snapshot.value is List) {
        return List<dynamic>.from(snapshot.value as List);
      } else if (snapshot.value is Map) {
        return List<dynamic>.from((snapshot.value as Map).values);
      } else {
        return [];
      }
    } catch (e) {
      Toaster().error("Error getting data: $e");
      return [];
    }
  }

  Future<void> setValue({required String path, required dynamic value}) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      await dbref.set(value);
    } catch (e) {
      Toaster().error("Error setting data: $e");
    }
  }

  Future<void> setJson(
      {required String path, required Map<String, dynamic> json}) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      await dbref.set(json);
    } catch (e) {
      Toaster().error("Error setting data: $e");
    }
  }

  Future<void> addToList({
    required String path,
    String? child,
    required Map<String, dynamic> data,
  }) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      if (child != null) {
        if (data['name'] != null) {
          await dbref.child(data['name']).child(child).set(data);
        } else {
          await dbref.push().child(child).set(data);
        }
      } else {
        if (data['name'] != null) {
          await dbref.child(data['name']).set(data);
        } else {
          await dbref.push().set(data);
        }
      }
    } catch (e) {
      Toaster().error("Error adding data to list: $e");
    }
  }

  Future<void> deleteValue({required String path}) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      await dbref.remove();
    } catch (e) {
      Toaster().error("Error deleting data: $e");
    }
  }
}

class FBCallbacks {
  void Function(dynamic data) add;
  void Function() edit; // full refresh required on edit
  void Function(dynamic data) delete;
  void Function(List<StreamSubscription<DatabaseEvent>>)? getListeners;

  FBCallbacks({
    required this.add,
    required this.edit,
    required this.delete,
    this.getListeners,
  });
}
