import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:get/get.dart' as gx;

class CallController extends gx.GetxController {
  late IO.Socket socket;
  late RTCPeerConnection peerConnection;
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();
  final isInCall = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initRenderers();
    _connectSocket();
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  void _connectSocket() {
    socket = IO.io('http://192.168.1.70:5001', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connected to socket');
    });

    socket.on('offer', (data) async {
      await _onOfferReceived(data);
    });

    socket.on('answer', (data) async {
      await _onAnswerReceived(data);
    });

    socket.on('ice-candidate', (data) async {
      await _onIceCandidate(data);
    });
  }

  Future<void> startCall(bool isVideoCall) async {
    final mediaConstraints = {
      'audio': true,
      'video': isVideoCall ? {'facingMode': 'user'} : false,
    };

    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localRenderer.srcObject = stream;

    peerConnection = await createPeerConnection(_iceServers());

    stream.getTracks().forEach((track) {
      peerConnection.addTrack(track, stream);
    });

    peerConnection.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    peerConnection.onIceCandidate = (candidate) {
      socket.emit('ice-candidate', {'candidate': candidate.toMap()});
    };

    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    socket.emit('offer', {'sdp': offer.sdp, 'type': offer.type});

    isInCall.value = true;
  }

  Future<void> _onOfferReceived(dynamic data) async {
    await _createPeer();

    await peerConnection.setRemoteDescription(
      RTCSessionDescription(data['sdp'], data['type']),
    );

    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);

    socket.emit('answer', {'sdp': answer.sdp, 'type': answer.type});

    isInCall.value = true;
  }

  Future<void> _onAnswerReceived(dynamic data) async {
    final desc = RTCSessionDescription(data['sdp'], data['type']);
    await peerConnection.setRemoteDescription(desc);
  }

  Future<void> _onIceCandidate(dynamic data) async {
    await peerConnection.addCandidate(
      RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      ),
    );
  }

  Future<void> _createPeer() async {
    peerConnection = await createPeerConnection(_iceServers());

    peerConnection.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    peerConnection.onIceCandidate = (candidate) {
      socket.emit('ice-candidate', {'candidate': candidate.toMap()});
    };
  }

  Map<String, dynamic> _iceServers() => {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // optionally: {'urls': 'turn:turn.server.com', 'username': 'user', 'credential': 'pass'}
    ],
  };

  void endCall() {
    isInCall.value = false;
    peerConnection.close();
    localRenderer.srcObject?.dispose();
    remoteRenderer.srcObject?.dispose();
  }

  @override
  void onClose() {
    socket.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.onClose();
  }
}
