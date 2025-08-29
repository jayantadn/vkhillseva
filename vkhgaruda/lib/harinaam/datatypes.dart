import 'package:vkhpackages/vkhpackages.dart';

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

class SalesEntry {
  int count;
  Japamala japamala;
  final DateTime timestamp;
  String paymentMode;
  String username;

  SalesEntry({
    required this.count,
    required this.japamala,
    required this.timestamp,
    required this.paymentMode,
    required this.username,
  });

  // Convert from JSON
  factory SalesEntry.fromJson(Map<String, dynamic> json) {
    return SalesEntry(
      count: json['count'],
      japamala:
          Utils().convertRawToDatatype(json['japamala'], Japamala.fromJson),
      timestamp: DateTime.parse(json['timestamp']),
      paymentMode: json['paymentMode'] ?? 'Unknown',
      username: json['username'] ?? 'Unknown',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'japamala': japamala.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'paymentMode': paymentMode,
      'username': username,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SalesEntry) return false;
    return count == other.count &&
        japamala == other.japamala &&
        timestamp == other.timestamp &&
        paymentMode == other.paymentMode &&
        username == other.username;
  }

  @override
  int get hashCode =>
      Object.hash(count, japamala, timestamp, paymentMode, username);
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

class InventorySummary {
  int openingBalance;
  int discarded;
  int newAdditions;
  int closingBalance;

  InventorySummary({
    required this.openingBalance,
    required this.discarded,
    required this.newAdditions,
    required this.closingBalance,
  });

  // Convert from JSON
  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      openingBalance: json['openingBalance'],
      discarded: json['discarded'],
      newAdditions: json['newAdditions'],
      closingBalance: json['closingBalance'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'openingBalance': openingBalance,
      'discarded': discarded,
      'newAdditions': newAdditions,
      'closingBalance': closingBalance,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InventorySummary) return false;
    return openingBalance == other.openingBalance &&
        discarded == other.discarded &&
        newAdditions == other.newAdditions &&
        closingBalance == other.closingBalance;
  }

  @override
  int get hashCode =>
      Object.hash(openingBalance, discarded, newAdditions, closingBalance);
}
