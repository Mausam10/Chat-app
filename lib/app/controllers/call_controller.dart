import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../services/socket_service.dart';

class CallController extends GetxController {
  // Observable variables
  var isInCall = false.obs;
  var isVideoCall = false.obs;
  var isMuted = false.obs;
  var isVideoEnabled = true.obs;
  var isConnected = false.obs;
  var callDuration = 0.obs;
  var connectionStatus = 'Connecting...'.obs;

  // Add missing observable variables for UI consistency
  var isMicEnabled = true.obs;
  var isCameraEnabled = true.obs;

  // WebRTC variables
  webrtc.RTCPeerConnection? _peerConnection;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;
  webrtc.RTCVideoRenderer localRenderer = webrtc.RTCVideoRenderer();
  webrtc.RTCVideoRenderer remoteRenderer = webrtc.RTCVideoRenderer();

  // Call variables
  String? currentCallId;
  String? remoteUserId;
  bool isInitiator = false;

  // Socket service
  final SocketService socketService = Get.find<SocketService>();

  // Timer for call duration
  Timer? _callTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeRenderers();
    _setupSocketListeners();
  }

  Future<void> _initializeRenderers() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    } catch (e) {
      print('Error initializing renderers: $e');
    }
  }

  void _setupSocketListeners() {
    final socket = socketService.socket;

    socket?.on('webrtc-offer', (data) => _handleOffer(data));
    socket?.on('webrtc-answer', (data) => _handleAnswer(data));
    socket?.on('webrtc-ice-candidate', (data) => _handleIceCandidate(data));
    socket?.on('call-ended', (_) => endCall());
  }

  /// Main method to start a call
  Future<void> startCall(String userId, bool videoCall) async {
    try {
      // Check permissions first
      if (!await _checkPermissions(videoCall)) {
        _showError('Permissions not granted');
        return;
      }

      // Set call state
      isInCall.value = true;
      isVideoCall.value = videoCall;
      remoteUserId = userId;
      isInitiator = true;
      connectionStatus.value = 'Connecting...';

      // Initialize WebRTC
      await _initializeWebRTC();

      // Get user media
      await _getUserMedia(videoCall);

      // Create offer
      await _createOffer();

      // Start call timer
      _startCallTimer();

      print('Call started successfully');
    } catch (e) {
      print('Error starting call: $e');
      _showError('Failed to start call: ${e.toString()}');
      endCall();
    }
  }

  /// Initialize WebRTC peer connection
  Future<void> _initializeWebRTC() async {
    final configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
          ],
        },
      ],
    };

    final constraints = {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    _peerConnection = await webrtc.createPeerConnection(
      configuration,
      constraints,
    );

    // Handle ICE candidates
    _peerConnection?.onIceCandidate = (webrtc.RTCIceCandidate candidate) {
      socketService.socket?.emit('webrtc-ice-candidate', {
        'to': remoteUserId,
        'candidate': candidate.toMap(),
      });
    };

    // Handle remote stream
    _peerConnection?.onAddStream = (webrtc.MediaStream stream) {
      _remoteStream = stream;
      remoteRenderer.srcObject = stream;
      connectionStatus.value = 'Connected';
      isConnected.value = true;
    };

    // Handle connection state changes
    _peerConnection?.onConnectionState = (webrtc.RTCPeerConnectionState state) {
      switch (state) {
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          connectionStatus.value = 'Connected';
          isConnected.value = true;
          break;
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          connectionStatus.value = 'Disconnected';
          isConnected.value = false;
          break;
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          connectionStatus.value = 'Connection failed';
          endCall();
          break;
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          connectionStatus.value = 'Connecting...';
          break;
        default:
          break;
      }
    };
  }

  /// Get user media (camera/microphone)
  Future<void> _getUserMedia(bool videoCall) async {
    final constraints = {
      'audio': true,
      'video':
          videoCall
              ? {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              }
              : false,
    };

    _localStream = await webrtc.navigator.mediaDevices.getUserMedia(
      constraints,
    );
    localRenderer.srcObject = _localStream;

    // Add stream to peer connection
    _peerConnection?.addStream(_localStream!);
  }

  /// Create WebRTC offer
  Future<void> _createOffer() async {
    webrtc.RTCSessionDescription description =
        await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(description);

    // Send offer through socket
    socketService.socket?.emit('webrtc-offer', {
      'to': remoteUserId,
      'offer': description.toMap(),
    });
  }

  /// Handle incoming WebRTC offer
  Future<void> _handleOffer(dynamic data) async {
    try {
      if (!isInCall.value) {
        // This is an incoming call, initialize everything
        isInCall.value = true;
        isVideoCall.value = data['offer']['type'] == 'video';
        remoteUserId = data['from'];
        isInitiator = false;

        await _initializeWebRTC();
        await _getUserMedia(isVideoCall.value);
        _startCallTimer();
      }

      // Set remote description
      webrtc.RTCSessionDescription description = webrtc.RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await _peerConnection!.setRemoteDescription(description);

      // Create answer
      webrtc.RTCSessionDescription answer =
          await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Send answer through socket
      socketService.socket?.emit('webrtc-answer', {
        'to': remoteUserId,
        'answer': answer.toMap(),
      });
    } catch (e) {
      print('Error handling offer: $e');
      endCall();
    }
  }

  /// Handle WebRTC answer
  Future<void> _handleAnswer(dynamic data) async {
    try {
      webrtc.RTCSessionDescription description = webrtc.RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _peerConnection!.setRemoteDescription(description);
    } catch (e) {
      print('Error handling answer: $e');
      endCall();
    }
  }

  /// Handle ICE candidate
  Future<void> _handleIceCandidate(dynamic data) async {
    try {
      webrtc.RTCIceCandidate candidate = webrtc.RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }

  /// Check required permissions
  Future<bool> _checkPermissions(bool videoCall) async {
    Map<Permission, PermissionStatus> permissions =
        await [
          Permission.microphone,
          if (videoCall) Permission.camera,
        ].request();

    return permissions.values.every((status) => status.isGranted);
  }

  /// Start call timer
  void _startCallTimer() {
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      callDuration.value++;
    });
  }

  /// Toggle mute - Fixed method name and logic
  void toggleMute() {
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = isMuted.value; // Enable when currently muted
      });
      isMuted.value = !isMuted.value;
      isMicEnabled.value = !isMuted.value; // Update mic enabled state
    }
  }

  /// Add missing toggleMic method for UI consistency
  void toggleMic() {
    toggleMute();
  }

  /// Toggle video - Fixed method name and logic
  void toggleVideo() {
    if (_localStream != null && isVideoCall.value) {
      _localStream!.getVideoTracks().forEach((track) {
        track.enabled = !isVideoEnabled.value;
      });
      isVideoEnabled.value = !isVideoEnabled.value;
      isCameraEnabled.value =
          isVideoEnabled.value; // Update camera enabled state
    }
  }

  /// Add missing toggleCamera method for UI consistency
  void toggleCamera() {
    toggleVideo();
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_localStream != null && isVideoCall.value) {
      final videoTrack = _localStream!.getVideoTracks().first;
      await webrtc.Helper.switchCamera(videoTrack);
    }
  }

  /// End call
  void endCall() {
    try {
      // Stop call timer
      _callTimer?.cancel();
      _callTimer = null;

      // Close peer connection
      _peerConnection?.close();
      _peerConnection = null;

      // Stop local stream
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _localStream = null;

      // Stop remote stream
      _remoteStream?.dispose();
      _remoteStream = null;

      // Clear renderers
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;

      // Notify other user
      if (remoteUserId != null) {
        socketService.socket?.emit('call-ended', {'to': remoteUserId});
      }

      // Reset state
      isInCall.value = false;
      isVideoCall.value = false;
      isMuted.value = false;
      isVideoEnabled.value = true;
      isMicEnabled.value = true;
      isCameraEnabled.value = true;
      isConnected.value = false;
      callDuration.value = 0;
      connectionStatus.value = 'Disconnected';
      currentCallId = null;
      remoteUserId = null;
      isInitiator = false;

      print('Call ended successfully');
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  /// Get formatted call duration
  String getFormattedDuration() {
    final duration = callDuration.value;
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Show error message
  void _showError(String message) {
    Get.snackbar(
      'Call Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  @override
  void onClose() {
    endCall();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.onClose();
  }
}
