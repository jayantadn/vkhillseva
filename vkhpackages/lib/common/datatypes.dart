class FestivalSettings {
  final String name;
  final String icon;

  FestivalSettings({required this.name, required this.icon});

  factory FestivalSettings.fromJson(Map<String, dynamic> json) {
    return FestivalSettings(name: json['name'], icon: json['icon']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'icon': icon};
  }
}
