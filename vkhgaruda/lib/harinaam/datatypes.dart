class ChantersEntry {
  DateTime timestamp;
  String username;
  int count;

  ChantersEntry({
    required this.timestamp,
    required this.username,
    required this.count,
  });

  // Convert from JSON
  factory ChantersEntry.fromJson(Map<String, dynamic> json) {
    return ChantersEntry(
      timestamp: DateTime.parse(json['timestamp']),
      username: json['username'],
      count: json['count'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'username': username,
      'count': count,
    };
  }

  // Override == operator for value equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChantersEntry) return false;
    return timestamp == other.timestamp &&
        username == other.username &&
        count == other.count;
  }

  // Override hashCode (must be consistent with ==)
  @override
  int get hashCode => Object.hash(timestamp, username, count);
}

class Japamala {
  String name;
  int saleValue;
  String colorHex;

  Japamala({
    required this.name,
    required this.saleValue,
    required this.colorHex,
  });

  // Convert from JSON
  factory Japamala.fromJson(Map<String, dynamic> json) {
    return Japamala(
      name: json['name'],
      saleValue: json['saleValue'],
      colorHex: json['colorHex'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'saleValue': saleValue,
      'colorHex': colorHex,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Japamala) return false;
    return name == other.name &&
        saleValue == other.saleValue &&
        colorHex == other.colorHex;
  }

  @override
  int get hashCode => Object.hash(name, saleValue, colorHex);
}
