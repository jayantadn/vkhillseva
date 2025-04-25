import 'package:vkhpackages/vkhpackages.dart';

class SSUtils {
  static final SSUtils _instance = SSUtils._internal();

  factory SSUtils() {
    return _instance;
  }

  SSUtils._internal() {
    // init
  }

  Future<PerformerProfile?> getUserProfile(String mobile) async {
    var userDetailsRaw = await FB().getValue(
      path: "${Const().dbrootSangeetSeva}/Users/$mobile",
    );

    if (userDetailsRaw == null || userDetailsRaw.isEmpty) {
      return null;
    }

    return Utils().convertRawToDatatype(
      userDetailsRaw,
      PerformerProfile.fromJson,
    );
  }
}
