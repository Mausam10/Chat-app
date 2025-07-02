import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:chat_app/app/services/socket_service.dart';

class MessageController extends GetxController {
  final storage = GetStorage();

  final isLoading = false.obs;
  final RxBool isTyping = false.obs;
  final chatMessages = <Map<String, dynamic>>[].obs;
  final recentChats = <Map<String, dynamic>>[].obs;

  late final SocketService socketService;

  String? currentChatUserId;

  String get currentUserId => storage.read('user_id') ?? '';

  final String baseUrl = 'http://192.168.56.1:5001/api';

  @override
  void onInit() {
    super.onInit();
    socketService = Get.find<SocketService>();

    // Subscribe to socket event callbacks exposed by SocketService
    socketService.onMessageReceived(_handleIncomingMessage);
    socketService.onUserTyping(_handleTypingIndicator);
    socketService.onMessageSeen((data) {
      _updateMessageStatus(data['messageId'], 'seen');
    });
  }

  void _handleIncomingMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = _normalizeMessageFormat(data);
      if (!_isValidMessage(message)) return;

      final senderId = message['senderId'] ?? '';
      final receiverId = message['receiverId'] ?? '';

      bool isCurrentConversation =
          currentChatUserId != null &&
          ((senderId == currentChatUserId && receiverId == currentUserId) ||
              (senderId == currentUserId && receiverId == currentChatUserId));

      if (!isCurrentConversation && receiverId == currentUserId) {
        isCurrentConversation = true;
      }

      if (isCurrentConversation && !_isDuplicateMessage(message)) {
        chatMessages.insert(0, message);
        chatMessages.refresh();
      }
    }
  }

  void _handleTypingIndicator(dynamic data) {
    if (data is Map<String, dynamic>) {
      final typingUserId = data['from'] ?? '';
      if (typingUserId == currentChatUserId) {
        isTyping.value = true;
        Future.delayed(const Duration(seconds: 3), () {
          isTyping.value = false;
        });
      }
    }
  }

  Map<String, dynamic> _normalizeMessageFormat(Map<String, dynamic> data) {
    var normalized = Map<String, dynamic>.from(data);

    if (data.containsKey('message') && data.containsKey('from')) {
      normalized = {
        'text': data['message'],
        'senderId': data['from'],
        'receiverId': currentUserId,
        'timestamp': data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        ...data,
      };
    }

    return normalized;
  }

  bool _isValidMessage(Map<String, dynamic> msg) {
    return msg.containsKey('text') || msg.containsKey('image');
  }

  bool _isDuplicateMessage(Map<String, dynamic> newMsg) {
    final newId = newMsg['id'] ?? newMsg['_id'];
    if (newId == null) return false;

    return chatMessages.any((existingMsg) {
      final existingId = existingMsg['id'] ?? existingMsg['_id'];
      return existingId == newId;
    });
  }

  void startConversation(String userId, {bool isGroup = false}) {
    currentChatUserId = userId;
    chatMessages.clear();

    // Join the chat room
    String roomId;
    if (isGroup) {
      roomId = 'group_$userId';
    } else {
      final ids = [currentUserId, userId]..sort();
      roomId = 'chat_${ids.join('_')}';
    }
    socketService.joinRoom(roomId, currentUserId);

    fetchMessages(userId);
  }

  Future<void> fetchMessages(String userId) async {
    isLoading.value = true;
    try {
      final token = storage.read('auth_token');
      if (token == null) throw Exception('No auth token');

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
        print('Failed to load messages: ${res.statusCode}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRecentChats() async {
    try {
      final token = storage.read('auth_token');
      if (token == null) throw Exception('No auth token');

      final res = await http.get(
        Uri.parse('$baseUrl/messages/recent/$currentUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        recentChats.value = data.cast<Map<String, dynamic>>();
      } else {
        print('Failed to load recent chats: ${res.statusCode}');
      }
    } catch (e) {
      print('Error fetching recent chats: $e');
    }
  }

  Future<bool> sendMessage(
    String receiverId,
    String text, {
    String? base64Image,
    String? base64File,
    String? fileName,
    String? mimeType,
    String? replyToMessageId,
    String? reaction,
  }) async {
    try {
      final token = storage.read('auth_token');
      if (token == null) throw Exception('No auth token');

      final body = {
        'text': text,
        'senderId': currentUserId,
        'receiverId': receiverId,
        'status': 'sent',
        if (base64Image != null && base64Image.isNotEmpty) 'image': base64Image,
        if (base64File != null) ...{
          'file': base64File,
          'fileName': fileName,
          'mimeType': mimeType,
        },
        if (replyToMessageId != null) 'replyTo': replyToMessageId,
        if (reaction != null) 'reaction': reaction,
      };

      final res = await http.post(
        Uri.parse('$baseUrl/messages/send/$receiverId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final newMessage = json.decode(res.body);
        if (!_isDuplicateMessage(newMessage)) {
          chatMessages.insert(0, newMessage);
          chatMessages.refresh();
        }

        // Emit socket event via SocketService
        socketService.sendMessage(receiverId, text);

        return true;
      } else {
        print('Failed to send message: ${res.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  void sendTypingEvent(String receiverId) {
    socketService.sendTypingEvent(receiverId);
  }

  void markMessagesAsSeen(String otherUserId) {
    for (var msg in chatMessages) {
      if (msg['receiverId'] == currentUserId &&
          msg['senderId'] == otherUserId) {
        msg['status'] = 'seen';
      }
    }
    chatMessages.refresh();

    // Emit seen event
    socketService.markMessageAsSeen(
      otherUserId,
      'some-message-id',
    ); // Pass proper messageId if available
  }

  void _updateMessageStatus(String messageId, String status) {
    final index = chatMessages.indexWhere(
      (msg) => msg['id'] == messageId || msg['_id'] == messageId,
    );
    if (index != -1) {
      chatMessages[index]['status'] = status;
      chatMessages.refresh();
    }
  }
}
