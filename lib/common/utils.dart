import 'package:intl/intl.dart';

class Utils {
  static final Utils _instance = Utils._internal();

  factory Utils() {
    return _instance;
  }

  Utils._internal() {
    // init
  }

  String formatIndianCurrency(String amount) {
    final formatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final number = int.parse(amount.replaceAll(RegExp(r'[^\d]'), ''));
    return formatter.format(number);
  }
}
