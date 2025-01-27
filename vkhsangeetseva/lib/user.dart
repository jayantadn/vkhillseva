class User {
  static final User _instance = User._internal();

  factory User() {
    return _instance;
  }

  User._internal() {
    // init
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
