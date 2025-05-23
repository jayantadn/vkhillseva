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

  Future<SessionLock?> lockSession(
      {required String sessionPath, String? username}) async {
    // get the session
    var sessionJson = await FB().getJson(path: sessionPath);
    if (sessionJson.isEmpty) {
      Toaster().error("Unable to lock. Session not found");
      return null;
    }
    Session session = Session.fromJson(sessionJson);

    SessionLock? sessionLock = session.sessionLock;
    if (sessionLock == null) {
      sessionLock = SessionLock(
        isLocked: true,
      );
    } else {
      sessionLock.isLocked = true;
    }
    sessionLock.lockedBy = username ?? "Autolock";
    sessionLock.lockedTime = DateTime.now();

    // push to fb
    await FB()
        .setJson(path: "$sessionPath/sessionLock", json: sessionLock.toJson());

    return sessionLock;
  }
}
