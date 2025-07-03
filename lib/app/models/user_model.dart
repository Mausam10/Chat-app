class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? profilePic;
  final bool isAdmin;

  // 🆕 Chat-related fields
  String? lastMessage;
  DateTime? lastMessageTime;
  int unreadCount;
  bool isTyping;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePic,
    required this.isAdmin,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isTyping = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profilePic'],
      isAdmin: json['isAdmin'] ?? false,

      // Chat fields from backend
      lastMessage: json['lastMessage'],
      lastMessageTime:
          json['lastMessageTime'] != null
              ? DateTime.tryParse(json['lastMessageTime'])
              : null,
      unreadCount: json['unreadCount'] ?? 0,
      isTyping: json['isTyping'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'fullName': fullName,
    'email': email,
    'profilePic': profilePic,
    'isAdmin': isAdmin,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime?.toIso8601String(),
    'unreadCount': unreadCount,
    'isTyping': isTyping,
  };
}
