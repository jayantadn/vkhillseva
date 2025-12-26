import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Utils {
  static final Utils _instance = Utils._internal();

  factory Utils() {
    return _instance;
  }

  Utils._internal() {
    // init
  }

  Future<void> checkForUpdate(
    BuildContext context, {
    String app = "garuda",
  }) async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(hours: 6),
      ),
    );

    await remoteConfig.fetchAndActivate();

    bool triggerUpdate = remoteConfig.getBool('${app}_trigger_update');
    if (triggerUpdate) {
      String remoteVersion = remoteConfig.getString('${app}_version');
      int remoteVersionSuffix = remoteConfig.getInt('${app}_version_suffix');

      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = int.parse(packageInfo.buildNumber);

      if (remoteVersionSuffix > localVersion) {
        // update detected
        if (context.mounted) {
          Widgets().showConfirmDialog(
            context,
            "New version available: $remoteVersion",
            "Update",
            () {
              // update logic: open URL
            },
          );
        }
      }
    }

    return;
  }

  Future<bool> checkPermission(String seva) async {
    UserBasics? basics = getUserBasics();
    if (basics == null) {
      await fetchUserBasics();
      basics = getUserBasics();
      if (basics == null) {
        Toaster().error("Could not fetch user details");
        return false;
      }
    }

    List mobiles = await FB().getList(
      path: "${Const().dbrootGaruda}/Settings/UserManagement/$seva",
    );
    if (mobiles.isNotEmpty && mobiles.contains(basics.mobile)) {
      return true;
    } else {
      return false;
    }
  }

  T convertRawToDatatype<T>(
    Map raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    return fromJson(map);
  }

  Map<String, dynamic> convertRawToJson(dynamic raw) {
    if (raw is Map) {
      Map<String, dynamic> map = Map<String, dynamic>.from(raw);
      return map;
    } else {
      throw Exception("Raw data is not a Map");
    }
  }

  Future<void> fetchFestivalIcons() async {
    if (festivalIcons.isEmpty) {
      List sevaListRaw = await FB().getList(path: "Settings/NityaSevaList");
      for (var sevaRaw in sevaListRaw) {
        Map<String, dynamic> sevaMap = Map<String, dynamic>.from(sevaRaw);
        festivalIcons.add({'name': sevaMap['name'], 'icon': sevaMap['icon']});
      }
    }
  }

  Future<void> fetchUserBasics() async {
    final String? u = await LS().read('userbasics');
    if (u != null) {
      _userbasics = UserBasics.fromJson(jsonDecode(u));
    } else {
      _userbasics = null;
    }
  }

  Future<UserBasics?> fetchOrGetUserBasics() async {
    if (_userbasics == null) {
      await fetchUserBasics();
    }
    return _userbasics;
  }

  Future<bool> getAdminStatus() async {
    UserBasics? basics = await fetchOrGetUserBasics();
    if (basics != null) {
      List adminsRaw = await FB().getList(
        path: "${Const().dbrootGaruda}/Settings/UserManagement/Admin",
      );
      List<String> admins = adminsRaw.map((e) => e.toString()).toList();
      if (admins.contains(basics.mobile)) {
        return true;
      }
    }

    return false;
  }

  String getFestivalIcon(String festival) {
    for (var seva in festivalIcons) {
      if (seva['name'] == festival) {
        return seva['icon'] ?? "assets/images/Logo/KrishnaLilaPark_square.png";
      }
    }
    return "";
  }

  final List<Color> darkColors = [
    Colors.lightGreen,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.deepPurpleAccent,
    Colors.lightBlueAccent,
    Colors.indigoAccent,
    Colors.brown,
    Colors.blueGrey,
    Colors.black,
    Colors.grey,
    Colors.deepOrange,
    Colors.teal,
    Colors.cyan,
    Colors.orange,
  ];
  Color getRandomDarkColor() {
    final random = Random();
    return darkColors[random.nextInt(darkColors.length)];
  }

  final List<Color> lightColors = [
    Colors.greenAccent,
    Colors.lightBlueAccent,
    Colors.lightGreenAccent,
    Colors.amberAccent,
    Colors.tealAccent,
    const Color.fromARGB(255, 153, 249, 249),
    Colors.limeAccent,
    Color.fromARGB(255, 255, 169, 169),
    const Color.fromARGB(255, 248, 139, 175),
    Color.fromARGB(255, 235, 124, 255),
  ];

  List<Map<String, String>> festivalIcons = [];
  UserBasics? _userbasics;

  Color getRandomLightColor() {
    return lightColors[DateTime.now().millisecond % lightColors.length];
  }

  String formatIndianCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final number = int.parse(
      amount.toString().replaceAll(RegExp(r'[^\d]'), ''),
    );
    return formatter.format(number);
  }

  String getUsername() {
    return _userbasics?.name ?? "";
  }

  UserBasics? getUserBasics() {
    return _userbasics;
  }

  void printType(dynamic value) {
    print("${value.runtimeType}: $value");
  }

  Future<void> sendWhatsAppMessage(String phoneNumber, String message) async {
    final url = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Toaster().error('Could not launch WhatsApp');
    }
  }

  Future<void> setUserBasics(UserBasics userbasics) async {
    _userbasics = userbasics;
    await LS().write('userbasics', jsonEncode(userbasics.toJson()));
  }

  Future<void> setUserDetails(PerformerProfile details) async {
    String dbpath = "${Const().dbrootSangeetSeva}/Users/${details.mobile}";
    await FB().setJson(path: dbpath, json: details.toJson());
  }

  Future<bool> isAdmin() async {
    UserBasics? basics = getUserBasics();
    if (basics == null) {
      await fetchUserBasics();
      basics = getUserBasics();
      if (basics == null) {
        Toaster().error("Could not fetch user details");
        return false;
      }
    }

    List adminsRaw = await FB().getList(
      path: "${Const().dbrootGaruda}/Settings/UserManagement/Admin",
    );
    List<String> admins = adminsRaw.map((e) => e.toString()).toList();
    if (admins.isNotEmpty && admins.contains(basics.mobile)) {
      return true;
    } else {
      return false;
    }
  }

  bool isDateWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  Future<String?> getLastActiveNityaSeva() async {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month - 1, 1);
    Map<String, dynamic> sessions = await FB().getValuesByDateRange(
      path: "${Const().dbrootGaruda}/NityaSeva",
      startDate: startDate,
    );

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
              Session session = Utils().convertRawToDatatype(
                s['Settings'],
                Session.fromJson,
              );
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

  Future<SessionLock?> lockSession({
    required BuildContext context,
    required String sessionPath,
    String? username,
    bool? silent,
  }) async {
    bool? confirm;

    if (silent == null || (!silent)) {
      confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Lock Session'),
            content: const Text('Are you sure you want to lock this session?'),
            actions: <Widget>[
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        },
      );
    } else {
      confirm = true;
    }

    if (confirm != true) {
      return null;
    }

    SessionLock? sessionLock;

    // get the session
    var sessionJson = await FB().getJson(path: "$sessionPath/Settings");
    if (sessionJson.isEmpty) {
      Toaster().error("Unable to lock. Session not found");
      return null;
    }
    Session session = Session.fromJson(sessionJson);

    sessionLock = session.sessionLock;
    if (sessionLock == null) {
      sessionLock = SessionLock(isLocked: true);
    } else {
      sessionLock.isLocked = true;
    }
    sessionLock.lockedBy = username ?? "Autolock";
    sessionLock.lockedTime = DateTime.now();

    // push to fb
    await FB().setJson(
      path: "$sessionPath/Settings/sessionLock",
      json: sessionLock.toJson(),
    );

    // store the last used ticket numbers
    if (session.name == "Nitya Seva") {
      // locking only the last active session will update ticket numbers
      String? lastActiveSessionPath = await getLastActiveNityaSeva();
      if (sessionPath == lastActiveSessionPath) {
        String ticketNumbersPath =
            "${Const().dbrootGaruda}/NityaSeva/NextTicketNumbers";
        Map<String, dynamic> nextTicketNumbers = await FB().getJson(
          path: ticketNumbersPath,
          silent: true,
        );

        String ticketsPath = "$sessionPath/Tickets";
        var t = await FB().getJson(path: ticketsPath, silent: true);
        if (t.isNotEmpty) {
          List<Ticket> tickets =
              t.entries
                  .map(
                    (entry) => Utils().convertRawToDatatype(
                      entry.value,
                      Ticket.fromJson,
                    ),
                  )
                  .toList();
          tickets.sort((a, b) => a.ticketNumber.compareTo(b.ticketNumber));
          for (Ticket ticket in tickets) {
            String amount = ticket.amount.toString();
            int storedTicketNumber =
                int.tryParse(nextTicketNumbers[amount].split(":").last) ?? 1;
            if (ticket.ticketNumber >= storedTicketNumber) {
              String storedBookNumber =
                  nextTicketNumbers[amount].split(":").first;
              int nextBookNumber = int.tryParse(storedBookNumber) ?? 1;
              if (ticket.ticketNumber % 100 == 0) {
                nextBookNumber++;
              }
              nextTicketNumbers[amount] =
                  "$nextBookNumber:${ticket.ticketNumber + 1}";
            }
          }
          await FB().setJson(path: ticketNumbersPath, json: nextTicketNumbers);
        }
      }
    }
    ;

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
    List adminsRaw = await FB().getList(
      path: "${Const().dbrootGaruda}/Settings/UserManagement/Admin",
    );
    List<String> admins = adminsRaw.map((e) => e.toString()).toList();
    UserBasics? user = Utils().getUserBasics();
    if (user == null || user.name.isEmpty) {
      await Utils().fetchUserBasics();
      user = Utils().getUserBasics();
    }
    if (user == null) {
      Widgets().showMessage(
        context,
        "You cannot unlock the session. Please contact admin to do it.",
      );
      return null;
    }
    if (!admins.contains(user.mobile)) {
      Widgets().showMessage(
        context,
        "You cannot unlock the session. Please contact admin to do it.",
      );
      return null;
    }

    SessionLock? sessionLock;

    await Widgets().showConfirmDialog(
      context,
      "Are you sure to unlock this session? Tickets can be added or modified after this.",
      "Unlock",
      () async {
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
          json: sessionLock!.toJson(),
        );
      },
    );

    return sessionLock;
  }
}
