import 'package:firebase_database/firebase_database.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/home/settings_festivals.dart';

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
    List<FestivalSettings> festivals = [];

    final DatabaseReference dbref =
        FirebaseDatabase.instance.ref(Const().dbroot);

    DataSnapshot snapshot =
        await dbref.child('Config/NityaSeva/FestivalOld').get();
    if (snapshot.value != null) {
      Map<dynamic, dynamic> values = snapshot.value as Map;
      values.forEach((key, value) {
        Map<String, dynamic> v = Map<String, dynamic>.from(value as Map);
        _festivalConfig[key] = v;

        festivals.add(FestivalSettings(
          name: key,
          icon: v['icon'],
        ));
      });
    }

    // update the settings
    List<Map<String, dynamic>> festivalsJson =
        festivals.map((festival) => festival.toJson()).toList();
    await dbref.child('Config/NityaSeva/Festivals').set(festivalsJson);
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
