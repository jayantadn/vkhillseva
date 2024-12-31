import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Utils {
  static final Utils _instance = Utils._internal();

  factory Utils() {
    return _instance;
  }

  Utils._internal() {
    // init
  }

  String formatIndianCurrency(String amount) {
    final formatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final number = int.parse(amount.replaceAll(RegExp(r'[^\d]'), ''));
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

  Color getRandomLightColor() {
    return lightColors[DateTime.now().millisecond % lightColors.length];
  }

  String getUserName() {
    return "Guest";
  }
}
