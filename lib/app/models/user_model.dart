class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? profilePic;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePic,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      fullName: json['fullName'],
      email: json['email'],
      profilePic: json['profilePic'],
    );
  }
}
