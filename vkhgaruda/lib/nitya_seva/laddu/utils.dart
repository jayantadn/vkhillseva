import 'package:vkhgaruda/nitya_seva/laddu/datatypes.dart';
import 'package:intl/intl.dart';
import 'package:vkhgaruda/nitya_seva/laddu/fbl.dart';
import 'package:vkhpackages/common/toaster.dart';
import 'package:vkhpackages/common/utils.dart';

int CalculateTotalLadduPacksServed(LadduServe serve) {
  int total = 0;
  for (var element in serve.packsPushpanjali) {
    element.forEach((key, value) {
      total += value;
    });
  }

  for (var element in serve.packsOtherSeva) {
    element.forEach((key, value) {
      total += value;
    });
  }

  for (var element in serve.packsMisc) {
    element.forEach((key, value) {
      total += value;
    });
  }

  return total;
}

Future<String> CalculateSessionTitle(Map<String, dynamic> sessionData) async {
  String lastSession = (await FBL().getLastSessionName()).replaceAll("^", ".");
  DateTime session = DateTime.parse(lastSession);

  String sessionTitle = DateFormat("EEE, MMM dd").format(session);
  LadduReturn lr = readLadduReturnStatus(sessionData) ??
      LadduReturn(count: -1, timestamp: DateTime.now(), to: "", user: "");

  if (lr.count >= 0) {
    String endSession = DateFormat("EEE, MMM dd").format(lr.timestamp);
    if (sessionTitle != endSession) {
      sessionTitle += " - $endSession";
    }
  } else {
    DateTime now = DateTime.now();
    if (session.day != now.day) {
      sessionTitle += DateFormat(" - EEE, MMM dd").format(now);
    }
  }

  return sessionTitle;
}

LadduReturn? readLadduReturnStatus(Map<String, dynamic>? sessionData) {
  if (sessionData == null || sessionData.isEmpty) {
    Toaster().error("No data");
    return null;
  }

  if (sessionData['returned'] == null) {
    return null;
  }

  return Utils()
      .convertRawToDatatype(sessionData['returned'], LadduReturn.fromJson);
}

List<LadduServe> readLadduServes(Map<String, dynamic>? sessionData) {
  if (sessionData == null) {
    Toaster().error("No data");
    return [];
  }

  List<LadduServe> list = [];

  if (sessionData.isNotEmpty) {
    Map<String, dynamic> serves =
        Map<String, dynamic>.from(sessionData['serves']);
    serves.forEach((key, value) {
      list.add(Utils().convertRawToDatatype(value, LadduServe.fromJson));
    });
  }

  return list;
}

List<LadduStock> readLadduStocks(Map<String, dynamic>? sessionData) {
  if (sessionData == null) {
    Toaster().error("No data");
    return [];
  }

  List<LadduStock> list = [];

  if (sessionData.isNotEmpty) {
    Map<String, dynamic> serves =
        Map<String, dynamic>.from(sessionData['stocks']);
    serves.forEach((key, value) {
      list.add(Utils().convertRawToDatatype(value, LadduStock.fromJson));
    });
  }

  return list;
}
