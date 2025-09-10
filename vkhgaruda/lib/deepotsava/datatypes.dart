class SalesEntry {
  final DateTime timestamp;
  String username;
  int count;
  String paymentMode;
  bool isPlateIncluded;

  SalesEntry({
    required this.timestamp,
    required this.username,
    required this.count,
    required this.paymentMode,
    required this.isPlateIncluded,
  });

  // Convert from JSON
  factory SalesEntry.fromJson(Map<String, dynamic> json) {
    return SalesEntry(
      timestamp: DateTime.parse(json['timestamp']),
      username: json['username'] ?? 'Unknown',
      count: json['count'],
      paymentMode: json['paymentMode'] ?? 'Unknown',
      isPlateIncluded: json['isPlateIncluded'] ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'username': username,
      'count': count,
      'paymentMode': paymentMode,
      'isPlateIncluded': isPlateIncluded,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SalesEntry) return false;
    return timestamp == other.timestamp &&
        username == other.username &&
        count == other.count &&
        paymentMode == other.paymentMode &&
        isPlateIncluded == other.isPlateIncluded;
  }

  @override
  int get hashCode =>
      Object.hash(timestamp, username, count, paymentMode, isPlateIncluded);
}

class InventoryEntry {
  int count;
  String note;
  final DateTime timestamp;
  String username;
  String malaType; // 'sale' or 'chanter'
  String addOrRemove; // 'Add' or 'Remove'

  InventoryEntry({
    required this.count,
    required this.timestamp,
    required this.note,
    required this.username,
    required this.malaType,
    required this.addOrRemove,
  });

  // Convert from JSON
  factory InventoryEntry.fromJson(Map<String, dynamic> json) {
    return InventoryEntry(
      count: json['count'],
      note: json['note'],
      timestamp: DateTime.parse(json['timestamp']),
      username: json['username'] ?? 'Unknown',
      malaType: json['malaType'] ?? 'Unknown',
      addOrRemove: json['addOrRemove'] ?? 'Unknown',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'username': username,
      'malaType': malaType,
      'addOrRemove': addOrRemove,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InventoryEntry) return false;
    return count == other.count &&
        note == other.note &&
        timestamp == other.timestamp &&
        malaType == other.malaType &&
        addOrRemove == other.addOrRemove &&
        username == other.username;
  }

  @override
  int get hashCode =>
      Object.hash(count, note, timestamp, malaType, addOrRemove, username);
}
