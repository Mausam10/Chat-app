import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final bool isGroupChat;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
    this.isGroupChat = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ✅ Group chat sender info
            if (isGroupChat && !isMe)
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: NetworkImage(
                      msg['senderProfilePic'] ?? '',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg['senderName'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            // ✅ Reply preview
            if (msg['replyTo'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  msg['replyToPreview'] ?? 'Replying to message...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isMe ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),

            // ✅ Image message
            if (msg['image'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    msg['image'],
                    width: 200,
                    errorBuilder:
                        (context, error, stack) =>
                            const Text('Image failed to load'),
                  ),
                ),
              ),

            // ✅ Text message
            if (msg['text'] != null && msg['text'].toString().isNotEmpty)
              Text(
                msg['text'],
                style: TextStyle(
                  color:
                      isMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSecondaryContainer,
                ),
              ),

            // ✅ Reaction emoji
            if (msg['reaction'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  msg['reaction'],
                  style: const TextStyle(fontSize: 18),
                ),
              ),

            // ✅ Timestamp and seen/sent icon
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg['timestamp']),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(width: 4),
                if (isMe)
                  Icon(
                    msg['seenBy']?.contains(msg['receiverId']) == true
                        ? Icons.done_all
                        : Icons.check,
                    size: 16,
                    color:
                        msg['seenBy']?.contains(msg['receiverId']) == true
                            ? Colors.lightBlueAccent
                            : Colors.grey,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime? dt;
    if (timestamp is String) {
      dt = DateTime.tryParse(timestamp);
    } else if (timestamp is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    if (dt == null) return '';
    return DateFormat('hh:mm a').format(dt);
  }
}
