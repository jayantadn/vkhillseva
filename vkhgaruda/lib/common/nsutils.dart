import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:vkhgaruda/common/datatypes.dart';
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

  Future<String?> getLastActiveNityaSeva() async {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month - 1, 1);
    Map<String, dynamic> sessions = await FB().getValuesByDateRange(
        path: "${Const().dbrootGaruda}/NityaSeva", startDate: startDate);

    if (sessions.isEmpty) {
      Toaster().error("No sessions found in the last month");
      return null;
    }

    List<String> sessionKeys = sessions.keys.toList();
    sessionKeys.sort();

    for (int i = sessionKeys.length - 1; i >= 0; i--) {
      String key = sessionKeys[i];
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
        continue;
      }
      var value = sessions[key];

      // If value is a nested map, traverse deeper
      if (value is Map && value.isNotEmpty) {
        // Get the last key in the nested map
        var nestedKeys = value.keys.toList();
        nestedKeys.sort();

        for (int i = nestedKeys.length - 1; i >= 0; i--) {
          var k = nestedKeys[i];
          var s = value[k];

          if (s is Map && s.isNotEmpty) {
            if (s['Tickets'] != null && s['Tickets'].isNotEmpty) {
              Session session =
                  Utils().convertRawToDatatype(s['Settings'], Session.fromJson);
              if (session.name == "Nitya Seva") {
                return "${Const().dbrootGaruda}/NityaSeva/$key/$k";
              }
            }
          }
        }
      }
    }

    return null;
  }

  Future<SessionLock?> lockSession(
      {required BuildContext context,
      required String sessionPath,
      String? username}) async {
    SessionLock? sessionLock;

    await Widgets().showConfirmDialog(
        context,
        "Are you sure to lock this session? Tickets cannot be added or modified after this.",
        "Lock", () async {
      // get the session
      var sessionJson = await FB().getJson(path: "$sessionPath/Settings");
      if (sessionJson.isEmpty) {
        Toaster().error("Unable to lock. Session not found");
        return null;
      }
      Session session = Session.fromJson(sessionJson);

      sessionLock = session.sessionLock;
      if (sessionLock == null) {
        sessionLock = SessionLock(
          isLocked: true,
        );
      } else {
        sessionLock!.isLocked = true;
      }
      sessionLock!.lockedBy = username ?? "Autolock";
      sessionLock!.lockedTime = DateTime.now();

      // push to fb
      await FB().setJson(
          path: "$sessionPath/Settings/sessionLock",
          json: sessionLock!.toJson());

      // store the last used ticket numbers
      if (session.name == "Nitya Seva") {
        String? lastActiveSessionPath = await getLastActiveNityaSeva();
        if (sessionPath == lastActiveSessionPath) {
          // locking only the last active session will update ticket numbers
          String ticketNumbersPath =
              "${Const().dbrootGaruda}/NityaSeva/NextTicketNumbers";
          Map<String, dynamic> nextTicketNumbers =
              await FB().getJson(path: ticketNumbersPath, silent: true);
          String ticketsPath = "$sessionPath/Tickets";

          var t = await FB().getJson(path: ticketsPath, silent: true);
          if (t.isNotEmpty) {
            for (var entry in t.entries) {
              Ticket ticket =
                  Utils().convertRawToDatatype(entry.value, Ticket.fromJson);
              String key = ticket.amount.toString();
              int value = nextTicketNumbers[key] ?? 1;
              if (ticket.ticketNumber >= value) {
                nextTicketNumbers[key] = ticket.ticketNumber + 1;
              }
            }
            await FB()
                .setJson(path: ticketNumbersPath, json: nextTicketNumbers);
          }
        }
      }
    });

    return sessionLock;
  }

  Future<SessionLock?> unlockSession({
    required BuildContext context,
    required String sessionPath,
  }) async {
    // get the session
    var sessionJson = await FB().getJson(path: "$sessionPath/Settings");
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

    SessionLock? sessionLock;

    await Widgets().showConfirmDialog(
        context,
        "Are you sure to unlock this session? Tickets can be added or modified after this.",
        "Unlock", () async {
      // push to fb

      if (session.sessionLock == null) {
        sessionLock = SessionLock(
          isLocked: false,
          unlockedBy: user!.name,
          unlockedTime: DateTime.now(),
        );
      } else {
        sessionLock = session.sessionLock!;
        sessionLock!.isLocked = false;
        sessionLock!.unlockedBy = user!.name;
        sessionLock!.unlockedTime = DateTime.now();
      }

      await FB().setJson(
          path: "$sessionPath/Settings/sessionLock",
          json: sessionLock!.toJson());
    });

    return sessionLock;
  }
}
