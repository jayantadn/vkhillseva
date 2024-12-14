import 'package:firebase_database/firebase_database.dart';
import 'package:vkhillseva/common/const.dart';

class Config {
  static final Config _instance = Config._internal();

  factory Config() {
    return _instance;
  }

  Config._internal() {
    // init
  }

  // private variables

  // Map<festival_name, Map<key, value>>
  Map<String, Map<String, dynamic>> _festivalConfig = {};

  Future<void> parse() async {
    final DatabaseReference dbref =
        FirebaseDatabase.instance.ref(Const().dbroot);

    DataSnapshot snapshot =
        await dbref.child('Config/NityaSeva/Festivals').get();
    if (snapshot.value != null) {
      // print(snapshot.value);
      Map<dynamic, dynamic> values = snapshot.value as Map;
      values.forEach((key, value) {
        Map<String, dynamic> v = Map<String, dynamic>.from(value as Map);
        _festivalConfig[key] = v;
        // DeepamStock stock = DeepamStock.fromJson(v);
        // stocks.add(stock);
      });
    }
  }

  // Map<name, icon>
  Map<String, String> getFestivalIcons() {
    Map<String, String> icons = {};
    _festivalConfig.forEach((key, value) {
      icons[key] = value['icon'];
    });

    return icons;
  }
}
