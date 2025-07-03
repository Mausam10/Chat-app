import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

import '../services/socket_service.dart';
import '../models/user_model.dart';

class HomeController extends GetxController {
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<String> onlineUserIds = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;
  final RxString searchQuery = ''.obs;

  final storage = GetStorage();
  late final SocketService socketService;

  String? get currentUserId => storage.read('user_id');

  @override
  void onInit() {
    super.onInit();
    _initSocket();
    fetchUsers();
  }

  /// Initialize socket and setup event listeners for HomeScreen features
  void _initSocket() {
    final userId = currentUserId ?? '';
    final token = storage.read('auth_token') ?? '';
    const baseUrl = 'http://192.168.1.70:5001';

    if (userId.isNotEmpty && token.isNotEmpty) {
      socketService = SocketService(baseUrl: baseUrl);
      socketService.initSocket(userId: userId, token: token);
      socketService.connect();

      // Online users update event
      socketService.onOnlineUsersUpdated((List<String> onlineIds) {
        onlineUserIds.assignAll(onlineIds);
      });

      // New message event handler
      socketService.onNewMessage((data) {
        final senderId = data['senderId'] as String? ?? '';
        final message = data['message'] as String? ?? '';
        final timeStr = data['createdAt'] as String? ?? '';
        DateTime time;
        try {
          time = DateTime.parse(timeStr);
        } catch (_) {
          time = DateTime.now();
        }

        final index = users.indexWhere((u) => u.id == senderId);
        if (index != -1) {
          // Create a new UserModel instance with updated values
          final user = users[index];
          final updatedUser = UserModel(
            id: user.id,
            fullName: user.fullName,
            email: user.email,
            profilePic: user.profilePic,
            isAdmin: user.isAdmin,
            lastMessage: message,
            lastMessageTime: time,
            unreadCount: user.unreadCount + 1,
            isTyping: user.isTyping,
          );
          users[index] = updatedUser; // trigger update
          _sortUsersByLastMessage();
          _updateUnreadCount();
        } else {
          // Optionally fetch user info if not in list
        }
      });

      // Typing indicator handler
      socketService.onTyping((data) {
        final userId = data['userId'] as String? ?? '';
        final isTyping = data['isTyping'] as bool? ?? false;
        final index = users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          final user = users[index];
          final updatedUser = UserModel(
            id: user.id,
            fullName: user.fullName,
            email: user.email,
            profilePic: user.profilePic,
            isAdmin: user.isAdmin,
            lastMessage: user.lastMessage,
            lastMessageTime: user.lastMessageTime,
            unreadCount: user.unreadCount,
            isTyping: isTyping,
          );
          users[index] = updatedUser; // trigger update
        }
      });
    }
  }

  /// Fetch users list from API and sort by last message time desc
  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final token = storage.read('auth_token');
      final res = await http.get(
        Uri.parse('http://192.168.1.70:5001/api/users/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        final loadedUsers = data.map((e) => UserModel.fromJson(e)).toList();

        // Initialize extra fields to avoid null errors
        for (var u in loadedUsers) {
          // Fields are already properly initialized from fromJson
          // Only set defaults if they're null (shouldn't happen with current model)
          u.lastMessage ??= '';
          u.lastMessageTime ??= DateTime.fromMillisecondsSinceEpoch(0);
          // unreadCount and isTyping already have defaults in the model
        }

        users.assignAll(loadedUsers);
        _sortUsersByLastMessage();
        _updateUnreadCount();
      }
    } catch (e) {
      print('❌ fetchUsers error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sort users by last message time descending
  void _sortUsersByLastMessage() {
    users.sort(
      (a, b) => (b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(
            a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
    );
  }

  /// Update global unread message count
  void _updateUnreadCount() {
    unreadCount.value = users.fold(0, (sum, u) => sum + u.unreadCount);
  }

  /// Mark all messages as read for a given user
  void markMessagesAsRead(String otherUserId) {
    final index = users.indexWhere((u) => u.id == otherUserId);
    if (index != -1) {
      final user = users[index];
      final updatedUser = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        profilePic: user.profilePic,
        isAdmin: user.isAdmin,
        lastMessage: user.lastMessage,
        lastMessageTime: user.lastMessageTime,
        unreadCount: 0, // Reset unread count
        isTyping: user.isTyping,
      );
      users[index] = updatedUser; // update
      _updateUnreadCount();
      socketService.markMessageAsSeen(
        otherUserId,
        '',
      ); // MessageId can be optional here or pass actual id
    }
  }

  /// Send typing indicator event to server
  void sendTypingEvent(String toUserId) {
    socketService.sendTypingEvent(toUserId);
  }

  /// Send a new chat message
  void sendMessage(Map<String, dynamic> messageData) {
    socketService.sendMessage(messageData);
  }

  /// Get filtered users based on search query
  List<UserModel> get filteredUsers {
    if (searchQuery.value.isEmpty) {
      return users;
    }
    return users.where((user) {
      final name = user.fullName.toLowerCase();
      final email = user.email.toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Clear search query
  void clearSearch() {
    searchQuery.value = '';
  }

  /// Check if user is online
  bool isUserOnline(String userId) {
    return onlineUserIds.contains(userId);
  }

  /// Refresh users list
  Future<void> refreshUsers() async {
    await fetchUsers();
  }

  @override
  void onClose() {
    socketService.disconnect();
    super.onClose();
  }
}
