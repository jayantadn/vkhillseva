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
