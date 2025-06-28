import 'dart:convert';
import 'package:chat_app/app/models/message_model.dart';
import 'package:http/http.dart' as http;

class MessageService {
  final String baseUrl;
  final String authToken; // if you use JWT or any token auth

  MessageService({required this.baseUrl, required this.authToken});

  Future<List<MessageModel>> fetchMessages(String chatUserId) async {
    final url = Uri.parse('$baseUrl/api/messages/$chatUserId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken', // adjust as needed
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }
}
