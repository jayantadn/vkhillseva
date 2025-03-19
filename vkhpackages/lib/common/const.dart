import 'package:flutter/material.dart';
import 'datatypes.dart';

class Const {
  static final Const _instance = Const._internal();

  factory Const() {
    return _instance;
  }

  Const._internal() {
    // init
  }

  final String dbrootGaruda = "TEST/GARUDA_01";
  final String dbrootTAS = "TEST/TAS_01";
  final String dbrootSangeetSeva = "TEST/SANGEETSEVA_01";

  final int fbListenerDelay = 2; // seconds
  final double toolbarIconSize = 32;
  final int morningCutoff = 14;
  final int maxImageSize = 500; // kB

  final List<Slot> weekendSangeetSevaSlots = [
    Slot(name: "MorningSlot", avl: true, from: "10:00 AM", to: "01:00 PM"),
    Slot(name: "EveningSlot", avl: true, from: "05:00 PM", to: "08:00 PM"),
  ];

  final nityaSeva = {
    'amounts': [
      {
        "400": {
          'color': Colors.blue,
          "sevas": [
            {"name": "Pushpanjali"},
          ],
          "obsolete": true,
        },
      },
      {
        "500": {
          'color': Colors.cyanAccent,
          "sevas": [
            {"name": "Tulasi Archana Seva"},
            {"name": "Jala-dana Seva"},
            {"name": "Sudharshana Chakra Puja"},
          ],
          "obsolete": false,
        },
      },
      {
        "600": {
          'color': Colors.yellow,
          "sevas": [
            {"name": "Tulasi Archana Seva"},
            {"name": "Jala-dana Seva"},
            {"name": "Sudharshana Chakra Puja"},
          ],
          "obsolete": false,
        },
      },
      {
        "1000": {
          'color': Colors.lightGreenAccent,
          "sevas": [
            {"name": "Mandir-marjana Seva"},
            {"name": "Naivedya Seva"},
            {"name": "Sadhu Seva"},
            {"name": "Shringara Seva"},
            {"name": "Trikala Puja"},
            {"name": "Tulasi Hara Seva"},
          ],
          "obsolete": false,
        },
      },
      {
        "2500": {
          'color': Colors.pinkAccent[100],
          "sevas": [
            {"name": "Gita-Dana Seva"},
            {"name": "Pushpalankara Seva"},
            {"name": "Sadhu Bhojana Seva"},
            {"name": "Shodashopachara Seva"},
          ],
        },
      },
    ],
  };

  final paymentModes = {
    'Cash': {'icon': "assets/images/PaymentModes/icon_cash.png"},
    'UPI': {'icon': "assets/images/PaymentModes/icon_upi.png"},
    'Card': {'icon': "assets/images/PaymentModes/icon_card.png"},
    'Gift': {'icon': "assets/images/PaymentModes/icon_gift.png"},
  };

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
