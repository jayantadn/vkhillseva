class Const {
  static final Const _instance = Const._internal();

  factory Const() {
    return _instance;
  }

  Const._internal() {
    // init
  }

  final String dbroot = "NityaSeva_01";
}
