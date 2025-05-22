class Ticket {
  final DateTime timestamp;
  final int amount;
  final String mode;
  final int ticketNumber;
  final String user;
  final String note;
  final String seva;

  Ticket(
      {required this.timestamp,
      required this.amount,
      required this.mode,
      required this.ticketNumber,
      required this.user,
      required this.note,
      required this.seva});

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
