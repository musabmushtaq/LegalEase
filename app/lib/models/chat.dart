class Chat {
  final String id;
  final String userId;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  bool isShared;
  List<String> collaborators;

  Chat({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isShared = false,
    this.collaborators = const [],
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
      isShared: json['is_shared'] as bool? ?? false,
      collaborators: (json['collaborators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
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
      'is_shared': isShared,
      'collaborators': collaborators,
    };
  }
}

class ChatMessage {
  final String id;
  final String? chatId;
  final String sender; // 'user' or 'ai'
  final String content;
  final DateTime createdAt;
  bool isNew;
  final String? localFilePath;
  final String? fileId;
  final String? fileName;
  final String? userId;

  ChatMessage({
    required this.id,
    this.chatId,
    required this.sender,
    required this.content,
    required this.createdAt,
    this.isNew = false,
    this.localFilePath,
    this.fileId,
    this.fileName,
    this.userId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatId: json['chat_id'] as String?,
      sender: json['sender'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      localFilePath: json['local_file_path'] as String?,
      fileId: json['file_id'] as String?,
      fileName: json['filename'] as String?,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (chatId != null) 'chat_id': chatId,
      'sender': sender,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (fileId != null) 'file_id': fileId,
      if (fileName != null) 'filename': fileName,
      if (userId != null) 'user_id': userId,
    };
  }
}
