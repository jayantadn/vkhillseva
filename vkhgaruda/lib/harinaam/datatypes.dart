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
}
