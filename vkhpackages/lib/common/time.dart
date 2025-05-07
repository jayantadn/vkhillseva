class Time {
  static final Time _instance = Time._internal();

  factory Time() {
    return _instance;
  }

  Time._internal() {
    // init
  }

  String convertDateTimeTo12hrFormat(DateTime dateTime) {
    String ampm = "AM";
    int hr = dateTime.hour;
    if (hr >= 12) {
      ampm = "PM";
      if (hr > 12) {
        hr -= 12;
      }
    }
    String min = dateTime.minute.toString().padLeft(2, '0');
    return "$hr:$min $ampm";
  }

  String convertTimeStringTo12HrFormat(String time) {
    // check if 12 hr or 24 hr format
    if (time.contains("AM") || time.contains("PM")) {
      // 12-hr format
      return time;
    } else {
      // 24-hr format
      String part1 = time.split(":")[0];
      String part2 = time.split(":")[1];
      int hr = int.parse(part1);
      String ampm = "AM";
      if (hr >= 12) {
        ampm = "PM";
        if (hr > 12) {
          hr -= 12;
        }
      }
      return "$hr:$part2 $ampm";
    }
  }

  // input time is in format "07:30 PM" or "19:30"
  DateTime convertStringToTime(DateTime date, String time) {
    // check if 12 hr or 24 hr format
    if (time.contains("AM") || time.contains("PM")) {
      // 12-hr format
      return DateTime(
        date.year,
        date.month,
        date.day,
        convertTo24hrFormat(time)[0],
        convertTo24hrFormat(time)[1],
      );
    } else {
      // 24-hr format
      String part1 = time.split(":")[0];
      String part2 = time.split(":")[1];
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(part1),
        int.parse(part2),
      );
    }
  }

  // input time is in format "07:30 PM"
  // return [19, 30]
  List<int> convertTo24hrFormat(String time) {
    String part1 = time.split(":")[0];
    String part2 = time.split(":")[1];
    String part3 = part2.split(" ")[0];
    String part4 = part2.split(" ")[1];

    int hr = int.parse(part1);
    int min = int.parse(part3);
    if (part4 == "PM" && hr != 12) {
      hr += 12;
    } else if (part4 == "AM" && hr == 12) {
      hr = 0;
    }
    if (hr == 24) {
      hr = 0;
    }

    return [hr, min];
  }
}
