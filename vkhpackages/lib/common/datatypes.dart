class EventRecord {
  final DateTime date;
  final Slot slot;
  final String mainPerformerMobile;
  final List<String> supportTeamMobiles;
  final List<Guest> guests;
  final List<String> songs;
  String status;
  final String notePerformer;
  String noteTemple;

  EventRecord({
    required this.date,
    required this.slot,
    required this.mainPerformerMobile,
    required this.supportTeamMobiles,
    required this.guests,
    required this.songs,
    this.status = 'Pending',
    this.notePerformer = '',
    this.noteTemple = '',
  });

  factory EventRecord.fromJson(Map<String, dynamic> json) {
    return EventRecord(
      date: DateTime.parse(json['date'] as String),
      mainPerformerMobile: json['mainPerformer'] as String,

      notePerformer: json['notePerformer'] as String,
      noteTemple: json['noteTemple'] as String,
      slot: Slot.fromJson(Map<String, dynamic>.from(json['slot'])),
      songs: List.generate(json['songs'].length, (index) {
        return json['songs'][index];
      }),
      status: json['status'] as String,
      guests:
          json['guests'] == null
              ? []
              : List.generate(json['guests'].length, (index) {
                dynamic guestRaw = json['guests'][index];
                Map<String, dynamic> guestMap = Map<String, dynamic>.from(
                  guestRaw,
                );
                return Guest.fromJson(guestMap);
              }),
      supportTeamMobiles:
          json['supportTeam'] == null
              ? []
              : List.generate(json['supportTeam'].length, (index) {
                return json['supportTeam'][index] as String;
              }),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'slot': slot.toJson(),
      'mainPerformer': mainPerformerMobile,
      'supportTeam': supportTeamMobiles.map((e) => e).toList(),
      'guests': guests.map((e) => e.toJson()).toList(),
      'songs': songs,
      'status': status,
      'notePerformer': notePerformer,
      'noteTemple': noteTemple,
    };
  }
}

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
    return {'name': name, 'honorPrasadam': honorPrasadam};
  }
}

class SangeetExp {
  final String category;
  final String subcategory;
  final int yrs;

  SangeetExp({
    required this.category,
    required this.subcategory,
    required this.yrs,
  });

  // Factory constructor to create SangeetExp from JSON
  factory SangeetExp.fromJson(Map<String, dynamic> json) {
    return SangeetExp(
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      yrs: json['yrs'] as int,
    );
  }

  // Method to convert SangeetExp to JSON
  Map<String, dynamic> toJson() {
    return {'category': category, 'subcategory': subcategory, 'yrs': yrs};
  }
}

class Slot {
  final String name;
  bool avl;
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
    return {'name': name, 'avl': avl, 'from': from, 'to': to};
  }
}

class UserDetails {
  final String salutation;
  final String name;
  final String mobile;
  final String profilePicUrl;
  final String credentials;
  final List<SangeetExp> exps;
  final List<String> youtubeUrls;
  final List<String> audioClipUrls;
  String? fcmToken;
  String? friendMobile;

  UserDetails({
    required this.salutation,
    required this.name,
    required this.mobile,
    required this.profilePicUrl,
    required this.credentials,
    required this.exps,
    required this.youtubeUrls,
    required this.audioClipUrls,
    this.fcmToken,
    this.friendMobile,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      salutation: json['salutation'],
      name: json['name'],
      mobile: json['mobile'],
      profilePicUrl: json['profilePicUrl'],
      credentials: json['credentials'],
      exps:
          json['exps'] == null
              ? []
              : List<SangeetExp>.from(
                json['exps'].map(
                  (e) =>
                      SangeetExp.fromJson(Map<String, dynamic>.from(e as Map)),
                ),
              ),
      youtubeUrls:
          json['youtubeUrls'] == null
              ? []
              : List<String>.from(json['youtubeUrls']),
      audioClipUrls:
          json['audioClipUrls'] == null
              ? []
              : List<String>.from(json['audioClipUrls']),
      fcmToken: json['fcmToken'],
      friendMobile: json['friendMobile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salutation': salutation,
      'name': name,
      'mobile': mobile,
      'profilePicUrl': profilePicUrl,
      'credentials': credentials,
      'exps': exps.map((e) => e.toJson()).toList(),
      'youtubeUrls': youtubeUrls,
      'audioClipUrls': audioClipUrls,
      'fcmToken': fcmToken,
      'friendMobile': friendMobile,
    };
  }
}
