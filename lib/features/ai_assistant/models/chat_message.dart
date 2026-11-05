enum MessageSender { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final bool isThinking;
  final String? disclaimer;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isThinking = false,
    this.disclaimer,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': sender.name,
      'content': text,
      'created_at': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    MessageSender s = MessageSender.assistant;
    final roleStr = map['role']?.toString().toLowerCase();
    if (roleStr == 'user') {
      s = MessageSender.user;
    } else if (roleStr == 'system') {
      s = MessageSender.system;
    }

    return ChatMessage(
      id: map['id']?.toString() ?? '',
      sender: s,
      text: map['content']?.toString() ?? '',
      timestamp: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      disclaimer: 'Educational suggestions only. Not guaranteed financial advice.',
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

