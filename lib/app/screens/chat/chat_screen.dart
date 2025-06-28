import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controllers/message_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = Get.find<MessageController>();
  final textController = TextEditingController();
  final storage = GetStorage();

  late String receiverId;
  late String receiverName;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;

    if (args == null || args['userId'] == null || args['userName'] == null) {
      // debugPrint('ChatScreen opened without valid arguments.');

      // Fallback to stored values if available
      receiverId = storage.read<String>('chat_userId') ?? '';
      receiverName = storage.read<String>('chat_userName') ?? 'Unknown';
    } else {
      receiverId = args['userId'];
      receiverName = args['userName'];

      // Save to storage for reload fallback
      storage.write('chat_userId', receiverId);
      storage.write('chat_userName', receiverName);
    }

    if (receiverId.isNotEmpty) {
      messageController.fetchMessages(receiverId);
    }
  }

  @override
  void dispose() {
    // Clear stored chat info when leaving chat screen
    storage.remove('chat_userId');
    storage.remove('chat_userName');
    textController.dispose();
    super.dispose();
  }

  void handleSend() {
    final text = textController.text.trim();
    if (text.isNotEmpty) {
      messageController.sendMessage(receiverId, text);
      textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = messageController.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName.isNotEmpty ? receiverName : 'Chat'),
      ),
      body:
          receiverId.isEmpty
              ? const Center(
                child: Text('Invalid chat user or missing arguments.'),
              )
              : Column(
                children: [
                  Expanded(
                    child: Obx(() {
                      if (messageController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = messageController.chatMessages;

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg =
                              messages[messages.length - 1 - index]; // reverse
                          final isMe = msg['senderId'] == myId;

                          return Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    isMe
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  if (msg['image'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        msg['image'],
                                        width: 200,
                                        errorBuilder:
                                            (context, error, stack) =>
                                                const Text('Image load failed'),
                                      ),
                                    ),
                                  if (msg['text'] != null &&
                                      msg['text'].toString().isNotEmpty)
                                    Text(
                                      msg['text'],
                                      style: TextStyle(
                                        color:
                                            isMe ? Colors.white : Colors.black,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: handleSend,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
