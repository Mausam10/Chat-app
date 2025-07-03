import 'package:chat_app/app/controllers/call_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallScreen extends StatelessWidget {
  final bool isVideoCall;
  final controller = Get.put(CallController());

  CallScreen({super.key, required this.isVideoCall});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isVideoCall ? "Video Call" : "Audio Call"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Obx(() {
        return Stack(
          children: [
            if (isVideoCall)
              Positioned.fill(child: RTCVideoView(controller.remoteRenderer)),
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 120,
                height: 160,
                margin: const EdgeInsets.all(16),
                child: RTCVideoView(controller.localRenderer, mirror: true),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IconButton(
                icon: const Icon(Icons.call_end, color: Colors.red, size: 40),
                onPressed: () {
                  controller.endCall();
                  Get.back();
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
