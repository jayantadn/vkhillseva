import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhillseva/common/local_storage.dart';

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

  Future<String> getUsername(context) async {
    String? username = await LS().read('username');
    if (username != null) {
      return username;
    } else {
      // prompt for username
      TextEditingController usernameController = TextEditingController();
      username = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Please enter your name'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(hintText: "Username"),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    if (usernameController.text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Username is required',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                );
              },
            ),
            actions: <Widget>[
              TextButton(
                onPressed: usernameController.text.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop(usernameController.text);
                      },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

      if (username == null || username.isEmpty) {
        return "Guest";
      } else {
        await LS().write('username', username);
        return username;
      }
    }
  }
}
