import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static final Utils _instance = Utils._internal();

  factory Utils() {
    return _instance;
  }

  Utils._internal() {
    // init
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

  String convertTimeStringTo12HrFormat(String time) {
    // check if 12 hr or 24 hr format
    if (time.contains("AM") || time.contains("PM")) {
      // 12-hr format
      return time;
    } else {
      // 24-hr format
      String part1 = time.split(":")[0];
      String part2 = time.split(":")[1];
      int hr = int.parse(part1);
      String ampm = "AM";
      if (hr >= 12) {
        ampm = "PM";
        if (hr > 12) {
          hr -= 12;
        }
      }
      return "$hr:$part2 $ampm";
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

  String getFestivalIcon(String festival) {
    for (var seva in festivalIcons) {
      if (seva['name'] == festival) {
        return seva['icon'] ?? "assets/images/Logo/KrishnaLilaPark_square.png";
      }
    }
    return "";
  }

  // input time is in format "07:30 PM" or "19:30"
  DateTime convertStringToTime(DateTime date, String time) {
    // check if 12 hr or 24 hr format
    if (time.contains("AM") || time.contains("PM")) {
      // 12-hr format
      return DateTime(
        date.year,
        date.month,
        date.day,
        convertTimeToHrMin(time)[0],
        convertTimeToHrMin(time)[1],
      );
    } else {
      // 24-hr format
      String part1 = time.split(":")[0];
      String part2 = time.split(":")[1];
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(part1),
        int.parse(part2),
      );
    }
  }

  // input time is in format "07:30 PM"
  // return [19, 30]
  List<int> convertTimeToHrMin(String time) {
    String part1 = time.split(":")[0];
    String part2 = time.split(":")[1];
    String part3 = part2.split(" ")[0];
    String part4 = part2.split(" ")[1];

    int hr = int.parse(part1);
    int min = int.parse(part3);
    if (part4 == "PM" && hr != 12) {
      hr += 12;
    } else if (part4 == "AM" && hr == 12) {
      hr = 0;
    }
    if (hr == 24) {
      hr = 0;
    }

    return [hr, min];
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

  Future<String> getFcmToken(String mobile) async {
    String token = await FB().getValue(
      path: "${Const().dbrootSangeetSeva}/Users/$mobile/fcmToken",
    );
    return token;
  }

  String getUsername() {
    return _userbasics?.name ?? "";
  }

  UserBasics? getUserBasics() {
    return _userbasics;
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

  bool isDateWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}
