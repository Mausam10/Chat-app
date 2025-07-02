import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  bool _listenersRegistered = false;
  bool _isConnecting = false;

  late IO.Socket socket;
  final String baseUrl;

  Function(dynamic)? _onMessageReceived;
  Function(dynamic)? _onMessageSeen;
  Function(dynamic)? _onUserTyping;
  Function(List<String>)? _onOnlineUsersUpdated;

  final List<Map<String, dynamic>> _pendingMessages = [];
  final List<Function()> _pendingActions = [];

  SocketService({required this.baseUrl});

  void initSocket({required String userId, required String token}) {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token, 'userId': userId})
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print('✅ Socket connected as $userId');

      if (!_listenersRegistered) {
        _registerListeners();
        _listenersRegistered = true;
      }

      _isConnecting = false;

      for (var msg in _pendingMessages) {
        socket.emit('sendMessage', msg);
      }
      _pendingMessages.clear();

      for (var action in _pendingActions) {
        action();
      }
      _pendingActions.clear();
    });

    socket.onConnectError((err) {
      print('❌ Connect error: $err');
      _isConnecting = false;
    });

    socket.onError((err) {
      print('❌ Socket error: $err');
      _isConnecting = false;
    });

    socket.onDisconnect((_) {
      print('⚠️ Socket disconnected');
      _listenersRegistered = false;
    });
  }

  void _registerListeners() {
    socket.on('receiveMessage', (data) => _onMessageReceived?.call(data));
    socket.on('messageSeen', (data) => _onMessageSeen?.call(data));
    socket.on('userTyping', (data) => _onUserTyping?.call(data));
    socket.on('getOnlineUsers', (data) {
      if (data is List) {
        _onOnlineUsersUpdated?.call(data.map((e) => e.toString()).toList());
      }
    });
  }

  void connect() {
    if (!socket.connected && !_isConnecting) {
      _isConnecting = true;
      socket.connect();
    }
  }

  void disconnect() {
    if (socket.connected) socket.disconnect();
    _isConnecting = false;
    _listenersRegistered = false;
  }

  void dispose() {
    socket.clearListeners();
    _listenersRegistered = false;
    _isConnecting = false;
  }

  void onMessageReceived(Function(dynamic) callback) =>
      _onMessageReceived = callback;
  void onMessageSeen(Function(dynamic) callback) => _onMessageSeen = callback;
  void onUserTyping(Function(dynamic) callback) => _onUserTyping = callback;
  void onOnlineUsersUpdated(Function(List<String>) callback) =>
      _onOnlineUsersUpdated = callback;

  void sendMessage(Map<String, dynamic> messageData) {
    if (socket.connected) {
      socket.emit('sendMessage', messageData);
    } else {
      _pendingMessages.add(messageData);
      connect();
    }
  }

  void markMessageAsSeen(String toUserId, String messageId) {
    final data = {'to': toUserId, 'messageId': messageId};
    if (socket.connected) {
      socket.emit('messageSeen', data);
    }
  }

  void sendTypingEvent(String toUserId) {
    final data = {'to': toUserId};
    if (socket.connected) {
      socket.emit('typing', data);
    }
  }

  void joinRoom(String roomId, String userId) {
    final data = {'roomId': roomId, 'userId': userId};
    if (socket.connected) {
      socket.emit('join-room', data);
    } else {
      _pendingActions.add(() => joinRoom(roomId, userId));
      connect();
    }
  }
}
