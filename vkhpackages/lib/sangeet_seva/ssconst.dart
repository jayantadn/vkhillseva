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
    Slot(name: "MorningSlot1", avl: true, from: "10:30 AM", to: "11:30 AM"),
    Slot(name: "MorningSlot2", avl: true, from: "11:30 AM", to: "12:30 PM"),
    Slot(name: "EveningSlot1", avl: true, from: "05:30 PM", to: "06:45 PM"),
    Slot(name: "EveningSlot2", avl: true, from: "07:15 PM", to: "08:30 PM"),
  ];

  final List<Map<String, dynamic>> aartiTimings = [
    // {"name": "Sandhya Aarti", "from": "07:00 PM", "to": "07:15 PM"},
  ];

  final maxEventDuration = 60; // mins
}
