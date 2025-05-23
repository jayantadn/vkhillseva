import 'package:vkhpackages/vkhpackages.dart';

class Session {
  final String name;
  final String type;
  final int defaultAmount;
  final String defaultPaymentMode;
  final String icon;
  final String sevakarta;
  final DateTime timestamp;
  SessionLock? sessionLock;

  Session(
      {required this.name,
      required this.type,
      required this.defaultAmount,
      required this.defaultPaymentMode,
      required this.icon,
      required this.sevakarta,
      required this.timestamp,
      SessionLock? sessionLock});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'defaultAmount': defaultAmount,
      'defaultPaymentMode': defaultPaymentMode,
      'icon': icon,
      'sevakarta': sevakarta,
      'timestamp': timestamp.toIso8601String(),
      'sessionLock': sessionLock?.toJson(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    Session session = Session(
      name: json['name'],
      type: json['type'],
      defaultAmount: json['defaultAmount'],
      defaultPaymentMode: json['defaultPaymentMode'],
      icon: json['icon'],
      sevakarta: json['sevakarta'],
      timestamp: DateTime.parse(json['timestamp']),
      sessionLock: json['sessionLock'] != null
          ? Utils().convertRawToDatatype(json['sessionLock'], SessionLock.fromJson)
          : null,
    );

    return session;
  }
}

class SessionLock {
  bool isLocked;
  String? lockedBy;
  DateTime? lockedTime;
  String? unlockedBy;
  DateTime? unlockedTime;

  SessionLock(
      {required this.isLocked,
      this.lockedBy,
      this.lockedTime,
      this.unlockedBy,
      this.unlockedTime});

  Map<String, dynamic> toJson() {
    return {
      'isLocked': isLocked,
      'lockedBy': lockedBy,
      'lockedTime': lockedTime?.toIso8601String(),
      'unlockedBy': unlockedBy,
      'unlockedTime': unlockedTime?.toIso8601String(),
    };
  }

  factory SessionLock.fromJson(Map<String, dynamic> json) {
    SessionLock sessionLock = SessionLock(
      isLocked: json['isLocked'],
      lockedBy: json['lockedBy'],
      lockedTime: json['lockedTime'] == null ? null : DateTime.parse(json['lockedTime']),
      unlockedBy: json['unlockedBy'],
      unlockedTime: json['unlockedTime'] == null ? null : DateTime.parse(json['unlockedTime']),
    );

    return sessionLock;
  }
}
