class Session {
  final String name;
  final String defaultAmount;
  final String defaultPaymentMode;
  final String icon;
  final String sevakarta;
  DateTime timestamp;

  Session(
      {required this.name,
      required this.defaultAmount,
      required this.defaultPaymentMode,
      required this.icon,
      required this.sevakarta,
      required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'defaultAmount': defaultAmount,
      'defaultPaymentMode': defaultPaymentMode,
      'icon': icon,
      'sevakarta': sevakarta,
      'timestamp': timestamp,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      name: json['name'],
      defaultAmount: json['defaultAmount'],
      defaultPaymentMode: json['defaultPaymentMode'],
      icon: json['icon'],
      sevakarta: json['sevakarta'],
      timestamp: json['timestamp'].toDate(),
    );
  }
}
