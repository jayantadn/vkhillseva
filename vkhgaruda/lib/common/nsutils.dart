import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:vkhgaruda/nitya_seva/session.dart';
import 'package:vkhpackages/vkhpackages.dart';

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

  Future<SessionLock?> unlockSession({
    required BuildContext context,
    required String sessionPath,
  }) async {
    // get the session
    var sessionJson = await FB().getJson(path: sessionPath);
    if (sessionJson.isEmpty) {
      Toaster().error("Unable to lock. Session not found");
      return null;
    }
    Session session = Session.fromJson(sessionJson);

    // check if user is admin
    List adminsRaw = await FB()
        .getList(path: "${Const().dbrootGaruda}/Settings/UserManagement/Admin");
    List<String> admins = adminsRaw.map((e) => e.toString()).toList();
    UserBasics? user = Utils().getUserBasics();
    if (user == null || user.name.isEmpty) {
      await Utils().fetchUserBasics();
      user = Utils().getUserBasics();
    }
    if (user == null) {
      Widgets().showMessage(context,
          "You cannot unlock the session. Please contact admin to do it.");
      return null;
    }
    if (!admins.contains(user.mobile)) {
      Widgets().showMessage(context,
          "You cannot unlock the session. Please contact admin to do it.");
      return null;
    }

    Widgets().showConfirmDialog(
        context,
        "Are you sure to unlock this session? Tickets can be added or modified after this.",
        "Unlock", () async {
      // push to fb
      SessionLock sessionLock;
      if (session.sessionLock == null) {
        sessionLock = SessionLock(
          isLocked: false,
          unlockedBy: user!.name,
          unlockedTime: DateTime.now(),
        );
      } else {
        sessionLock = session.sessionLock!;
        sessionLock.isLocked = false;
        sessionLock.unlockedBy = user!.name;
        sessionLock.unlockedTime = DateTime.now();
      }

      await FB().setJson(
          path: "$sessionPath/sessionLock", json: sessionLock.toJson());
    });
  }
}
