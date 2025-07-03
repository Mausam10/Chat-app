import 'package:chat_app/app/controllers/call_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class CallScreen extends StatelessWidget {
  final String receiverId;
  final String receiverName;
  final bool isVideoCall;

  const CallScreen({
    Key? key,
    required this.receiverId,
    required this.receiverName,
    required this.isVideoCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CallController callController = Get.find<CallController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            callController.endCall();
            Get.back();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              receiverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Obx(
              () => Text(
                callController.connectionStatus.value,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Obx(() {
        final localRenderer = callController.localRenderer;
        final remoteRenderer = callController.remoteRenderer;

        return Stack(
          children: [
            // Remote video or background
            Positioned.fill(
              child:
                  isVideoCall
                      ? RTCVideoView(
                        remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      )
                      : Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.grey.shade800,
                                child: Text(
                                  receiverName.isNotEmpty
                                      ? receiverName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                receiverName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Obx(() {
                                final formatted =
                                    callController.getFormattedDuration();
                                return Text(formatted);
                              }),
                            ],
                          ),
                        ),
                      ),
            ),

            // Local video (picture-in-picture)
            if (isVideoCall)
              Positioned(
                top: 100,
                right: 16,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RTCVideoView(
                      localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // Call duration overlay
            if (!isVideoCall)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Obx(() {
                    final _ =
                        callController
                            .callDuration
                            .value; // force reactive read
                    return Text(callController.getFormattedDuration());
                  }),
                ),
              ),

            // Controls
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Toggle microphone
                  Obx(() {
                    final isMuted = callController.isMuted.value;
                    return Container(
                      decoration: BoxDecoration(
                        color:
                            isMuted
                                ? Colors.red
                                : Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 32,
                        icon: Icon(
                          isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                        onPressed: () => callController.toggleMute(),
                      ),
                    );
                  }),

                  // End call button
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      onPressed: () {
                        callController.endCall();
                        Get.back();
                      },
                    ),
                  ),

                  // Toggle camera (only for video calls)
                  if (isVideoCall)
                    Obx(() {
                      final isVideoEnabled =
                          callController.isVideoEnabled.value;
                      return Container(
                        decoration: BoxDecoration(
                          color:
                              !isVideoEnabled
                                  ? Colors.red
                                  : Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          iconSize: 32,
                          icon: Icon(
                            isVideoEnabled
                                ? Icons.videocam
                                : Icons.videocam_off,
                            color: Colors.white,
                          ),
                          onPressed: () => callController.toggleVideo(),
                        ),
                      );
                    })
                  else
                    // Speaker toggle for voice calls
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.volume_up, color: Colors.white),
                        onPressed: () {
                          // TODO: Implement speaker toggle
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Additional controls for video calls
            if (isVideoCall)
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 24,
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                    ),
                    onPressed: () => callController.switchCamera(),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
