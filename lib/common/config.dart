class Config {
  static final Config _instance = Config._internal();

  factory Config() {
    return _instance;
  }

  Config._internal() {
    // init
  }

  Map nityaSeva = {
    'sevaList': {
      'Nitya Seva morning': {'icon': "assets/images/Common/morning.png"},
      'Nitya Seva evening': {'icon': "assets/images/Common/evening.png"},
      'Ram Navami': {'icon': "assets/images/Festivals/RamNavami.png"},
      'Brahmotsava': {'icon': "assets/images/Logo/KrishnaLilaPark_square.png"},
      'Hanuman Jayanti': {'icon': "assets/images/VKHillDieties/Hanuman.png"},
      'Akshaya Tritiya': {'icon': "assets/images/Festivals/AkshayaTritiya.png"},
      'Narasimha Chaturdashi': {
        'icon': "assets/images/VKHillDieties/Narasimha.png"
      },
      'Garuda Panchami': {'icon': "assets/images/Festivals/Garuda.png"},
      'Balarama Jayanti': {'icon': "assets/images/Festivals/Balarama.png"},
      'Sri Krishna Janmastami': {
        'icon': "assets/images/VKHillDieties/RadhaKrishna.png"
      },
      'Sri Vyasa Puja': {'icon': "assets/images/VKHillDieties/Prabhupada.png"},
      'Radhastami': {'icon': "assets/images/VKHillDieties/Padmavati.png"},
      'Vamana Jayanti': {'icon': "assets/images/Festivals/Vamana.png"},
      'Govardhana Puja': {'icon': "assets/images/Festivals/Govardhana.png"},
      'Vaikuntha Ekadashi': {'icon': "assets/images/VKHillDieties/Govinda.png"},
      'Nityananda Trayodashi': {
        'icon': "assets/images/VKHillDieties/NitaiGauranga.png"
      },
      'Sri Gaura Poornima': {
        'icon': "assets/images/VKHillDieties/NitaiGauranga.png"
      },
      'Ratha Yatra': {'icon': "assets/images/VKHillDieties/Jagannatha.png"},
      'Jhulan Utsava': {'icon': "assets/images/VKHillDieties/RadhaKrishna.png"},
      'Sudarshana Jayanti': {
        'icon': "assets/images/VKHillDieties/Sudarshana.png"
      },
      'Other festival': {'icon': "assets/images/LauncherIcons/NityaSeva.png"},
    }
  };
}
