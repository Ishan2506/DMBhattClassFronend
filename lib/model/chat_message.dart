// enum MessageType { user, ai }

// class ChatMessage {
//   final String text;
//   final MessageType type;

//   ChatMessage({required this.text, required this.type});

//   factory ChatMessage.user(String text) =>
//       ChatMessage(text: text, type: MessageType.user);

//   factory ChatMessage.ai(String text) =>
//       ChatMessage(text: text, type: MessageType.ai);
// }

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? options;
  final List<Map<String, String>>? videos; // List of {title, url, thumbnail}
  final Map<String, String>? contact; // {name, number}

  ChatMessage({
    required this.text,
    required this.isUser,
    this.options,
    this.videos,
    this.contact,
  });
}
