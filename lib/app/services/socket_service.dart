import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  final String userId;

  SocketService({required this.userId});

  void connect() {
    print("Connecting to socket with userId: $userId");

    socket = IO.io(
      'http://localhost:5001', // Change this to your backend URL
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setQuery({'userId': userId})
          .setTimeout(5000)
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('Socket connected as $userId');
    });

    socket.onConnectError((error) {
      print('Connect error: $error');
    });

    socket.onError((error) {
      print('Socket error: $error');
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });

    // Handle online users list update from server
    socket.on('getOnlineUsers', (data) {
      print('Online users: $data');
      _onOnlineUsersUpdated?.call(List<String>.from(data));
    });

    // User joined/left room events
    socket.on('user-joined', (data) => print('User joined room: $data'));
    socket.on('user-left', (data) => print('User left room: $data'));

    // WebRTC signaling events
    socket.on('offer', (data) => print('Offer received: $data'));
    socket.on('answer', (data) => print('Answer received: $data'));
    socket.on(
      'ice-candidate',
      (data) => print('ICE candidate received: $data'),
    );

    // Messaging events
    socket.on('receiveMessage', (data) {
      print('Message received: $data');
      _onMessageReceived?.call(data);
    });

    socket.on('messageSeen', (data) {
      print('Message seen: $data');
      _onMessageSeen?.call(data);
    });

    socket.on('userTyping', (data) {
      print('User typing: $data');
      _onUserTyping?.call(data);
    });
  }

  void disconnect() {
    socket.disconnect();
    print("Socket disconnected manually.");
  }

  // Callbacks for external listeners
  Function(List<String>)? _onOnlineUsersUpdated;
  Function(dynamic)? _onMessageReceived;
  Function(dynamic)? _onMessageSeen;
  Function(dynamic)? _onUserTyping;

  // Register callback for online users update
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

  // Emit events for chat features

  void sendMessage(String toUserId, String message) {
    socket.emit('sendMessage', {'to': toUserId, 'message': message});
  }

  void markMessageAsSeen(String toUserId, String messageId) {
    socket.emit('messageSeen', {'to': toUserId, 'messageId': messageId});
  }

  void sendTypingEvent(String toUserId) {
    socket.emit('typing', {'to': toUserId});
  }

  // Room & WebRTC signaling emits

  void joinRoom(String roomId) {
    socket.emit('join-room', {'roomId': roomId, 'userId': userId});
  }

  void sendOffer(String toUserId, Map<String, dynamic> offer) {
    socket.emit('offer', {'offer': offer, 'to': toUserId});
  }

  void sendAnswer(String toUserId, Map<String, dynamic> answer) {
    socket.emit('answer', {'answer': answer, 'to': toUserId});
  }

  void sendIceCandidate(String toUserId, Map<String, dynamic> candidate) {
    socket.emit('ice-candidate', {'candidate': candidate, 'to': toUserId});
  }
}
