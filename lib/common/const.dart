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
  final String version = "0.7.0";

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

  final nityaSeva = {
    'amounts': [
      {
        "400": {
          'color': Colors.blue,
          "sevas": [
            {
              "name": "Pushpanjali",
              "icon": "assets/images/NityaSeva/vishnu_pushpanjali.png"
            }
          ]
        }
      },
      {
        "500": {
          'color': Colors.deepOrange,
          "sevas": [
            {
              "name": "Tulasi Archana Seva",
              "icon": "assets/images/NityaSeva/tas.png"
            },
            {
              "name": "Jala-dana Seva",
              "icon": "assets/images/NityaSeva/JalaDana.png"
            },
            {
              "name": "Sudharshana Chakra Puja",
              "icon": "assets/images/VKHillDieties/Sudarshana.png"
            }
          ]
        }
      },
      {
        "1000": {
          'color': Colors.green,
          "sevas": [
            {
              "name": "Mandir-marjana Seva",
              "icon": "assets/images/Logo/KrishnaLilaPark_square.png"
            },
            {
              "name": "Naivedya Seva",
              "icon": "assets/images/NityaSeva/laddu.png"
            },
            {
              "name": "Sadhu Seva",
              "icon": "assets/images/NityaSeva/sadhu_seva.png"
            },
            {
              "name": "Shringara Seva",
              "icon": "assets/images/VKHillDieties/Govinda.png"
            },
            {
              "name": "Trikala Puja",
              "icon": "assets/images/LauncherIcons/NityaSeva.png"
            },
            {
              "name": "Tulasi Hara Seva",
              "icon": "assets/images/NityaSeva/tulasi_garland.png"
            },
          ]
        }
      },
      {
        "2500": {
          'color': Colors.pink,
          "sevas": [
            {
              "name": "Gita-Dana Seva",
              "icon": "assets/images/NityaSeva/gita.png"
            },
            {
              "name": "Pushpalankara Seva",
              "icon": "assets/images/NityaSeva/flower_garland.png"
            },
            {
              "name": "Sadhu Bhojana Seva",
              "icon": "assets/images/NityaSeva/sadhu_bhojana.png"
            },
            {
              "name": "Shodashopachara Seva",
              "icon": "assets/images/NityaSeva/ShodashopacharaSeva.png"
            },
          ]
        }
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
