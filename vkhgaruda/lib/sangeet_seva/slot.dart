import 'package:intl/intl.dart';
import 'package:vkhgaruda/common/const.dart';
import 'package:vkhgaruda/common/fb.dart';

class SlotUtils {
  static final SlotUtils _instance = SlotUtils._internal();

  factory SlotUtils() {
    return _instance;
  }

  SlotUtils._internal() {
    // init
  }

  Future<int> getTotalSlotsCount(DateTime date) async {
    // get slots from database
    String dbDate = DateFormat("yyyy-MM-dd").format(date);
    List<dynamic> slotList =
        await FB().getList(dbroot: Const().dbroot, path: "Slots/$dbDate");

    // add slots for weekend
    bool isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return slotList.length + (isWeekend ? 2 : 0);
  }

  Future<int> getBookedSlotsCount(DateTime date) async {
    // TODO: implementation pending
    return 0;
  }
}

class Slot {
  final String name;
  final bool avl;
  final String startTime;
  final String endTime;

  Slot({
    required this.name,
    required this.avl,
    required this.startTime,
    required this.endTime,
  });

  // Factory constructor to create a Slot from JSON
  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      name: json['name'] as String,
      avl: json['avl'] as bool,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  // Method to convert Slot to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avl': avl,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
