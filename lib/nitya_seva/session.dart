class Session {
  final String seva;
  final String defaultAmount;
  final String defaultPaymentMode;
  final String icon;
  final String sevakarta;
  DateTime timestamp;

  Session(
      {required this.seva,
      required this.defaultAmount,
      required this.defaultPaymentMode,
      required this.icon,
      required this.sevakarta,
      required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'seva': seva,
      'defaultAmount': defaultAmount,
      'defaultPaymentMode': defaultPaymentMode,
      'icon': icon,
      'sevakarta': sevakarta,
      'timestamp': timestamp,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      seva: json['seva'],
      defaultAmount: json['defaultAmount'],
      defaultPaymentMode: json['defaultPaymentMode'],
      icon: json['icon'],
      sevakarta: json['sevakarta'],
      timestamp: json['timestamp'].toDate(),
    );
  }
}
