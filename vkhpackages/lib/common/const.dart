import 'package:flutter/material.dart';

class Const {
  static final Const _instance = Const._internal();

  factory Const() {
    return _instance;
  }

  Const._internal() {
    // init
  }

  final version = "9.0.0";

  final String dbrootGaruda = "GARUDA_01";
  final String dbrootSangeetSeva = "SANGEETSEVA_01";

  final int fbListenerDelay = 2; // seconds
  final double toolbarIconSize = 32;
  final int morningCutoff = 14;
  final int eveningCutoff = 21;
  final int maxImageSize = 500; // kB
  final String delimiter = "~";
  final int sessionLockDuration = 5; // hours

  // harinaam
  String weeklyHarinaamSettlementDay = "Monday";

  final nityaSeva = {
    'amounts': [
      {
        "400": {
          'color': Colors.cyan,
          "sevas": [
            {"name": "Pushpanjali"},
          ],
          "obsolete": true,
        },
      },
      {
        "500": {
          'color': Colors.blue,
          "sevas": [
            {"name": "Pushpanjali Seva"},
          ],
          "obsolete": false,
        },
      },
      {
        "600": {
          'color': Colors.green,
          "sevas": [
            {"name": "Tulasi Archana Seva"},
          ],
          "obsolete": false,
        },
      },
      {
        "1000": {
          'color': Colors.yellow[800],
          "sevas": [
            {"name": "Naivedya Seva"},
            {"name": "Sadhu Seva"},
          ],
          "obsolete": false,
        },
      },
      {
        "2500": {
          'color': Colors.pink,
          "sevas": [
            {"name": "Pushpalankara Seva"},
            {"name": "Sadhu Bhojana Seva"},
          ],
          "obsolete": false,
        },
      },
    ],
  };

  final paymentModes = {
    'Cash': {
      'icon': "assets/images/PaymentModes/icon_cash.png",
      'color': const Color.fromARGB(255, 65, 154, 68),
    },
    'UPI': {
      'icon': "assets/images/PaymentModes/icon_upi.png",
      'color': const Color(0xFFE65100),
    },
    'Card': {
      'icon': "assets/images/PaymentModes/icon_card.png",
      'color': const Color.fromARGB(255, 22, 76, 163),
    },
    'Gift': {
      'icon': "assets/images/PaymentModes/icon_gift.png",
      'color': const Color.fromARGB(255, 127, 33, 143),
    },
  };

  final Map<String, dynamic> deepotsava = {'deepamPrice': 5, 'platePrice': 10};

  final List<String> icons = [
    "assets/images/Logo/KrishnaLilaPark_circle.png",
    "assets/images/Logo/KrishnaLilaPark_square.png",
    "assets/images/LauncherIcons/NityaSeva.png",
    "assets/images/LauncherIcons/Deepotsava.png",
    "assets/images/LauncherIcons/Harinaam.png",
    "assets/images/Common/morning.png",
    "assets/images/Common/evening.png",
    "assets/images/Common/add.png",
    "assets/images/Festivals/RamNavami.png",
    "assets/images/Festivals/Balarama.png",
    "assets/images/Festivals/AkshayaTritiya.png",
    "assets/images/Festivals/Garuda.png",
    "assets/images/Festivals/Govardhana.png",
    "assets/images/Festivals/Vamana.png",
    "assets/images/Festivals/GaurNitai.png",
    "assets/images/Festivals/HanumanJayanti.png",
    "assets/images/Festivals/JhulanUtsava.png",
    "assets/images/Festivals/NarasimhaChaturdashi.png",
    "assets/images/Festivals/NityanandaTrayodashi.png",
    "assets/images/Festivals/RathaYatra.png",
    "assets/images/Festivals/VyasaPuja.png",
    "assets/images/VKHillDieties/Garuda.png",
    "assets/images/VKHillDieties/Govinda.png",
    "assets/images/VKHillDieties/Hanuman.png",
    "assets/images/VKHillDieties/Jagannatha.png",
    "assets/images/VKHillDieties/LakshmiNarasimha.png",
    "assets/images/VKHillDieties/Narasimha.png",
    "assets/images/VKHillDieties/NitaiGauranga.png",
    "assets/images/VKHillDieties/Padmavati.png",
    "assets/images/VKHillDieties/Prabhupada.png",
    "assets/images/VKHillDieties/RadhaKrishna.png",
    "assets/images/VKHillDieties/Sudarshana.png",
    "assets/images/PaymentModes/icon_card.png",
    "assets/images/PaymentModes/icon_cash.png",
    "assets/images/PaymentModes/icon_gift.png",
    "assets/images/PaymentModes/icon_upi.png",
    "assets/images/NityaSeva/flower_garland.png",
    "assets/images/NityaSeva/gita.png",
    "assets/images/NityaSeva/sadhu_bhojana.png",
    "assets/images/NityaSeva/ShodashopacharaSeva.png",
    "assets/images/NityaSeva/tulasi_garland.png",
    "assets/images/NityaSeva/vishnu_pushpanjali.png",
    "assets/images/NityaSeva/tas.png",
    "assets/images/NityaSeva/JalaDana.png",
    "assets/images/NityaSeva/laddu.png",
    "assets/images/NityaSeva/sadhu_seva.png",
  ];
}
