import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../services/socket_service.dart';

class MessageController extends GetxController {
  final storage = GetStorage();
  final chatMessages = <Map<String, dynamic>>[].obs;
  final recentChats = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isTyping = false.obs;

  late final SocketService socketService;
  String? currentChatUserId;
  String get currentUserId => storage.read('user_id') ?? '';
  final String baseUrl = 'http://192.168.1.70:5001/api';

  final Set<String> _messageIds = {}; // for deduplication
  Timer? _typingDebounce;

  @override
  void onInit() {
    super.onInit();
    socketService = Get.find<SocketService>();
    socketService.onNewMessage(_onMessageReceived);
    socketService.onTyping(_onTyping);
    socketService.onMessageSeen(_onSeen);
    socketService.onReactionReceived(_onReaction);
  }

  void _onMessageReceived(dynamic data) {
    final msg = _normalize(data);
    if (!_isDuplicate(msg)) {
      final sender = msg['senderId'], receiver = msg['receiverId'];
      final relevant =
          (sender == currentChatUserId && receiver == currentUserId) ||
          (sender == currentUserId && receiver == currentChatUserId);
      if (relevant) _addMessage(msg);
    }
  }

  void _onTyping(dynamic data) {
    if (data is Map && data['from'] == currentChatUserId) {
      isTyping.value = true;
      Future.delayed(const Duration(seconds: 2), () => isTyping.value = false);
    }
  }

  void _onSeen(dynamic data) {
    final id = data['messageId'];
    final i = chatMessages.indexWhere((m) => m['id'] == id || m['_id'] == id);
    if (i != -1) {
      chatMessages[i]['status'] = 'seen';
      chatMessages.refresh();
    }
  }

  void _onReaction(dynamic data) {
    final messageId = data['messageId'];
    final emoji = data['reaction'];
    final index = chatMessages.indexWhere(
      (m) => m['id'] == messageId || m['_id'] == messageId,
    );
    if (index != -1) {
      chatMessages[index]['reaction'] = emoji;
      chatMessages.refresh();
    }
  }

  void startConversation(String userId) {
    if (currentChatUserId != userId) {
      chatMessages.clear();
      _messageIds.clear();
    }
    currentChatUserId = userId;
    final room = _roomId(currentUserId, userId);
    socketService.joinRoom(room, userId: currentUserId);
    fetchMessages(userId);
  }

  Future<void> fetchMessages(String userId) async {
    isLoading.value = true;
    chatMessages.clear();
    _messageIds.clear();
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
        final List list = json.decode(res.body);
        list.sort(
          (a, b) => DateTime.parse(
            a['createdAt'],
          ).compareTo(DateTime.parse(b['createdAt'])),
        );
        list.forEach((msg) => _addMessage(_normalize(msg)));
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRecentChats() async {
    try {
      final token = storage.read('auth_token');
      final res = await http.get(
        Uri.parse('$baseUrl/messages/recent/$currentUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        recentChats.value = json.decode(res.body).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
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
      final body = {
        'text': text,
        'senderId': currentUserId,
        'receiverId': receiverId,
        'status': 'sent',
        if (base64Image?.isNotEmpty ?? false) 'image': base64Image,
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
        final newMsg = _normalize(json.decode(res.body));
        _addMessage(newMsg);
        socketService.sendMessage({...newMsg});
        return true;
      }
    } catch (_) {}
    return false;
  }

  void sendTypingEvent(String receiverId) {
    if (_typingDebounce?.isActive ?? false) _typingDebounce!.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 1500), () {
      socketService.sendTypingEvent(receiverId);
    });
  }

  void sendReaction(String messageId, String emoji) {
    final index = chatMessages.indexWhere(
      (m) => m['id'] == messageId || m['_id'] == messageId,
    );
    if (index != -1) {
      chatMessages[index]['reaction'] = emoji;
      chatMessages.refresh();
      socketService.sendReaction(messageId, emoji);
    }
  }

  void markMessagesAsSeen(String userId) {
    String? seenId;
    for (final m in chatMessages) {
      if (m['receiverId'] == currentUserId && m['senderId'] == userId) {
        m['status'] = 'seen';
        seenId ??= m['id'] ?? m['_id'];
      }
    }
    chatMessages.refresh();
    if (seenId != null) socketService.markMessageAsSeen(userId, seenId);
  }

  void clearCurrentChat() {
    currentChatUserId = null;
    chatMessages.clear();
    _messageIds.clear();
  }

  void _addMessage(Map<String, dynamic> msg) {
    if (!_isDuplicate(msg)) {
      chatMessages.add(msg);
      chatMessages.refresh();
    }
  }

  bool _isDuplicate(Map<String, dynamic> msg) {
    final id = msg['id'] ?? msg['_id'];
    if (id == null || _messageIds.contains(id)) return true;
    _messageIds.add(id);
    return false;
  }

  Map<String, dynamic> _normalize(dynamic data) {
    final map = Map<String, dynamic>.from(data);
    if (map.containsKey('message')) map['text'] = map['message'];
    map['senderId'] ??= map['from'];
    map['receiverId'] ??= currentUserId;
    map['timestamp'] ??= DateTime.now().toIso8601String();
    return map;
  }

  String _roomId(String a, String b) {
    final sorted = [a, b]..sort();
    return 'chat_${sorted.join("_")}';
  }
}
