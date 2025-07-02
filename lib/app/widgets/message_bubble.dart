import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // For file links if needed
import 'package:video_player/video_player.dart'; // For video preview (optional)
import 'package:audioplayers/audioplayers.dart'; // For audio preview (optional)

class MessageBubble extends StatefulWidget {
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
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();

    // Init video controller if message has video file
    if (_isVideo(widget.msg)) {
      _videoController = VideoPlayerController.network(widget.msg['file'] ?? '')
        ..initialize().then((_) => setState(() {}));
    }

    // Init audio player if message has audio file
    if (_isAudio(widget.msg)) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onPlayerComplete.listen((_) {
        setState(() {
          _isPlayingAudio = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  bool _isVideo(Map<String, dynamic> msg) {
    final mime = (msg['mimeType'] ?? '').toString();
    return mime.startsWith('video/');
  }

  bool _isAudio(Map<String, dynamic> msg) {
    final mime = (msg['mimeType'] ?? '').toString();
    return mime.startsWith('audio/');
  }

  bool _isFile(Map<String, dynamic> msg) {
    return msg['file'] != null && !_isVideo(msg) && !_isAudio(msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = widget.isMe;
    final msg = widget.msg;
    final isGroupChat = widget.isGroupChat;

    final timestamp = _formatTime(msg['timestamp']);
    final textColor =
        isMe
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSecondaryContainer;

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
            // Group chat sender info
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

            // Reply preview
            if (msg['replyTo'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6, top: 6),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  msg['replyToPreview'] ??
                      msg['replyTo']['text'] ??
                      'Replying to message...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isMe ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),

            // Image message
            if (msg['image'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    msg['image'],
                    width: 200,
                    errorBuilder:
                        (context, error, stack) => const Text(
                          'Image failed to load',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                  ),
                ),
              ),

            // Video preview
            if (_isVideo(msg) &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 200,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                    IconButton(
                      iconSize: 40,
                      icon: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause_circle
                            : Icons.play_circle,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Audio preview with play/pause button
            if (_isAudio(msg) && _audioPlayer != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlayingAudio
                            ? Icons.pause_circle
                            : Icons.play_circle,
                      ),
                      iconSize: 32,
                      color: isMe ? Colors.white : Colors.black54,
                      onPressed: () async {
                        if (_isPlayingAudio) {
                          await _audioPlayer!.pause();
                          setState(() => _isPlayingAudio = false);
                        } else {
                          final url = msg['file'] ?? '';
                          if (url.isNotEmpty) {
                            await _audioPlayer!.play(UrlSource(url));
                            setState(() => _isPlayingAudio = true);
                          }
                        }
                      },
                    ),
                    Text(
                      msg['fileName'] ?? 'Audio file',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                  ],
                ),
              ),

            // Other file preview (PDF, DOCX, etc.)
            if (_isFile(msg))
              InkWell(
                onTap: () async {
                  final url = msg['file'] ?? '';
                  if (url.isNotEmpty && await canLaunch(url)) {
                    await launch(url);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        size: 24,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          msg['fileName'] ?? 'File',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Text message (if present and not empty)
            if (msg['text'] != null && msg['text'].toString().trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  msg['text'],
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
              ),

            // Reaction emoji
            if (msg['reaction'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  msg['reaction'],
                  style: const TextStyle(fontSize: 18),
                ),
              ),

            const SizedBox(height: 6),

            // Timestamp and status (including group "Seen by X")
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
                const SizedBox(width: 6),
                if (isMe)
                  Tooltip(
                    message: _getStatusTooltip(),
                    child: _buildMessageStatusIcon(),
                  ),

                // For group chats: show "Seen by X" summary if message seen by others
                if (isGroupChat && isMe)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        _seenBySummary(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.lightGreenAccent,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _seenBySummary() {
    final seenBy = widget.msg['seenBy'] as List<dynamic>? ?? [];
    final currentUserId = widget.msg['senderId'];

    // Remove self from seenBy list
    final othersSeenBy = seenBy.where((id) => id != currentUserId).toList();

    if (othersSeenBy.isEmpty) {
      return 'Seen by nobody yet';
    }

    // For simplicity, just show count
    return 'Seen by ${othersSeenBy.length} user${othersSeenBy.length > 1 ? 's' : ''}';
  }

  Icon _buildMessageStatusIcon() {
    final seenBy = widget.msg['seenBy'] as List<dynamic>? ?? [];
    final deliveredTo = widget.msg['deliveredTo'] as List<dynamic>? ?? [];
    final receiverId = widget.msg['receiverId'];

    if (seenBy.contains(receiverId)) {
      return const Icon(
        Icons.done_all,
        size: 16,
        color: Colors.lightBlueAccent,
      );
    } else if (deliveredTo.contains(receiverId)) {
      return const Icon(Icons.done_all, size: 16, color: Colors.grey);
    } else {
      return const Icon(Icons.check, size: 16, color: Colors.grey);
    }
  }

  String _getStatusTooltip() {
    final seenBy = widget.msg['seenBy'] as List<dynamic>? ?? [];
    final deliveredTo = widget.msg['deliveredTo'] as List<dynamic>? ?? [];
    final receiverId = widget.msg['receiverId'];

    if (seenBy.contains(receiverId)) {
      return 'Seen';
    } else if (deliveredTo.contains(receiverId)) {
      return 'Delivered';
    } else {
      return 'Sent';
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime? dt;

    if (timestamp is String) {
      dt = DateTime.tryParse(timestamp);
    } else if (timestamp is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return dt != null ? DateFormat('hh:mm a').format(dt) : '';
  }
}
