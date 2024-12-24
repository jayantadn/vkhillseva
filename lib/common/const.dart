import 'package:flutter/material.dart';

class Const {
  static final Const _instance = Const._internal();

  factory Const() {
    return _instance;
  }

  Const._internal() {
    // init
  }

  final String dbroot = "VKHILLSEVA_01";
  final String version = "0.3.0";

  final int fbListenerDelay = 2; // seconds

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
  ];

  final nityaSeva = {
    'amounts': [
      {
        "400": {'color': Colors.blue}
      },
      {
        "500": {'color': Colors.green}
      },
      {
        "1000": {'color': Colors.yellow}
      },
      {
        "2500": {'color': Colors.pink}
      },
    ]
  };

  final paymentModes = {
    'Cash': {'icon': "assets/images/PaymentModes/icon_cash.png"},
    'UPI': {'icon': "assets/images/PaymentModes/icon_upi.png"},
    'Card': {'icon': "assets/images/PaymentModes/icon_card.png"},
    'Gift': {'icon': "assets/images/PaymentModes/icon_gift.png"},
  };
}
