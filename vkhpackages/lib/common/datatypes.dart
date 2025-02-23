class FestivalSettings {
  final String name;
  final String icon;

  FestivalSettings({required this.name, required this.icon});

  factory FestivalSettings.fromJson(Map<String, dynamic> json) {
    return FestivalSettings(
      name: json['name'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
    };
  }
}

class Slot {
  final String name;
  final bool avl;
  final String from;
  final String to;

  Slot({
    required this.name,
    required this.avl,
    required this.from,
    required this.to,
  });

  // Factory constructor to create a Slot from JSON
  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      name: json['name'] as String,
      avl: json['avl'] as bool,
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }

  // Method to convert Slot to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avl': avl,
      'from': from,
      'to': to,
    };
  }
}

class PerformanceRequest {
  final DateTime date;
  final Slot slot;
  final UserDetails mainPerformer;
  final List<UserDetails> supportTeam;
  final List<Guest> guests;
  final List<String> songs;

  PerformanceRequest({
    required this.date,
    required this.slot,
    required this.mainPerformer,
    required this.supportTeam,
    required this.guests,
    required this.songs,
  });

  factory PerformanceRequest.fromJson(Map<String, dynamic> json) {
    return PerformanceRequest(
      date: DateTime.parse(json['date'] as String),
      slot: Slot.fromJson(json['slot'] as Map<String, dynamic>),
      mainPerformer:
          UserDetails.fromJson(json['mainPerformer'] as Map<String, dynamic>),
      supportTeam: (json['supportTeam'] as List<dynamic>)
          .map((e) => UserDetails.fromJson(e as Map<String, dynamic>))
          .toList(),
      guests: (json['guests'] as List<dynamic>)
          .map((e) => Guest.fromJson(e as Map<String, dynamic>))
          .toList(),
      songs: List<String>.from(json['songs'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'slot': slot.toJson(),
      'mainPerformer': mainPerformer.toJson(),
      'supportTeam': supportTeam.map((e) => e.toJson()).toList(),
      'guests': guests.map((e) => e.toJson()).toList(),
      'songs': songs,
    };
  }
}

class Guest {
  final String name;
  final bool honorPrasadam;

  Guest({required this.name, required this.honorPrasadam});

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      name: json['name'] as String,
      honorPrasadam: json['honorPrasadam'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'honorPrasadam': honorPrasadam,
    };
  }
}

class UserDetails {
  final String salutation;
  final String name;
  final String mobile;
  final String profilePicUrl;
  final String credentials;
  final String experience;
  final String fieldOfExpertise;
  final List<String> skills;
  final List<String> youtubeUrls;
  final List<String> audioClipUrls;

  UserDetails({
    required this.salutation,
    required this.name,
    required this.mobile,
    required this.profilePicUrl,
    required this.credentials,
    required this.experience,
    required this.fieldOfExpertise,
    required this.skills,
    required this.youtubeUrls,
    required this.audioClipUrls,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      salutation: json['salutation'],
      name: json['name'],
      mobile: json['mobile'],
      profilePicUrl: json['profilePicUrl'],
      credentials: json['credentials'],
      experience: json['experience'],
      fieldOfExpertise: json['fieldOfExpertise'],
      skills: json['skills'] == null ? [] : List<String>.from(json['skills']),
      youtubeUrls: json['youtubeUrls'] == null
          ? []
          : List<String>.from(json['youtubeUrls']),
      audioClipUrls: json['audioClipUrls'] == null
          ? []
          : List<String>.from(json['audioClipUrls']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salutation': salutation,
      'name': name,
      'mobile': mobile,
      'profilePicUrl': profilePicUrl,
      'credentials': credentials,
      'experience': experience,
      'fieldOfExpertise': fieldOfExpertise,
      'skills': skills,
      'youtubeUrls': youtubeUrls,
      'audioClipUrls': audioClipUrls,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserDetails &&
        other.salutation == salutation &&
        other.name == name &&
        other.mobile == mobile &&
        other.profilePicUrl == profilePicUrl &&
        other.credentials == credentials &&
        other.experience == experience &&
        other.fieldOfExpertise == fieldOfExpertise &&
        other.youtubeUrls.every((url) => youtubeUrls.contains(url)) &&
        other.audioClipUrls.length == audioClipUrls.length &&
        other.audioClipUrls.every((url) => audioClipUrls.contains(url));
  }

  @override
  int get hashCode {
    return salutation.hashCode ^
        name.hashCode ^
        mobile.hashCode ^
        profilePicUrl.hashCode ^
        credentials.hashCode ^
        experience.hashCode ^
        fieldOfExpertise.hashCode ^
        skills.hashCode ^
        youtubeUrls.hashCode ^
        audioClipUrls.hashCode;
  }

  bool isEqual(UserDetails other) {
    return other.salutation == salutation &&
        other.name == name &&
        other.mobile == mobile &&
        other.profilePicUrl == profilePicUrl &&
        other.credentials == credentials &&
        other.experience == experience &&
        other.fieldOfExpertise == fieldOfExpertise &&
        other.skills.length == skills.length &&
        other.skills.every((skill) => skills.contains(skill)) &&
        other.youtubeUrls.length == youtubeUrls.length &&
        other.youtubeUrls.every((url) => youtubeUrls.contains(url)) &&
        other.audioClipUrls.length == audioClipUrls.length &&
        other.audioClipUrls.every((url) => audioClipUrls.contains(url));
  }

  bool isEmpty() {
    return salutation.isEmpty ||
        name.isEmpty ||
        mobile.isEmpty ||
        profilePicUrl.isEmpty ||
        credentials.isEmpty ||
        experience.isEmpty ||
        fieldOfExpertise.isEmpty ||
        skills.isEmpty ||
        youtubeUrls.isEmpty ||
        audioClipUrls.isEmpty;
  }
}
