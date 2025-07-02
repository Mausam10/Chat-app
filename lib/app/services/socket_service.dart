import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  final String baseUrl;

  // Callbacks
  Function(List<String>)? _onOnlineUsersUpdated;
  Function(dynamic)? _onMessageReceived;
  Function(dynamic)? _onMessageSeen;
  Function(dynamic)? _onUserTyping;

  final List<Map<String, dynamic>> _pendingMessages = [];

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

      // Flush pending messages
      if (_pendingMessages.isNotEmpty) {
        print('📤 Flushing ${_pendingMessages.length} pending messages...');
        for (var msg in _pendingMessages) {
          socket.emit('sendMessage', msg);
        }
        _pendingMessages.clear();
      }
    });

    socket.onConnectError((err) => print('❌ Connect error: $err'));
    socket.onError((err) => print('❌ Socket error: $err'));
    socket.onDisconnect((_) => print('⚠️ Socket disconnected'));

    socket.on('getOnlineUsers', (data) {
      print('👥 Online users: $data');
      _onOnlineUsersUpdated?.call(List<String>.from(data));
    });

    socket.on('receiveMessage', (data) {
      print('📩 Message received: $data');
      _onMessageReceived?.call(data);
    });

    socket.on('messageSeen', (data) {
      print('👁️ Message seen: $data');
      _onMessageSeen?.call(data);
    });

    socket.on('userTyping', (data) {
      print('⌨️ User typing: $data');
      _onUserTyping?.call(data);
    });

    socket.on('user-joined', (data) => print('🔵 User joined room: $data'));
    socket.on('user-left', (data) => print('🔴 User left room: $data'));

    socket.on('offer', (data) => print('📨 Offer received: $data'));
    socket.on('answer', (data) => print('📨 Answer received: $data'));
    socket.on(
      'ice-candidate',
      (data) => print('📨 ICE candidate received: $data'),
    );

    socket.connect();
  }

  void connect() {
    if (!socket.connected) {
      print('🔌 Connecting socket...');
      socket.connect();
    }
  }

  void disconnect() {
    if (socket.connected) {
      socket.disconnect();
      print('🔌 Socket disconnected manually.');
    }
  }

  void onOnlineUsersUpdated(Function(List<String>) callback) {
    _onOnlineUsersUpdated = callback;
  }

  void onMessageReceived(Function(dynamic) callback) {
    _onMessageReceived = callback;
  }

  void onMessageSeen(Function(dynamic) callback) {
    _onMessageSeen = callback;
  }

  void onUserTyping(Function(dynamic) callback) {
    _onUserTyping = callback;
  }

  void sendMessage(String toUserId, String message) {
    final msgData = {'to': toUserId, 'message': message};
    if (socket.connected) {
      socket.emit('sendMessage', msgData);
      print('📡 Socket message emitted: $msgData');
    } else {
      print('⚠️ Socket not connected. Queuing message...');
      _pendingMessages.add(msgData);
      socket.connect();
    }
  }

  void markMessageAsSeen(String toUserId, String messageId) {
    final data = {'to': toUserId, 'messageId': messageId};
    if (socket.connected) {
      socket.emit('messageSeen', data);
    } else {
      print('⚠️ Socket not connected. Message seen event not emitted.');
    }
  }

  void sendTypingEvent(String toUserId) {
    final data = {'to': toUserId};
    if (socket.connected) {
      socket.emit('typing', data);
    } else {
      print('⚠️ Socket not connected. Typing event not sent.');
    }
  }

  void joinRoom(String roomId, String userId) {
    final data = {'roomId': roomId, 'userId': userId};
    if (socket.connected) {
      socket.emit('join-room', data);
      print('✅ Joined room $roomId as user $userId');
    } else {
      print('⚠️ Socket not connected. Join room failed.');
    }
  }

  void sendOffer(String toUserId, Map<String, dynamic> offer) {
    final data = {'offer': offer, 'to': toUserId};
    if (socket.connected) {
      socket.emit('offer', data);
    } else {
      print('⚠️ Socket not connected. Offer not sent.');
    }
  }

  void sendAnswer(String toUserId, Map<String, dynamic> answer) {
    final data = {'answer': answer, 'to': toUserId};
    if (socket.connected) {
      socket.emit('answer', data);
    } else {
      print('⚠️ Socket not connected. Answer not sent.');
    }
  }

  void sendIceCandidate(String toUserId, Map<String, dynamic> candidate) {
    final data = {'candidate': candidate, 'to': toUserId};
    if (socket.connected) {
      socket.emit('ice-candidate', data);
    } else {
      print('⚠️ Socket not connected. ICE candidate not sent.');
    }
  }
}
