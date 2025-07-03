import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef JsonMap = Map<String, dynamic>;

class SocketService {
  final String baseUrl;
  late IO.Socket socket;

  bool _connected = false;
  bool get isConnected => _connected;

  String? _userId;
  String? _token;

  final List<JsonMap> _pendingMessages = [];
  final List<Function()> _pendingActions = [];

  Timer? _typingTimer;

  SocketService({required this.baseUrl});

  // Initialize and configure socket with auth
  void initSocket({required String userId, required String token}) {
    _userId = userId;
    _token = token;

    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .enableReconnection()
          .setQuery({'token': token, 'userId': userId})
          .build(),
    );

    socket.onConnect((_) {
      _connected = true;
      print('[Socket] Connected');
      _flushPendingMessages();
      _flushPendingActions();
      joinRoom(userId);
    });

    socket.onDisconnect((_) {
      _connected = false;
      print('[Socket] Disconnected');
    });

    socket.onConnectError((data) {
      print('[Socket] Connect error: $data');
    });

    socket.onError((data) {
      print('[Socket] Error: $data');
    });
  }

  void connect() {
    if (!_connected) {
      socket.connect();
    }
  }

  void disconnect() {
    if (_connected) {
      socket.disconnect();
    }
  }

  void joinRoom(String roomId, {String? userId}) {
    if (_connected) {
      socket.emit('joinRoom', {'roomId': roomId, 'userId': userId ?? _userId});
      print('[Socket] Join room: $roomId');
    } else {
      _pendingActions.add(() => joinRoom(roomId, userId: userId));
    }
  }

  void onOnlineUsersUpdated(void Function(List<String>) callback) {
    socket.on('getOnlineUsers', (data) {
      if (data is List) {
        final List<String> onlineIds = List<String>.from(data);
        callback(onlineIds);
      }
    });
  }

  void onNewMessage(void Function(JsonMap) callback) {
    socket.on('receiveMessage', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onTyping(void Function(JsonMap) callback) {
    socket.on('userTyping', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void sendMessage(JsonMap messageData) {
    if (_connected) {
      socket.emit('sendMessage', messageData);
    } else {
      _pendingMessages.add(messageData);
    }
  }

  void markMessageAsSeen(String toUserId, String messageId) {
    final data = {'toUserId': toUserId, 'messageId': messageId};
    if (_connected) {
      socket.emit('markAsSeen', data);
    } else {
      _pendingActions.add(() => markMessageAsSeen(toUserId, messageId));
    }
  }

  void sendTypingEvent(String toUserId, {int debounceMs = 2000}) {
    if (_typingTimer?.isActive ?? false) return;

    if (_connected) {
      socket.emit('typing', {'toUserId': toUserId});
      _typingTimer = Timer(Duration(milliseconds: debounceMs), () {});
    }
  }

  void sendReaction(String messageId, String emoji) {
    final data = {'messageId': messageId, 'reaction': emoji};
    if (_connected) {
      socket.emit('react', data);
    } else {
      _pendingActions.add(() => sendReaction(messageId, emoji));
    }
  }

  void onMessageSeen(void Function(Map<String, dynamic>) callback) {
    socket.on('messageSeen', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onReactionReceived(void Function(Map<String, dynamic>) callback) {
    socket.on('reaction', (data) {
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void registerHandlers({
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(Map<String, dynamic>) onTypingCallback,
    required void Function(Map<String, dynamic>) onSeen,
    required void Function(Map<String, dynamic>) onReaction,
  }) {
    onNewMessage(onMessage);
    onTyping(onTypingCallback);
    onMessageSeen(onSeen);
    onReactionReceived(onReaction);
  }

  void _flushPendingMessages() {
    for (var msg in _pendingMessages) {
      socket.emit('sendMessage', msg);
    }
    _pendingMessages.clear();
  }

  void _flushPendingActions() {
    for (var action in _pendingActions) {
      action();
    }
    _pendingActions.clear();
  }
}
