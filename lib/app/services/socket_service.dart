import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SocketService extends GetxService {
  late IO.Socket socket;
  final storage = GetStorage();

  Future<SocketService> init() async {
    final userId = storage.read('user_id');

    socket = IO.io('http://192.168.56.1:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
    });

    socket.connect();

    socket.onConnect((_) {
      print('🔌 Socket connected');
      socket.emit('user_connected', userId);
    });

    socket.onDisconnect((_) => print('🛑 Socket disconnected'));

    return this;
  }

  void sendMessage(Map<String, dynamic> message) {
    socket.emit('message:new', message);
  }

  void onMessageReceive(Function(dynamic) handler) {
    socket.on('message:receive', handler);
  }

  void sendCallOffer(Map<String, dynamic> offer) {
    socket.emit('call:offer', offer);
  }

  void onCallOffer(Function(dynamic) handler) {
    socket.on('call:offer', handler);
  }

  void sendCallAnswer(Map<String, dynamic> answer) {
    socket.emit('call:answer', answer);
  }

  void onCallAnswer(Function(dynamic) handler) {
    socket.on('call:answer', handler);
  }

  void sendIceCandidate(Map<String, dynamic> candidate) {
    socket.emit('call:ice-candidate', candidate);
  }

  void onIceCandidate(Function(dynamic) handler) {
    socket.on('call:ice-candidate', handler);
  }

  void disposeService() {
    socket.dispose();
  }
}
