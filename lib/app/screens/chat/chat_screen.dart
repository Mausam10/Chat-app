import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mime/mime.dart';

import '../../controllers/message_controller.dart';
import '../../widgets/emoji_input.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = Get.find<MessageController>();
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final scrollController = ScrollController();
  final storage = GetStorage();

  late String receiverId;
  late String receiverName;

  bool showEmojiPicker = false;
  Map<String, dynamic>? replyingTo;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args == null || args['userId'] == null || args['userName'] == null) {
      receiverId = storage.read<String>('chat_userId') ?? '';
      receiverName = storage.read<String>('chat_userName') ?? 'Unknown';
    } else {
      receiverId = args['userId'];
      receiverName = args['userName'];
      storage.write('chat_userId', receiverId);
      storage.write('chat_userName', receiverName);
    }

    if (receiverId.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/HomeScreen');
      });
      return;
    }

    messageController.startConversation(receiverId);
    messageController.markMessagesAsSeen(receiverId);
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    storage.remove('chat_userId');
    storage.remove('chat_userName');
    super.dispose();
  }

  void handleSend() {
    final text = textController.text.trim();
    if (text.isNotEmpty) {
      messageController.sendMessage(
        receiverId,
        text,
        replyToMessageId: replyingTo?['id'],
      );
      textController.clear();
      setState(() => replyingTo = null);
      focusNode.requestFocus();
      scrollToBottom();
    }
  }

  void handleReaction(String messageId, String emoji) {
    final msgIndex = messageController.chatMessages.indexWhere(
      (m) => m['id'] == messageId,
    );
    if (msgIndex != -1) {
      messageController.chatMessages[msgIndex]['reaction'] = emoji;
      messageController.chatMessages.refresh();
    }
  }

  void scrollToBottom({bool smooth = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final pos = scrollController.position.maxScrollExtent;
        if (smooth) {
          scrollController.animateTo(
            pos,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          scrollController.jumpTo(pos);
        }
      }
    });
  }

  Future<void> pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final base64File = base64Encode(file.bytes!);
      final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';

      messageController.sendMessage(
        receiverId,
        '',
        base64File: base64File,
        fileName: file.name,
        mimeType: mimeType,
      );

      scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = messageController.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName.isNotEmpty ? receiverName : 'Chat'),
        leading:
            Navigator.canPop(context)
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.offAllNamed('/HomeScreen'),
                ),
      ),
      body:
          receiverId.isEmpty
              ? const Center(child: Text('Invalid chat user.'))
              : Column(
                children: [
                  Obx(
                    () =>
                        messageController.isTyping.value
                            ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Typing...",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : const SizedBox(),
                  ),

                  if (replyingTo != null)
                    Container(
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const Icon(Icons.reply, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              replyingTo?['text'] ?? '',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => replyingTo = null),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: Obx(() {
                      final messages = messageController.chatMessages;

                      if (messageController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      scrollToBottom();

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['senderId'] == myId;

                          return GestureDetector(
                            onLongPress: () async {
                              final selected = await showMenu<String>(
                                context: context,
                                position: const RelativeRect.fromLTRB(
                                  100,
                                  300,
                                  100,
                                  100,
                                ),
                                items: const [
                                  PopupMenuItem(value: "❤️", child: Text("❤️")),
                                  PopupMenuItem(value: "😂", child: Text("😂")),
                                  PopupMenuItem(value: "👍", child: Text("👍")),
                                  PopupMenuItem(
                                    value: "reply",
                                    child: Text("Reply"),
                                  ),
                                ],
                              );

                              if (selected != null) {
                                if (selected == 'reply') {
                                  setState(() => replyingTo = msg);
                                } else {
                                  handleReaction(msg['id'], selected);
                                }
                              }
                            },
                            child: MessageBubble(msg: msg, isMe: isMe),
                          );
                        },
                      );
                    }),
                  ),

                  EmojiInput(
                    textController: textController,
                    focusNode: focusNode,
                    showEmojiPicker: showEmojiPicker,
                    onToggleEmojiPicker: () {
                      setState(() => showEmojiPicker = !showEmojiPicker);
                    },
                    onSend: handleSend,
                    onAttachFile: pickAndSendFile,
                  ),
                ],
              ),
    );
  }
}
