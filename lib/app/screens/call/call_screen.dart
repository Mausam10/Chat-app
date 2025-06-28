import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:get/get.dart';

class CallScreen extends StatefulWidget {
  final String remoteUserName;
  final bool isVideo;
  const CallScreen({
    super.key,
    required this.remoteUserName,
    required this.isVideo,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final rtc.RTCVideoRenderer _localRenderer = rtc.RTCVideoRenderer();
  final rtc.RTCVideoRenderer _remoteRenderer = rtc.RTCVideoRenderer();
  rtc.MediaStream? _localStream;
  rtc.RTCPeerConnection? _peerConnection;
  bool isMicEnabled = true;
  bool isCameraEnabled = true;

  @override
  void initState() {
    super.initState();
    initRenderers();
    _startCall();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _startCall() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await rtc.createPeerConnection(config);

    _localStream = await rtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.isVideo,
    });

    _localRenderer.srcObject = _localStream;
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onTrack = (rtc.RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  void _toggleMic() {
    setState(() {
      isMicEnabled = !isMicEnabled;
    });
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isMicEnabled;
    });
  }

  void _toggleCamera() {
    setState(() {
      isCameraEnabled = !isCameraEnabled;
    });
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isCameraEnabled;
    });
  }

  void _endCall() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: rtc.RTCVideoView(
              _remoteRenderer,
              objectFit: rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.remoteUserName,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  Text(
                    widget.isVideo ? "Video Call" : "Voice Call",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: SafeArea(
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: rtc.RTCVideoView(_localRenderer, mirror: true),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _callButton(
                    isMicEnabled ? Icons.mic : Icons.mic_off,
                    onPressed: _toggleMic,
                  ),
                  _callButton(
                    Icons.call_end,
                    color: Colors.red,
                    onPressed: _endCall,
                  ),
                  if (widget.isVideo)
                    _callButton(
                      isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                      onPressed: _toggleCamera,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _callButton(
    IconData icon, {
    Color color = Colors.white,
    required VoidCallback onPressed,
  }) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      radius: 28,
      child: IconButton(
        icon: Icon(icon, color: color, size: 28),
        onPressed: onPressed,
      ),
    );
  }
}
