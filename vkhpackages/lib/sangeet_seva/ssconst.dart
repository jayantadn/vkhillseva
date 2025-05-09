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
    Slot(name: "MorningSlot", avl: true, from: "10:00 AM", to: "01:00 PM"),
    Slot(name: "EveningSlot", avl: true, from: "05:00 PM", to: "08:00 PM"),
  ];

  final maxEventDuration = 90; // mins

  // temple notes
  final List<String> templeNotes = [
    "All artists can come up the Hill directly through their respective vehicle",
    "Please inform the security personnel that they are performing the Sangeetha Seva at the  Govinda temple this evening",
    "Can use the escalator/lift",
    "Share the vehicle number(s)",
    "Contact Securtiy Kamal near Garuda temple for the facilities",
    "Tune your musicial instruments well in advance",
    "Mike testing and adjustments should be done well in advance",
    "Sengeet Seva will be closed between 6:45pm and 7:15pm",
    "You can attend the 7pm arati and visit all other parivara temples( can be done earlier itself)",
    "Participate in sankalpa, arati and receive the phala-pushpa prasadam",
    "Dinner prasada for the artists (10 person) will be arranged",
    "Note: our temple devotee will address for a minute before the start of the seva",
  ];
}
