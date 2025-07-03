import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

class SocketService extends GetxService {
  final String baseUrl;
  IO.Socket? _socket;

  // Connection state
  RxBool get isConnectedObs => _isConnected;
  final RxBool _isConnected = false.obs;
  final RxBool _isConnecting = false.obs;
  final RxString _connectionStatus = 'disconnected'.obs;

  // User info
  String? _userId;
  String? _token;

  // Reconnection settings
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 2);
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // Getters
  bool get isConnected => _isConnected.value;
  bool get isConnecting => _isConnecting.value;
  String get connectionStatus => _connectionStatus.value;
  IO.Socket? get socket => _socket;

  SocketService({required this.baseUrl});

  @override
  void onInit() {
    super.onInit();
    _initializeConnectionStatusListener();
    _autoInitializeSocket();
  }

  @override
  void onClose() {
    _cleanupSocket();
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.onClose();
  }

  void _initializeConnectionStatusListener() {
    _isConnected.listen((connected) {
      _connectionStatus.value = connected ? 'connected' : 'disconnected';
      if (connected) {
        _reconnectAttempts = 0;
        _startHeartbeat();
      } else {
        _heartbeatTimer?.cancel();
      }
    });
  }

  void _autoInitializeSocket() {
    // Auto-initialize socket if credentials are available
    final storage = GetStorage();
    final userId = storage.read('user_id');
    final token = storage.read('auth_token');

    if (userId != null && token != null) {
      print('[SocketService] 🚀 Auto-initializing socket for user: $userId');
      initSocket(userId: userId, token: token);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 25), (timer) {
      if (_isConnected.value) {
        print('[SocketService] 💓 Sending heartbeat');
        _socket?.emit('ping');
      }
    });
  }

  Future<void> initSocket({
    required String userId,
    required String token,
  }) async {
    if (userId.isEmpty || token.isEmpty) {
      print('[SocketService] ❌ Missing userId or token');
      throw ArgumentError('UserId and token are required');
    }

    // If already connected with same credentials, return
    if (_isConnected.value && _userId == userId && _token == token) {
      print('[SocketService] ✅ Already connected with same credentials');
      return;
    }

    _userId = userId;
    _token = token;

    await _createSocket();
  }

  Future<void> _createSocket() async {
    if (_socket?.connected == true) {
      print('[SocketService] ⚠️ Disconnecting existing socket');
      _socket?.disconnect();
    }

    _isConnecting.value = true;

    try {
      print('[SocketService] 🔄 Creating socket connection to: $baseUrl');
      print('[SocketService] 🔐 Authenticating with userId: $_userId');

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(maxReconnectAttempts)
            .setReconnectionDelay(reconnectDelay.inMilliseconds)
            .setAuth({'userId': _userId!, 'token': _token!})
            .build(),
      );

      _setupSocketListeners();

      print('[SocketService] 🔄 Socket initialized and connecting as $_userId');
    } catch (e) {
      _isConnecting.value = false;
      print('[SocketService] ❌ Failed to create socket: $e');
      rethrow;
    }
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      _isConnected.value = true;
      _isConnecting.value = false;
      _reconnectAttempts = 0;
      print('[SocketService] 🔌 Connected successfully');
    });

    _socket?.onDisconnect((reason) {
      _isConnected.value = false;
      _isConnecting.value = false;
      print('[SocketService] ❌ Disconnected: $reason');

      // Auto-reconnect if not intentionally disconnected
      if (reason != 'io client disconnect') {
        _attemptReconnection();
      }
    });

    _socket?.onConnectError((error) {
      _isConnected.value = false;
      _isConnecting.value = false;
      print('[SocketService] ⚠️ Connect Error: $error');
      _attemptReconnection();
    });

    _socket?.onError((error) {
      print('[SocketService] ⚠️ Socket Error: $error');
    });

    _socket?.onReconnect((attempt) {
      print('[SocketService] 🔄 Reconnected after $attempt attempts');
    });

    _socket?.onReconnectError((error) {
      print('[SocketService] ⚠️ Reconnection Error: $error');
    });

    _socket?.onReconnectFailed((_) {
      print(
        '[SocketService] ❌ Reconnection failed after $maxReconnectAttempts attempts',
      );
      _connectionStatus.value = 'failed';
    });

    // Heartbeat response
    _socket?.on('pong', (_) {
      print('[SocketService] 💓 Heartbeat received');
    });
  }

  void _attemptReconnection() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('[SocketService] ❌ Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(
      Duration(seconds: reconnectDelay.inSeconds * _reconnectAttempts),
      () {
        if (!_isConnected.value && _userId != null && _token != null) {
          print(
            '[SocketService] 🔄 Attempting reconnection $_reconnectAttempts/$maxReconnectAttempts',
          );
          _createSocket();
        }
      },
    );
  }

  void _cleanupSocket() {
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket = null;
    _isConnected.value = false;
    _isConnecting.value = false;
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    if (_socket?.connected == true) {
      _socket?.disconnect();
    }
    _cleanupSocket();
    print('[SocketService] 🔌 Disconnected manually');
  }

  Future<void> connect() async {
    if (_isConnected.value || _isConnecting.value) {
      print('[SocketService] ⚠️ Already connected or connecting');
      return;
    }

    if (_userId == null || _token == null) {
      print('[SocketService] ❌ Cannot connect: Missing credentials');
      throw StateError('Socket not initialized. Call initSocket first.');
    }

    if (_socket?.disconnected == true) {
      _socket?.connect();
      print('[SocketService] 🔄 Manually reconnecting...');
    } else {
      await _createSocket();
    }
  }

  // Connection status stream
  Stream<bool> get connectionStream => _isConnected.stream;
  Stream<String> get connectionStatusStream => _connectionStatus.stream;

  // Utility method to ensure connection
  bool _ensureConnection() {
    if (!_isConnected.value) {
      print('[SocketService] ⚠️ Socket not connected');
      return false;
    }
    return true;
  }

  // --- Core Socket Methods ---

  void joinRoom(String roomId, {required String userId}) {
    if (!_ensureConnection()) return;

    if (roomId.isEmpty || userId.isEmpty) {
      print('[SocketService] ⚠️ Invalid room or userId');
      return;
    }

    print('[SocketService] 🏠 Joining room: $roomId as $userId');
    _socket?.emit('join-room', {'roomId': roomId, 'userId': userId});
  }

  void leaveRoom(String roomId, {required String userId}) {
    if (!_ensureConnection()) return;

    print('[SocketService] 🚪 Leaving room: $roomId as $userId');
    _socket?.emit('leave-room', {'roomId': roomId, 'userId': userId});
  }

  // --- Online Users ---

  void onOnlineUsersUpdated(void Function(List<String>) callback) {
    _socket?.on('getOnlineUsers', (data) {
      print('[SocketService] 👥 Online users updated: $data');
      if (data is List) {
        callback(List<String>.from(data));
      }
    });
  }

  // --- Enhanced Messaging ---

  void sendMessage(Map<String, dynamic> message) {
    if (!_ensureConnection()) return;

    final receiverId = message['receiverId'];
    final text = message['text'];

    if (receiverId == null || text == null) {
      print('[SocketService] ⚠️ Invalid message format');
      return;
    }

    // Generate room ID for the conversation
    final roomId = _generateRoomId(_userId!, receiverId);

    final messageData = {
      'message': text,
      'to': receiverId,
      'roomId': roomId,
      ...message,
    };

    print(
      '[SocketService] 📤 Sending message: $text to $receiverId in room: $roomId',
    );
    _socket?.emit('sendMessage', messageData);
  }

  void onNewMessage(void Function(Map<String, dynamic>) callback) {
    // Listen for direct messages
    _socket?.on('receiveMessage', (data) {
      print('[SocketService] 📥 Direct message received: $data');
      try {
        Map<String, dynamic> messageData;
        if (data is Map<String, dynamic>) {
          messageData = data;
        } else if (data is Map) {
          messageData = Map<String, dynamic>.from(data);
        } else {
          print('[SocketService] ⚠️ Unexpected message format: $data');
          return;
        }
        callback(messageData);
      } catch (e) {
        print('[SocketService] ❌ Error processing direct message: $e');
      }
    });

    // Listen for room messages
    _socket?.on('new-message', (data) {
      print('[SocketService] 📥 Room message received: $data');
      try {
        Map<String, dynamic> messageData;
        if (data is Map<String, dynamic>) {
          messageData = data;
        } else if (data is Map) {
          messageData = Map<String, dynamic>.from(data);
        } else {
          print('[SocketService] ⚠️ Unexpected room message format: $data');
          return;
        }
        callback(messageData);
      } catch (e) {
        print('[SocketService] ❌ Error processing room message: $e');
      }
    });

    // Listen for message sent confirmation
    _socket?.on('messageSent', (data) {
      print('[SocketService] ✅ Message sent confirmation: $data');
      // You can handle message status updates here
    });
  }

  // --- Enhanced Typing Events ---

  void sendTypingEvent(String toUserId) {
    if (!_ensureConnection() || toUserId.isEmpty) return;

    final roomId = _generateRoomId(_userId!, toUserId);
    print(
      '[SocketService] ✍️ Sending typing event to: $toUserId in room: $roomId',
    );
    _socket?.emit('typing', {'to': toUserId, 'roomId': roomId});
  }

  void sendStoppedTypingEvent(String toUserId) {
    if (!_ensureConnection() || toUserId.isEmpty) return;

    final roomId = _generateRoomId(_userId!, toUserId);
    print(
      '[SocketService] ✍️ Sending stopped typing event to: $toUserId in room: $roomId',
    );
    _socket?.emit('stop-typing', {'to': toUserId, 'roomId': roomId});
  }

  void onTyping(void Function(Map<String, dynamic>) callback) {
    _socket?.on('userTyping', (data) {
      print('[SocketService] ✍️ Direct typing event received: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('user-typing', (data) {
      print('[SocketService] ✍️ Room typing event received: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onStoppedTyping(void Function(Map<String, dynamic>) callback) {
    _socket?.on('userStoppedTyping', (data) {
      print('[SocketService] ✍️ Direct stopped typing event received: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('user-stopped-typing', (data) {
      print('[SocketService] ✍️ Room stopped typing event received: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  // --- Message Status ---

  void markMessageAsSeen(String toUserId, String messageId) {
    if (!_ensureConnection() || toUserId.isEmpty) return;

    print(
      '[SocketService] 👁️ Marking message as seen: $messageId for user: $toUserId',
    );
    _socket?.emit('messageSeen', {'to': toUserId, 'messageId': messageId});
  }

  void onMessageSeen(void Function(Map<String, dynamic>) callback) {
    _socket?.on('messageSeen', (data) {
      print('[SocketService] 👁️ Message seen event received: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  // --- Reactions ---

  void sendReaction(String messageId, String reaction) {
    if (!_ensureConnection() || messageId.isEmpty || reaction.isEmpty) return;

    print(
      '[SocketService] 😊 Sending reaction: $reaction for message: $messageId',
    );
    _socket?.emit('message-reaction', {
      'messageId': messageId,
      'reaction': reaction,
    });
  }

  void onReactionReceived(void Function(Map<String, dynamic>) callback) {
    _socket?.on('message-reaction', (data) {
      print('[SocketService] 😊 Reaction received: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  // --- Call Events ---

  void emitCallRequest(String receiverId, String callerName, bool isVideoCall) {
    if (!_ensureConnection() || receiverId.isEmpty || callerName.isEmpty)
      return;

    print('[SocketService] 📞 Emitting call request to: $receiverId');
    _socket?.emit('call-request', {
      'receiverId': receiverId,
      'callerName': callerName,
      'isVideoCall': isVideoCall,
    });
  }

  void emitCallAccepted(String receiverId, bool isVideoCall) {
    if (!_ensureConnection() || receiverId.isEmpty) return;

    print('[SocketService] ✅ Emitting call accepted to: $receiverId');
    _socket?.emit('call-accepted', {
      'receiverId': receiverId,
      'isVideoCall': isVideoCall,
    });
  }

  void emitCallRejected(String receiverId) {
    if (!_ensureConnection() || receiverId.isEmpty) return;

    print('[SocketService] ❌ Emitting call rejected to: $receiverId');
    _socket?.emit('call-rejected', {'receiverId': receiverId});
  }

  void emitCallCancelled(String receiverId) {
    if (!_ensureConnection() || receiverId.isEmpty) return;

    print('[SocketService] 🚫 Emitting call cancelled to: $receiverId');
    _socket?.emit('call-cancelled', {'receiverId': receiverId});
  }

  void emitCallEnded(String receiverId) {
    if (!_ensureConnection() || receiverId.isEmpty) return;

    print('[SocketService] 📞 Emitting call ended to: $receiverId');
    _socket?.emit('call-ended', {'receiverId': receiverId});
  }

  // --- Call Event Listeners ---

  void onIncomingCall(void Function(Map<String, dynamic>) callback) {
    _socket?.on('incoming-call', (data) {
      print('[SocketService] 📞 Incoming call: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onCallAccepted(void Function(Map<String, dynamic>) callback) {
    _socket?.on('call-accepted', (data) {
      print('[SocketService] ✅ Call accepted: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onCallRejected(void Function(Map<String, dynamic>) callback) {
    _socket?.on('call-rejected', (data) {
      print('[SocketService] ❌ Call rejected: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onCallCancelled(void Function(Map<String, dynamic>) callback) {
    _socket?.on('call-cancelled', (data) {
      print('[SocketService] 🚫 Call cancelled: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onCallEnded(void Function(Map<String, dynamic>) callback) {
    _socket?.on('call-ended', (data) {
      print('[SocketService] 📞 Call ended: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  // --- Room Events ---

  void onRoomJoined(void Function(Map<String, dynamic>) callback) {
    _socket?.on('room-joined', (data) {
      print('[SocketService] 🏠 Room joined: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onUserJoined(void Function(Map<String, dynamic>) callback) {
    _socket?.on('user-joined', (data) {
      print('[SocketService] 👤 User joined room: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onUserLeft(void Function(Map<String, dynamic>) callback) {
    _socket?.on('user-left', (data) {
      print('[SocketService] 👤 User left room: $data');
      if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  // --- Utility Methods ---

  String _generateRoomId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return 'chat_${sorted.join("_")}';
  }

  void removeAllListeners() {
    _socket?.clearListeners();
  }

  void removeListener(String event) {
    _socket?.off(event);
  }

  // Health check
  Future<bool> ping() async {
    if (!_ensureConnection()) return false;

    final completer = Completer<bool>();
    final timer = Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    _socket?.emit('ping');
    _socket?.once('pong', (_) {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    });

    return completer.future;
  }
}
