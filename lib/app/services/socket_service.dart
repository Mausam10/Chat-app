import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  final String userId;

  SocketService({required this.userId});

  void connect() {
    print("Connecting to socket with userId: $userId");

    socket = IO.io(
      'http://localhost:5001',
      IO.OptionBuilder()
          .setTransports(['polling', 'websocket'])
          .enableAutoConnect() // Try enabling auto-connect
          .setQuery({'userId': userId})
          .setTimeout(5000) // Add timeout
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

    socket.on('getOnlineUsers', (data) {
      print('Online users: $data');
    });

    socket.on('user-joined', (data) {
      print('User joined room: $data');
    });

    socket.on('offer', (data) {
      print('Offer received: $data');
    });

    socket.on('answer', (data) {
      print('Answer received: $data');
    });

    socket.on('ice-candidate', (data) {
      print('❄️ ICE candidate received: $data');
    });
  }

  void disconnect() {
    socket.disconnect();
    print("🚪 Socket disconnected manually.");
  }

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
