import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

class EmojiInput extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool showEmojiPicker;
  final VoidCallback onToggleEmojiPicker;
  final VoidCallback onSend;
  final VoidCallback onAttachFile;

  const EmojiInput({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.showEmojiPicker,
    required this.onToggleEmojiPicker,
    required this.onSend,
    required this.onAttachFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              onPressed: () {
                FocusScope.of(context).unfocus();
                onToggleEmojiPicker();
              },
            ),
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: onAttachFile,
            ),
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
                onTap: () {
                  if (showEmojiPicker) onToggleEmojiPicker();
                },
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: onSend),
          ],
        ),
        if (showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                textController.text += emoji.emoji;
              },
              config: Config(
                columns: 7,
                emojiSizeMax: 28,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                initCategory: Category.SMILEYS,
                bgColor: Colors.grey[200]!,
              ),
            ),
          ),
      ],
    );
  }
}
