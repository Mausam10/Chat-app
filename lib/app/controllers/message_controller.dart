import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:chat_app/app/services/socket_service.dart';

class MessageController extends GetxController {
  final storage = GetStorage();
  final Set<String> _messageIds = <String>{};
  final isLoading = false.obs;
  final RxBool isTyping = false.obs;
  final chatMessages = <Map<String, dynamic>>[].obs;
  final recentChats = <Map<String, dynamic>>[].obs;

  late final SocketService socketService;

  String? currentChatUserId;

  String get currentUserId => storage.read('user_id') ?? '';

  final String baseUrl = 'http://192.168.1.70:5001/api';

  @override
  void onInit() {
    super.onInit();
    socketService = Get.find<SocketService>();

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

      if (message['text'] == 'joined the room' && senderId == currentUserId)
        return;

      bool isCurrentConversation =
          currentChatUserId != null &&
          ((senderId == currentChatUserId && receiverId == currentUserId) ||
              (senderId == currentUserId && receiverId == currentChatUserId));

      if (!isCurrentConversation && receiverId == currentUserId) {
        isCurrentConversation = true;
      }

      if (isCurrentConversation) {
        _addMessage(message);
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
    final normalized = Map<String, dynamic>.from(data);

    if (data.containsKey('message') && data.containsKey('from')) {
      normalized['text'] = data['message'];
      normalized['senderId'] = data['from'];
      normalized['receiverId'] ??= currentUserId;
      normalized['timestamp'] ??= DateTime.now().toIso8601String();
    }

    return normalized;
  }

  bool _isValidMessage(Map<String, dynamic> msg) {
    return msg.containsKey('text') || msg.containsKey('image');
  }

  bool _isDuplicateMessage(Map<String, dynamic> msg) {
    final id = msg['id'] ?? msg['_id'];
    if (id == null || _messageIds.contains(id)) return true;
    _messageIds.add(id);
    return false;
  }

  void _addMessage(Map<String, dynamic> msg) {
    final message = _normalizeMessageFormat(msg);
    if (_isValidMessage(message) && !_isDuplicateMessage(message)) {
      chatMessages.add(message);
      chatMessages.refresh();
    }
  }

  void startConversation(String userId) {
    if (currentChatUserId != userId) {
      chatMessages.clear();
      _messageIds.clear();
    }

    currentChatUserId = userId;

    final sorted = [currentUserId, userId]..sort();
    final roomName = 'chat_${sorted.join("_")}';

    socketService.joinRoom(roomName, currentUserId);
    fetchMessages(userId);
  }

  Future<void> fetchMessages(String userId) async {
    isLoading.value = true;
    chatMessages.clear();
    _messageIds.clear();

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

        data.sort((a, b) {
          final aTime =
              DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return aTime.compareTo(bTime);
        });

        for (var msg in data) {
          _addMessage(msg);
        }
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
        _addMessage(newMessage);

        socketService.sendMessage({
          'from': currentUserId,
          'to': receiverId,
          'message': text,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          if (base64Image != null && base64Image.isNotEmpty)
            'image': base64Image,
          if (base64File != null) ...{
            'file': base64File,
            'fileName': fileName,
            'mimeType': mimeType,
          },
          if (replyToMessageId != null) 'replyTo': replyToMessageId,
          if (reaction != null) 'reaction': reaction,
        });

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
    String? lastSeenMessageId;

    for (var msg in chatMessages) {
      if (msg['receiverId'] == currentUserId &&
          msg['senderId'] == otherUserId) {
        msg['status'] = 'seen';
        lastSeenMessageId ??= msg['id'] ?? msg['_id'];
      }
    }

    chatMessages.refresh();

    if (lastSeenMessageId != null) {
      socketService.markMessageAsSeen(otherUserId, lastSeenMessageId);
    }
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

  void clearCurrentChat() {
    currentChatUserId = null;
    chatMessages.clear();
    _messageIds.clear();
    chatMessages.refresh();
  }
}
