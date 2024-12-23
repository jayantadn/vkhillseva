import 'package:firebase_database/firebase_database.dart';
import 'package:vkhillseva/common/const.dart';

class FB {
  static final FB _instance = FB._internal();

  factory FB() {
    return _instance;
  }

  FB._internal() {
    // init
  }

  Future<dynamic> get(String path) async {
    DatabaseReference dbref =
        FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
    DataSnapshot snapshot = await dbref.get();
    

    return snapshot.value;
  }

  Future<void> set(String path, dynamic data) async {
    DatabaseReference dbref =
        FirebaseDatabase.instance.ref("${Const().dbroot}/$path");
    await dbref.set(data);
  }
}
