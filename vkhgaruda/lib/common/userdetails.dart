class UserDetails {
  final String uid;
  final String? email;
  final String name;
  final String mobile;

  UserDetails({
    required this.uid,
    this.email,
    required this.name,
    required this.mobile,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      mobile: json['mobile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'mobile': mobile,
    };
  }
}
