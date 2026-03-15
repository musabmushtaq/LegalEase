class Chat {
  final String id;
  final String userId;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;

  Chat({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  // Data mapping representing exactly how it looks in PostgreSQL
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned,
    };
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String sender; // 'user' or 'ai'
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender': sender,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
