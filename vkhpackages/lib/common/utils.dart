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
