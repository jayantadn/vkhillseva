import 'package:vkhillseva/common/fb.dart';
import 'package:vkhillseva/nitya_seva/laddu/datatypes.dart';
import 'package:intl/intl.dart';
import 'package:vkhillseva/nitya_seva/laddu/fbl.dart';

int CalculateTotalLadduPacksServed(LadduServe serve) {
  int total = 0;
  serve.packsPushpanjali.forEach((element) {
    element.forEach((key, value) {
      total += value;
    });
  });

  serve.packsOtherSeva.forEach((element) {
    element.forEach((key, value) {
      total += value;
    });
  });

  serve.packsMisc.forEach((element) {
    element.forEach((key, value) {
      total += value;
    });
  });

  return total;
}

Future<String> CalculateSessionTitle(DateTime session) async {
  String sessionTitle = DateFormat("EEE, MMM dd").format(session);
  LadduReturn lr = await FBL().readLadduReturnStatus(session);
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
