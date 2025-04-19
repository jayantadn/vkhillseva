class Session {
  final String name;
  final String type;
  final int defaultAmount;
  final String defaultPaymentMode;
  final String icon;
  final String sevakarta;
  final DateTime timestamp;

  Session(
      {required this.name,
      required this.type,
      required this.defaultAmount,
      required this.defaultPaymentMode,
      required this.icon,
      required this.sevakarta,
      required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'defaultAmount': defaultAmount,
      'defaultPaymentMode': defaultPaymentMode,
      'icon': icon,
      'sevakarta': sevakarta,
      'timestamp': timestamp.toIso8601String(),
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
    );

    return session;
  }
}
