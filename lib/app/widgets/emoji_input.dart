import 'package:flutter/material.dart';

class EmojiInput extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiInput({Key? key, required this.onEmojiSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> emojis = [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🤯',
      '😳',
      '🥵',
      '🥶',
      '😱',
      '😨',
      '😰',
      '😥',
      '😓',
      '🤗',
      '🤔',
      '🤭',
      '🤫',
      '🤥',
      '😶',
      '😐',
      '😑',
      '😬',
      '🙄',
      '😯',
      '😦',
      '😧',
      '😮',
      '😲',
      '🥱',
      '😴',
      '🤤',
      '😪',
      '😵',
      '🤐',
      '🥴',
      '🤢',
      '🤮',
      '🤧',
      '😷',
      '🤒',
      '🤕',
      '🤑',
      '🤠',
      '😈',
      '👿',
      '👹',
      '👺',
      '🤡',
      '💩',
      '👻',
      '💀',
      '☠️',
      '👽',
      '👾',
      '🤖',
      '🎃',
      '😺',
      '😸',
      '😹',
      '😻',
      '😼',
      '😽',
      '🙀',
      '😿',
      '😾',
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '☮️',
      '✝️',
      '☪️',
      '🕉️',
      '☸️',
      '✡️',
      '🔯',
      '🕎',
      '☯️',
      '☦️',
      '🛐',
      '⛎',
      '♈',
      '♉',
      '♊',
      '♋',
      '♌',
      '♍',
      '♎',
      '♏',
      '♐',
      '♑',
      '♒',
      '♓',
      '🆔',
      '⚛️',
      '🉑',
      '☢️',
      '☣️',
      '📴',
      '📳',
      '🈶',
      '🈚',
      '🈸',
      '🈺',
      '🈷️',
      '✴️',
      '🆚',
      '💮',
      '🉐',
      '㊙️',
      '㊗️',
      '🈴',
      '🈵',
      '🈹',
      '🈲',
      '🅰️',
      '🅱️',
      '🆎',
      '🆑',
      '🅾️',
      '🆘',
      '❌',
      '⭕',
      '🛑',
      '⛔',
      '📛',
      '🚫',
      '💯',
      '💢',
      '♨️',
      '🚷',
      '🚯',
      '🚳',
      '🚱',
      '🔞',
      '📵',
      '🚭',
      '❗',
      '❕',
      '❓',
      '❔',
      '‼️',
      '⁉️',
      '🔅',
      '🔆',
      '〽️',
      '⚠️',
      '🚸',
      '🔱',
      '⚜️',
      '🔰',
      '♻️',
      '✅',
      '🈯',
      '💹',
      '❇️',
      '✳️',
      '❎',
      '🌐',
      '💠',
      'Ⓜ️',
      '🌀',
      '💤',
      '🏧',
      '🚾',
      '♿',
      '🅿️',
      '🈳',
      '🈂️',
      '🛂',
      '🛃',
      '🛄',
      '🛅',
      '🚹',
      '🚺',
      '🚼',
      '🚻',
      '🚮',
      '🎦',
      '📶',
      '🈁',
      '🔣',
      'ℹ️',
      '🔤',
      '🔡',
      '🔠',
      '🆖',
      '🆗',
      '🆙',
      '🆒',
      '🆕',
      '🆓',
      '0️⃣',
      '1️⃣',
      '2️⃣',
      '3️⃣',
      '4️⃣',
      '5️⃣',
      '6️⃣',
      '7️⃣',
      '8️⃣',
      '9️⃣',
      '🔟',
    ];

    return Container(
      color: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onEmojiSelected(emojis[index]),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: Center(
                child: Text(
                  emojis[index],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
