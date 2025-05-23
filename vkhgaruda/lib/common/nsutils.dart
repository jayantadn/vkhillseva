import 'package:intl/intl.dart';
import 'package:vkhgaruda/nitya_seva/session.dart';
import 'package:vkhpackages/common/const.dart';
import 'package:vkhpackages/common/fb.dart';
import 'package:vkhpackages/common/toaster.dart';

class NSUtils {
  static final NSUtils _instance = NSUtils._internal();

  factory NSUtils() {
    return _instance;
  }

  NSUtils._internal() {
    // init
  }

  Future<void> lockSession(String sessionPath, SessionLock sessionLock) async {
    // get the session
    var sessionJson = await FB().getJson(path: sessionPath);
    if (sessionJson.isEmpty) {
      Toaster().error("Unable to lock. Session not found");
      return;
    }
    Session session = Session.fromJson(sessionJson);

    // push to fb
    String dbdate = DateFormat('yyyy-MM-dd').format(session.timestamp);
    String key = session.timestamp.toIso8601String().replaceAll(".", "^");
    await FB().setJson(
        path:
            "${Const().dbrootGaruda}/NityaSeva/$dbdate/$key/Settings/sessionLock",
        json: sessionLock.toJson());
  }
}
