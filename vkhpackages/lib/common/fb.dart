import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'toaster.dart';

class FB {
  static final FB _instance = FB._internal();

  factory FB() {
    return _instance;
  }

  FB._internal() {
    // init
  }

  Future<void> listenForChange(String path, FBCallbacks callbacks) async {
    final dbRef = FirebaseDatabase.instance.ref(path);

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

  Future<void> addToListOld({
    required String path,
    String? child,
    required Map<String, dynamic> data,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      if (child != null) {
        if (data['timestamp'] != null) {
          String key = data['timestamp'].toString().replaceAll(".", "^");
          await dbref.child(key).child(child).set(data);
        } else {
          await dbref.push().child(child).set(data);
        }
      } else {
        if (data['timestamp'] != null) {
          String key = data['timestamp'].toString().replaceAll(".", "^");
          await dbref.child(key).set(data);
        } else {
          await dbref.push().set(data);
        }
      }
    } catch (e) {
      Toaster().error("Error adding data to list: $e");
    }
  }

  Future<int> addToList({
    required String listpath,
    required dynamic data,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(listpath);
      DataSnapshot snap = await dbref.get();
      if (snap.value == null) {
        await dbref.set([data]);
        return 0;
      } else {
        List<dynamic> list = List<dynamic>.from(snap.value as List);
        list.add(data);
        await dbref.set(list);
        return list.length - 1;
      }
    } catch (e) {
      Toaster().error("Error adding data to list: $e");
      return -1;
    }
  }

  Future<void> addKVToList({
    String? dbroot,
    required String path,
    required String key,
    required dynamic value,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      await dbref.child(key).set(value);
    } catch (e) {
      Toaster().error("Error adding key-value to list: $e");
    }
  }

  Future<void> addListToList({
    String? dbroot,
    required String path,
    required List<dynamic> list,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      List currentList = await getList(path: path);
      if (currentList.isNotEmpty) {
        currentList.addAll(list);
      } else {
        currentList = list;
      }
      await dbref.set(currentList);
    } catch (e) {
      Toaster().error("Error adding list to list: $e");
    }
  }

  Future<void> addMapToList({
    String? dbroot,
    required String path,
    String? child,
    required Map<String, dynamic> data,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      if (child != null) {
        if (data['timestamp'] != null) {
          String key = data['timestamp'].toString().replaceAll(".", "^");
          await dbref.child(key).child(child).set(data);
        } else {
          await dbref.push().child(child).set(data);
        }
      } else {
        if (data['timestamp'] != null) {
          String key = data['timestamp'].toString().replaceAll(".", "^");
          await dbref.child(key).set(data);
        } else {
          await dbref.push().set(data);
        }
      }
    } catch (e) {
      Toaster().error("Error adding data to list: $e");
    }
  }

  Future<void> deleteFromList({
    required String listpath,
    required int index,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(listpath);
      DataSnapshot snap = await dbref.get();
      if (snap.value == null) {
        // list is empty
        return;
      } else {
        List<dynamic> list = List<dynamic>.from(snap.value as List);
        list.removeAt(index);
        await dbref.set(list);
        return;
      }
    } catch (e) {
      Toaster().error("Error deleting data from list: $e");
      return;
    }
  }

  Future<void> deleteFromListByValue({
    required String listpath,
    required dynamic value,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(listpath);
      DataSnapshot snap = await dbref.get();
      if (snap.value == null) {
        // list is empty
        return;
      } else {
        List<dynamic> list = List<dynamic>.from(snap.value as List);
        list.remove(value);
        await dbref.set(list);
        return;
      }
    } catch (e) {
      Toaster().error("Error deleting data from list: $e");
      return;
    }
  }

  Future<void> deleteValue({required String path}) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      await dbref.remove();
    } catch (e) {
      Toaster().error("Error deleting data: $e");
    }
  }

  Future<void> editJson({
    required String path,
    required Map<String, dynamic> json,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      await dbref.update(json);
    } catch (e) {
      Toaster().error("Error updating data: $e");
    }
  }

  Future<int> editList({
    required String listpath,
    required dynamic data,
    required int index,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(listpath);
      DataSnapshot snap = await dbref.get();
      if (snap.value == null) {
        // empty list
        await dbref.set([data]);
        return 0;
      } else {
        List<dynamic> list = List<dynamic>.from(snap.value as List);

        if (index < 0 || index >= list.length) {
          Toaster().error("index out of bounds");
          return -1;
        }
        list[index] = data;
        await dbref.set(list);
        return list.length - 1;
      }
    } catch (e) {
      Toaster().error("Error adding data to list: $e");
      return -1;
    }
  }

  Future<bool> pathExists(String path) async {
    try {
      dynamic snapshot = await FirebaseDatabase.instance.ref(path).get();
      return snapshot.value == null ? false : true;
    } catch (e) {
      return false;
    }
  }

  Future<dynamic> getValue({required String path}) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      DataSnapshot snapshot = await dbref.get();
      return snapshot.value;
    } catch (e) {
      Toaster().error("Error getting data: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> getValuesByDateRange({
    required String path,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);

      // Format the start and end dates to match the database key format
      String startDateStr = DateFormat("yyyy-MM-dd").format(startDate);
      String endDateStr =
          endDate != null
              ? DateFormat("yyyy-MM-dd").format(endDate)
              : startDateStr;

      // Create a query to filter by the date range
      Query query = dbref.orderByKey().startAt(startDateStr);
      if (endDate != null) {
        query = query.endAt(endDateStr);
      }

      DataSnapshot snapshot = await query.get();

      if (snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        return {};
      }
    } catch (e) {
      Toaster().error("Error getting data by date range: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getJson({
    required String path,
    bool? silent,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      DataSnapshot snapshot = await dbref.get();
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      if (silent == null || !silent) {
        Toaster().error("Error getting data: $e");
      }
      return {};
    }
  }

  Future<List<dynamic>> getList({required String path}) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      DataSnapshot snapshot = await dbref.get();
      if (snapshot.value is List) {
        List ret = List<dynamic>.from(snapshot.value as List);
        return ret;
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

  Future<List<dynamic>> getListByYear({
    required String path,
    required String year,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);

      // filter for given year
      DateTime start = DateTime(int.parse(year), 1, 1);
      DateTime end = DateTime(int.parse(year), 12, 31, 23, 59, 59, 999);

      final Query query = dbref
          .orderByKey()
          .startAt(DateFormat("yyyy-MM-dd").format(start))
          .endAt(DateFormat("yyyy-MM-dd").format(end));

      DataSnapshot snapshot = await query.get();
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

  Future<void> setMultipleJson(Map<String, dynamic> jsons) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref();
      await dbref.update(jsons);
    } catch (e) {
      Toaster().error("Error setting data: $e");
    }
  }

  Future<void> setValue({required String path, required dynamic value}) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      await dbref.set(value);
    } catch (e) {
      Toaster().error("Error setting data: $e");
    }
  }

  Future<void> setJson({
    required String path,
    required Map<String, dynamic> json,
  }) async {
    try {
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      await dbref.set(json);
    } catch (e) {
      Toaster().error("Error setting data: $e");
    }
  }

  Future<void> setList<T>({
    required String path,
    required List<T> list,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      // Convert each element in the list to JSON
      List<Map<String, dynamic>> jsonList =
          list.map((item) => toJson(item)).toList();

      // Publish the JSON list to the specified database path
      DatabaseReference dbref = FirebaseDatabase.instance.ref(path);
      await dbref.set(jsonList);
    } catch (e) {
      Toaster().error("Error in setList: $e");
      rethrow;
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
