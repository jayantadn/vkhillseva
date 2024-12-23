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
    String? key,
    required Map<String, dynamic> data,
  }) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      if (key != null) {
        await dbref.push().child(key).set(data);
      } else {
        await dbref.push().set(data);
      }
    } catch (e) {
      Toaster().error("Error adding data to list: $e");
    }
  }
}
