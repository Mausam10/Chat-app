import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class MessageController extends GetxController {
  final storage = GetStorage();

  final isLoading = false.obs;
  final chatMessages = <Map<String, dynamic>>[].obs;

  String get currentUserId => storage.read('user_id') ?? '';
  String baseUrl = 'http://192.168.56.1:5001/api';

  // Fetch messages with a user by their ID
  Future<void> fetchMessages(String userId) async {
    isLoading.value = true;
    try {
      final token = storage.read('auth_token');
      final res = await http.get(
        Uri.parse('$baseUrl/messages/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        chatMessages.value = data.cast<Map<String, dynamic>>();
      } else {
        print("Failed to load messages: ${res.body}");
      }
    } catch (e) {
      print("Error fetching messages: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Send a new message to a user
  Future<void> sendMessage(
    String receiverId,
    String text, {
    String? base64Image,
  }) async {
    try {
      final token = storage.read('auth_token');
      final body = {
        'text': text,
        if (base64Image != null && base64Image.isNotEmpty) 'image': base64Image,
      };

      final res = await http.post(
        Uri.parse(
          '$baseUrl/messages/send/$receiverId',
        ), // Note the "/send" here
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (res.statusCode == 201) {
        final newMessage = json.decode(res.body);
        chatMessages.add(newMessage); // Optimistic UI update
      } else {
        print("Send message failed: ${res.body}");
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }
}
