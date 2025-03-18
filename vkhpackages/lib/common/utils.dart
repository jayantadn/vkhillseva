import 'dart:convert';
import 'dart:math';
import 'dart:js_interop'; // Add this import
import 'package:flutter/foundation.dart';
import 'package:web/web.dart'; //
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<String> checkForUpdates(String appname) async {
    String version = "";

    if (kIsWeb) {
      String versionUrl = "https://$appname.web.app/version.json";
      const String localVersionKey = "app_version";

      try {
        final response = await http.get(
          Uri.parse(versionUrl),
          headers: {'Cache-Control': 'no-cache'},
        );

        if (response.statusCode == 200) {
          final remoteVersion = json.decode(response.body)['version'];
          String? localVersion = await LS().read(localVersionKey);

          if (localVersion != null && localVersion != remoteVersion) {
            // Force refresh the web app using JS interop
            Toaster().info("Updating app");
            Future.delayed(Duration(milliseconds: 500), () {
              jsReloadPage();
            });
          }

          LS().write(localVersionKey, remoteVersion);
          version = remoteVersion;
        }
      } catch (e) {
        // print("Error checking version: $e");
      }
    }

    return version;
  }

  T convertRawToDatatype<T>(
    Map raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    return fromJson(map);
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

  Future<UserDetails?> getUserDetails(String mobile) async {
    var userDetailsRaw = await FB().getValue(
      path: "${Const().dbrootSangeetSeva}/Users/$mobile",
    );

    if (userDetailsRaw == null || userDetailsRaw.isEmpty) {
      return null;
    }

    return convertRawToDatatype(userDetailsRaw, UserDetails.fromJson);
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

  Widget responsiveBuilder(BuildContext context, List<Widget> children) {
    double maxWidth = 300;

    final double screenWidth = MediaQuery.of(context).size.width;
    maxWidth =
        (screenWidth > maxWidth && screenWidth < maxWidth * 2)
            ? screenWidth
            : maxWidth;

    return Wrap(
      spacing: 10,
      runSpacing: 20,
      children: [
        for (var child in children)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
      ],
    );
  }

  Future<void> setUserBasics(UserBasics userbasics) async {
    _userbasics = userbasics;
    await LS().write('userbasics', jsonEncode(userbasics.toJson()));
  }

  Future<void> setUserDetails(UserDetails details) async {
    String dbpath = "${Const().dbrootSangeetSeva}/Users/${details.mobile}";
    await FB().setJson(path: dbpath, json: details.toJson());
  }

  bool isDateWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}

// Add this helper function for JS interop
@JS('location.reload')
external void jsReloadPage();
