import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Utils {
  static final Utils _instance = Utils._internal();

  factory Utils() {
    return _instance;
  }

  Utils._internal() {
    // init
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

  Future<void> fetchFestivalIcons() async {
    if (festivalIcons.isEmpty) {
      List sevaListRaw = await FB().getList(path: "Settings/NityaSevaList");
      for (var sevaRaw in sevaListRaw) {
        Map<String, dynamic> sevaMap = Map<String, dynamic>.from(sevaRaw);
        festivalIcons.add({'name': sevaMap['name'], 'icon': sevaMap['icon']});
      }
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

  Future<void> fetchUserBasics() async {
    final String? u = await LS().read('userbasics');
    if (u != null) {
      _userbasics = UserBasics.fromJson(jsonDecode(u));
    } else {
      _userbasics = null;
    }
  }

  String getUsername() {
    return _userbasics?.name ?? "";
  }

  UserBasics? getUserBasics() {
    return _userbasics;
  }

  Widget buildWrappable(Widget child) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 300),
      child: child,
    );
  }

  Widget responsiveBuilder(List<Widget> children) {
    return Wrap(
      spacing: 10,
      runSpacing: 20,
      children: [
        for (var child in children)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            child: child,
          ),
      ],
    );
  }
}
