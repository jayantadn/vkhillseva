class Const {
  static final Const _instance = Const._internal();

  factory Const() {
    return _instance;
  }

  Const._internal() {
    // init
  }

  final String dbroot = "VKHILLSEVA_01";

  final List<String> icons = [
    "assets/images/Logo/KrishnaLilaPark_square.png",
    "assets/images/LauncherIcons/NityaSeva.png",
    "assets/images/LauncherIcons/Deepotsava.png",
    "assets/images/LauncherIcons/Harinaam.png",
    "assets/images/Common/morning.png",
    "assets/images/Common/evening.png",
    "assets/images/Festivals/RamNavami.png",
    "assets/images/Festivals/Balarama.png",
    "assets/images/Festivals/AkshayaTritiya.png",
    "assets/images/Festivals/Garuda.png",
    "assets/images/Festivals/Govardhana.png",
    "assets/images/Festivals/Vamana.png",
    "assets/images/VKHillDieties/Garuda.png",
    "assets/images/VKHillDieties/Govinda.png",
    "assets/images/VKHillDieties/Hanuman.png",
    "assets/images/VKHillDieties/Jagannatha.png",
    "assets/images/VKHillDieties/LakshmiNarasimha.png",
    "assets/images/VKHillDieties/Narasimha.png",
    "assets/images/VKHillDieties/NitaiGauranga.png",
    "assets/images/VKHillDieties/Padmavati.png",
    "assets/images/VKHillDieties/Prabhupada.png",
    "assets/images/VKHillDieties/RadhaKrishna.png",
    "assets/images/VKHillDieties/Sudarshana.png",
  ];
}
