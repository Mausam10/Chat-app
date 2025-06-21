class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? profilePic;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePic,
    required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '', // MongoDB ObjectId
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profilePic'], // Can be null
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'fullName': fullName,
    'email': email,
    'profilePic': profilePic,
    'isAdmin': isAdmin,
  };
}
