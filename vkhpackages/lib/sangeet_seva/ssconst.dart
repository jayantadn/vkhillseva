import 'package:vkhpackages/sangeet_seva/ssdatatypes.dart';

class SSConst {
  static final SSConst _instance = SSConst._internal();

  factory SSConst() {
    return _instance;
  }

  SSConst._internal() {
    // init
  }
  final List<String> salutations = [
    'Shri',
    'Smt',
    'Kumar',
    'Kumari',
    'Vidwan',
    'Vidushi',
    'Chiranjeevi',
    'Others',
  ];

  final List<String> vocalSkills = [
    'Hindustani',
    'Carnatic',
    'Western',
    'Bhajan Mandali',
    'Semi classical',
    'Sugam Sangeet',
    'Others',
  ];

  final List<String> instrumentSkills = [
    'Veena',
    'Flute',
    'Tabla',
    'Mridangam',
    'Harmonium',
    'Kartaal',
    'Violin',
    'Keyboard',
    'Other',
  ];

  final List<Slot> weekendSangeetSevaSlots = [
    Slot(name: "MorningSlot", avl: true, from: "10:30 AM", to: "01:00 PM"),
    Slot(name: "EveningSlot", avl: true, from: "05:00 PM", to: "08:00 PM"),
  ];

  final List<Map<String, dynamic>> aartiTimings = [
    {"name": "Sandhya Aarti", "from": "07:00 PM", "to": "07:15 PM"},
  ];

  final maxEventDuration = 60; // mins
}
