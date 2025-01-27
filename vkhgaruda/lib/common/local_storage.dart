import 'package:shared_preferences/shared_preferences.dart';

class LS {
  static final LS _instance = LS._internal();

  factory LS() {
    return _instance;
  }

  LS._internal();

  Future<String?> read(String key) async =>
      SharedPreferences.getInstance().then(
        // ignore: await_only_futures
        (prefs) async => await prefs.getString(key),
      );

  Future<void> write(String key, String value) async =>
      SharedPreferences.getInstance().then(
        (prefs) async => await prefs.setString(key, value),
      );

  Future<void> delete(String key) async => SharedPreferences.getInstance().then(
        (prefs) async => await prefs.remove(key),
      );
}
