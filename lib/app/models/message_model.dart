class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? image;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.image,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      text: json['text'],
      image: json['image'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
