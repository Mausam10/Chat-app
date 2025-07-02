import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

class CallController extends GetxController {
  IO.Socket? socket;
  rtc.RTCPeerConnection? peerConnection;
  rtc.MediaStream? localStream;
  rtc.MediaStream? remoteStream;

  final localRenderer = rtc.RTCVideoRenderer();
  final remoteRenderer = rtc.RTCVideoRenderer();

  final isCalling = false.obs;
  final callAccepted = false.obs;

  @override
  void onInit() {
    super.onInit();
    initRenderers();
    connectSocket();
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  void connectSocket() {
    socket = IO.io('http://localhost:5001', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket!.on('connect', (_) {
      print('Connected to signaling server');
    });

    socket!.on('incoming-call', (data) async {
      print('Incoming call from: ${data['from']}');
      await _createPeerConnection(isCaller: false);

      // Signal from caller (offer SDP)
      var signal = data['signal'];
      peerConnection!.setRemoteDescription(
        rtc.RTCSessionDescription(signal['sdp'], signal['type']),
      );

      callAccepted.value = true;

      // Create answer and send back
      rtc.RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      socket!.emit('answer-call', {
        'signal': {'sdp': answer.sdp, 'type': answer.type},
        'to': data['from'],
      });
    });

    socket!.on('call-accepted', (signal) async {
      print('Call accepted');
      callAccepted.value = true;
      await peerConnection!.setRemoteDescription(
        rtc.RTCSessionDescription(signal['sdp'], signal['type']),
      );
    });
  }

  Future<void> startCall(String userToCall) async {
    await _createPeerConnection(isCaller: true);

    rtc.RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    socket!.emit('call-user', {
      'userToCall': userToCall,
      'signal': {'sdp': offer.sdp, 'type': offer.type},
      'from': socket!.id,
    });

    isCalling.value = true;
  }

  Future<void> _createPeerConnection({required bool isCaller}) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    peerConnection = await rtc.createPeerConnection(config);

    localStream = await rtc.navigator!.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    localRenderer.srcObject = localStream;

    // Add local stream tracks to connection
    localStream!.getTracks().forEach((track) {
      peerConnection!.addTrack(track, localStream!);
    });

    peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        socket!.emit('ice-candidate', {
          'candidate': candidate.toMap(),
          'to':
              isCaller
                  ? 'userToCallId'
                  : 'callerId', // You will need to manage this properly
        });
      }
    };

    peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        remoteRenderer.srcObject = remoteStream;
      }
    };
  }

  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    peerConnection?.close();
    socket?.disconnect();
    super.dispose();
  }
}
