import 'dart:async';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:vkhgaruda/nitya_seva/laddu/datatypes.dart';

class FBL {
  static FBL? _instance;
  static Map<String, String> keyCache = {};

  StreamSubscription? _sevaSlotAddedSubscription;
  StreamSubscription? _sevaSlotChangedSubscription;
  StreamSubscription? _sevaSlotRemovedSubscription;

  StreamSubscription? _sevaTicketAddedSubscription;
  StreamSubscription? _sevaTicketChangedSubscription;
  StreamSubscription? _sevaTicketRemovedSubscription;

  factory FBL() {
    _instance ??= FBL._();
    return _instance!;
  }

  FBL._() {
    // Code to be executed when first instantiated
  }

  Future<List<Session>> readPushpanjaliSlotsByDate(DateTime date) async {
    String dbDate = DateFormat('yyyy-MM-dd').format(date);
    final dbRef = FirebaseDatabase.instance
        .ref('${Const().dbrootGaruda}/NityaSeva/$dbDate');

    DataSnapshot snapshot = await dbRef.get();

    if (snapshot.exists) {
      return (snapshot.value as Map)
          .values
          .map((value) => Session.fromJson(
              Map<String, dynamic>.from(value['Settings'] as Map)))
          .toList();
    } else {
      return [];
    }
  }

  Future<List<Ticket>> readPushpanjaliTickets(DateTime timestampSlot) async {
    String dbDate = DateFormat('yyyy-MM-dd').format(timestampSlot);
    String dbSession = timestampSlot.toIso8601String().replaceAll('.', '^');
    final dbRef = FirebaseDatabase.instance
        .ref('${Const().dbrootGaruda}/NityaSeva/$dbDate/$dbSession/Tickets');

    DataSnapshot snapshot = await dbRef.get();
    if (snapshot.exists) {
      return (snapshot.value as Map)
          .values
          .map((value) =>
              Ticket.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList();
    } else {
      return [];
    }
  }

  Future<void> listenForChange(String path, FBLCallbacks callbacks) async {
    bool initialLoad = true;

    final dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/$path');

    _sevaTicketAddedSubscription = dbRef.onChildAdded.listen((event) {
      if (!initialLoad) callbacks.onChange("ADD", event.snapshot.value);
    });

    _sevaTicketChangedSubscription = dbRef.onChildChanged.listen((event) {
      if (!initialLoad) callbacks.onChange("UPDATE", event.snapshot.value);
    });

    _sevaTicketRemovedSubscription = dbRef.onChildRemoved.listen((event) {
      if (!initialLoad) callbacks.onChange("REMOVE", event.snapshot.value);
    });

    dbRef.once().then((_) {
      initialLoad = false;
    });
  }

  Future<Map<String, dynamic>?> readLatestLadduSessionData() async {
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva');

    final Query query = dbRef.orderByKey().limitToLast(1);

    final DataSnapshot snapshot = await query.get();
    if (snapshot.exists) {
      var data = snapshot.value as Map;
      var lastValue = data.values.first;

      return Map<String, dynamic>.from(lastValue as Map);
    } else {
      return null;
    }
  }

  Future<List<DateTime>> readLadduSessions(
      DateTime startDate, DateTime endDate) async {
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva');

    final Query query = dbRef
        .orderByKey()
        .startAt(startDate.toIso8601String().replaceAll(".", "^"))
        .endAt(endDate.toIso8601String().replaceAll(".", "^"));

    final DataSnapshot snapshot = await query.get();
    if (snapshot.exists) {
      var allotments = snapshot.value as Map;
      var keys = allotments.keys.toList();
      keys.sort();
      return keys
          .map((key) => DateTime.parse(key.replaceAll("^", ".")))
          .toList();
    } else {
      return [];
    }
  }

  Future<LadduReturn> readLadduReturnStatus(DateTime session) {
    String a = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef = FirebaseDatabase.instance
        .ref('${Const().dbrootGaruda}/LadduSeva/$a/returned');

    return dbRef.get().then((snapshot) {
      if (snapshot.exists) {
        return LadduReturn.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map));
      } else {
        return LadduReturn(
            timestamp: DateTime.now(), to: '', count: -1, user: 'Unknown');
      }
    });
  }

  Future<bool> addLadduStock(
    DateTime session,
    LadduStock stock,
  ) async {
    String a = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva/$a');

    // set return status
    DatabaseReference refRet = dbRef.child('returned');
    try {
      await refRet.set(LadduReturn(
              timestamp: DateTime.now(), to: "", count: -1, user: 'Unknown')
          .toJson());
    } catch (e) {
      return false;
    }

    // Add a new laddu stock
    DateTime timestamp = stock.timestamp;
    DatabaseReference ref = dbRef
        .child('stocks')
        .child(timestamp.toIso8601String().replaceAll(".", "^"));
    try {
      await ref.set(stock.toJson());
    } catch (e) {
      return false;
    }

    return true;
  }

  Future<bool> editLadduStock(DateTime session, LadduStock stock) async {
    String a = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva/$a');

    // Add a new laddu stock
    DateTime timestamp = stock.timestamp;
    DatabaseReference ref = dbRef
        .child('stocks')
        .child(timestamp.toIso8601String().replaceAll(".", "^"));
    try {
      DataSnapshot snapshot = await ref.get();
      if (snapshot.exists) {
        await ref.set(stock.toJson());
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }

    return true;
  }

  Future<void> editLadduReturn(DateTime session, LadduReturn lr) async {
    String a = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef = FirebaseDatabase.instance
        .ref('${Const().dbrootGaruda}/LadduSeva/$a/returned');

    // set return status
    DatabaseReference refRet = dbRef.child('count');
    await refRet.set(lr.count);

    refRet = dbRef.child('to');
    await refRet.set(lr.to);
  }

  Future<bool> editLadduServe(DateTime session, LadduServe serve) async {
    String s = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva/$s');

    // edit laddu stock
    DateTime timestamp = serve.timestamp;
    DatabaseReference ref = dbRef
        .child('serves')
        .child(timestamp.toIso8601String().replaceAll(".", "^"));
    try {
      DataSnapshot snapshot = await ref.get();
      if (snapshot.exists) {
        await ref.set(serve.toJson());
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }

    return true;
  }

  Future<bool> deleteLadduStock(DateTime session, LadduStock stock) async {
    String a = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva/$a');

    // delete laddu stock
    DateTime timestamp = stock.timestamp;
    DatabaseReference ref = dbRef
        .child('stocks')
        .child(timestamp.toIso8601String().replaceAll(".", "^"));
    try {
      DataSnapshot snapshot = await ref.get();
      if (snapshot.exists) {
        await ref.remove();
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }

    return true;
  }

  Future<bool> deleteLadduServe(DateTime session, LadduServe serve) async {
    String a = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva/$a');

    // delete laddu serve
    DateTime timestamp = serve.timestamp;
    DatabaseReference ref = dbRef
        .child('serves')
        .child(timestamp.toIso8601String().replaceAll(".", "^"));
    try {
      DataSnapshot snapshot = await ref.get();
      if (snapshot.exists) {
        await ref.remove();
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }

    return true;
  }

  Future<List<LadduStock>> readLadduStocks(DateTime session) async {
    String a = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef = FirebaseDatabase.instance
        .ref('${Const().dbrootGaruda}/LadduSeva/$a/stocks');

    DataSnapshot snapshot = await dbRef.get();

    List<LadduStock> stocks = [];
    if (snapshot.exists) {
      stocks = (snapshot.value as Map)
          .values
          .map((value) =>
              LadduStock.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList();
    }

    return stocks;
  }

  Future<List<LadduStock>> readLadduStocksByDateRange(
      DateTime startDate, DateTime endDate) async {
    final DatabaseReference dbRef = FirebaseDatabase.instance
        .ref('${Const().dbrootGaruda}/LadduSeva/stocks');

    final Query query = dbRef
        .orderByKey()
        .startAt(startDate.toIso8601String().replaceAll(".", "^"))
        .endAt(endDate.toIso8601String().replaceAll(".", "^"));

    final DataSnapshot snapshot = await query.get();

    if (snapshot.exists) {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);
      final List<LadduStock> ladduStocks = data.entries
          .map((entry) =>
              LadduStock.fromJson(Map<String, dynamic>.from(entry.value)))
          .toList();
      return ladduStocks;
    } else {
      return [];
    }
  }

  Future<DateTime> addLadduSession() async {
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva');

    DateTime timestamp = DateTime.now();
    DatabaseReference ref =
        dbRef.child(timestamp.toIso8601String().replaceAll(".", "^"));

    try {
      await ref.set({});
      return timestamp;
    } catch (e) {
      Toaster().error("Database write error: $e");
      return DateTime.now();
    }
  }

  Future<bool> addLadduServe(DateTime session, LadduServe dist) async {
    String s = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva/$s');

    // Add a new laddu distribution
    DateTime timestamp = dist.timestamp;
    DatabaseReference ref = dbRef
        .child('serves')
        .child(timestamp.toIso8601String().replaceAll(".", "^"));
    try {
      await ref.set(dist.toJson());
    } catch (e) {
      return false;
    }

    return true;
  }

  Future<List<LadduServe>> readLadduServes(DateTime session) async {
    String s = session.toIso8601String().replaceAll(".", "^");
    final DatabaseReference dbRef = FirebaseDatabase.instance
        .ref('${Const().dbrootGaruda}/LadduSeva/$s/serves');

    DataSnapshot snapshot;
    snapshot = await dbRef.get();

    List<LadduServe> serves = [];
    if (snapshot.exists) {
      serves = (snapshot.value as Map)
          .values
          .map((value) =>
              LadduServe.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList();
    }

    return serves;
  }

  Future<String> getLastSessionName() async {
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('${Const().dbrootGaruda}/LadduSeva');

    final Query query = dbRef.orderByKey().limitToLast(1);
    final DataSnapshot snapshot = await query.get();

    if (!snapshot.exists) {
      throw Exception('No LadduSeva session found in database');
    }

    // Get the last session key
    var data = snapshot.value as Map;
    return data.keys.first;
  }

  Future<DateTime> getLastSessionDateTime() async {
    String lastSessionName = await getLastSessionName();
    return DateTime.parse(lastSessionName.replaceAll("^", "."));
  }

  Future<void> returnLadduStock(LadduReturn lr) async {
    String session = await getLastSessionName();

    final DatabaseReference returnRef = FirebaseDatabase.instance
        .ref('${Const().dbrootGaruda}/LadduSeva/$session/returned');

    await returnRef.update({
      'count': lr.count,
      'to': lr.to,
      'timestamp': lr.timestamp.toIso8601String(),
      'user': lr.user,
    });
  }
}

class FBLCallbacks {
  void Function(String changeType, dynamic data) onChange;

  FBLCallbacks({
    required this.onChange,
  });
}
