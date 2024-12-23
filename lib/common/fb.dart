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

  Future<dynamic> get(String path) async {
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

  Future<void> setValue(String path, dynamic data) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      await dbref.set(data);
    } catch (e) {
      Toaster().error("Error setting data: $e");
    }
  }

  Future<void> setJson(String path, Map<String, dynamic> data) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      await dbref.set(data);
    } catch (e) {
      Toaster().error("Error setting data: $e");
    }
  }

  Future<void> addToList(String path, Map<String, dynamic> data) async {
    try {
      DatabaseReference dbref =
          FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
      await dbref.push().set(data);
    } catch (e) {
      Toaster().error("Error adding data to list: $e");
    }
  }
}
