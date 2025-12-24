class UserBasics {
  String name;
  final String mobile;

  UserBasics({required this.name, required this.mobile});

  factory UserBasics.fromJson(Map<String, dynamic> json) {
    return UserBasics(
      name: json['name'],
      mobile: json['mobile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'mobile': mobile};
  }
}

class FestivalSettings {
  final String name;
  final String icon;

  FestivalSettings({required this.name, required this.icon});

  factory FestivalSettings.fromJson(Map<String, dynamic> json) {
    return FestivalSettings(name: json['name'], icon: json['icon']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'icon': icon};
  }
}

class Ticket {
  final DateTime timestamp;
  final int amount;
  final String mode;
  int ticketNumber;
  final String user;
  final String note;
  final String seva;

  Ticket({
    required this.timestamp,
    required this.amount,
    required this.mode,
    required this.ticketNumber,
    required this.user,
    required this.note,
    required this.seva,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      timestamp: DateTime.parse(json['timestamp']),
      amount: json['amount'],
      mode: json['mode'],
      ticketNumber: json['ticketNumber'],
      user: json['user'],
      note: json['note'],
      seva: json['seva'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'mode': mode,
      'ticketNumber': ticketNumber,
      'user': user,
      'note': note,
      'seva': seva,
    };
  }
}

class Session {
  final String name;
  final String type;
  final int defaultAmount;
  final String defaultPaymentMode;
  final String icon;
  final String sevakarta;
  final DateTime timestamp;
  SessionLock? sessionLock;

  Session({
    required this.name,
    required this.type,
    required this.defaultAmount,
    required this.defaultPaymentMode,
    required this.icon,
    required this.sevakarta,
    required this.timestamp,
    this.sessionLock,
  });

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
      sessionLock:
          json['sessionLock'] == null
              ? null
              : SessionLock.fromJson(
                Map<String, dynamic>.from(json['sessionLock']),
              ),
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

  SessionLock({
    required this.isLocked,
    this.lockedBy,
    this.lockedTime,
    this.unlockedBy,
    this.unlockedTime,
  });

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
      lockedTime:
          json['lockedTime'] == null
              ? null
              : DateTime.parse(json['lockedTime']),
      unlockedBy: json['unlockedBy'],
      unlockedTime:
          json['unlockedTime'] == null
              ? null
              : DateTime.parse(json['unlockedTime']),
    );

    return sessionLock;
  }
}
