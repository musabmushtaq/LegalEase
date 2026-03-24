import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chat.dart';

class ChatService extends ChangeNotifier {
  static const String _userId = 'user1';
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  String? _currentChatId;
  final Map<String, Chat> _chats = {};
  final Map<String, List<ChatMessage>> _messages = {};
  late SharedPreferences _prefs;

  String? get currentChatId => _currentChatId;
  Chat? get currentChat =>
      _currentChatId != null ? _chats[_currentChatId] : null;
  List<ChatMessage> get currentMessages =>
      _currentChatId != null ? _messages[_currentChatId] ?? [] : [];
  List<Chat> get allChats =>
      _chats.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  // Get only chats that have messages
  List<Chat> get displayedChats {
    final chatsWithMessages = _chats.values
        .where((c) => (_messages[c.id]?.isNotEmpty ?? false))
        .toList();
    chatsWithMessages.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return chatsWithMessages;
  }

  // Get messages for a specific chat
  List<ChatMessage> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadChats();
    await _syncFromApi();
  }

  Future<void> _loadChats() async {
    final chatsJson = _prefs.getString('chats');
    if (chatsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(chatsJson);
        _chats.clear();
        _messages.clear();

        decoded.forEach((id, chatData) {
          final chat = Chat.fromJson(chatData);
          _chats[id] = chat;
          final messagesData = chatData['messages'] as List? ?? [];
          _messages[id] = messagesData
              .map((m) => ChatMessage.fromJson(m))
              .toList();
        });
      } catch (e) {
        // Silently fail if chats can't be loaded (first time or corrupted data)
      }
    }

    // If no chats exist, create a default one (but don't save it yet)
    if (_chats.isEmpty) {
      final defaultChatId = 'default_chat';
      _currentChatId = defaultChatId;
      _chats[defaultChatId] = Chat(
        id: defaultChatId,
        userId: 'user1',
        title: 'Chat',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _messages[defaultChatId] = [];
      // Don't save the empty default chat - only save when first message is added
    } else {
      // Set current chat to first one (most recent)
      final sortedChats = _chats.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (sortedChats.isNotEmpty) {
        _currentChatId = sortedChats.first.id;
      }
    }
    notifyListeners();
  }

  Future<void> _syncFromApi() async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/chats');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        return;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (decoded['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      _chats.clear();
      _messages.clear();

      for (final item in items) {
        final chat = Chat.fromJson(item);
        _chats[chat.id] = chat;

        final rawMessages = (item['messages'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _messages[chat.id] = rawMessages.map(ChatMessage.fromJson).toList();
      }

      if (_chats.isEmpty) {
        await createNewChat();
      } else {
        final sortedChats = _chats.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _currentChatId = sortedChats.first.id;
      }

      await _saveChats();
      notifyListeners();
    } catch (_) {
      // Keep local cache if API is unavailable.
    }
  }

  Future<void> _saveChats() async {
    final data = <String, dynamic>{};
    for (var entry in _chats.entries) {
      data[entry.key] = {
        ...entry.value.toJson(),
        'messages': _messages[entry.key]?.map((m) => m.toJson()).toList() ?? [],
      };
    }
    await _prefs.setString('chats', jsonEncode(data));
  }

  Future<void> createNewChat() async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/chats');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'title': 'New Chat'}),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final chatJson = jsonDecode(response.body) as Map<String, dynamic>;
        final chat = Chat.fromJson(chatJson);
        _currentChatId = chat.id;
        _chats[chat.id] = chat;
        _messages[chat.id] = [];
        await _saveChats();
        notifyListeners();
        return;
      }
    } catch (_) {
      // Fallback below.
    }

    final chatId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentChatId = chatId;
    _chats[chatId] = Chat(
      id: chatId,
      userId: _userId,
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _messages[chatId] = [];
    await _saveChats();
    notifyListeners();
  }

  void selectChat(String chatId) {
    _currentChatId = chatId;
    notifyListeners();
  }

  void addMessage(String content, String sender) {
    if (_currentChatId == null) return;

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = ChatMessage(
      id: messageId,
      chatId: _currentChatId!,
      sender: sender,
      content: content,
      createdAt: DateTime.now(),
    );

    _messages[_currentChatId]?.add(message);

    // Update chat timestamp
    _chats[_currentChatId]!.updatedAt = DateTime.now();
    _saveChats();

    notifyListeners();
  }

  Future<void> sendUserMessage(String content) async {
    if (_currentChatId == null) {
      await createNewChat();
    }

    if (_currentChatId == null) return;

    final currentId = _currentChatId!;
    addMessage(content, 'user');

    try {
      final uri = Uri.parse('$_apiBaseUrl/chats/$currentId/messages');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': _userId,
              'sender': 'user',
              'content': content,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final assistantMessage =
            decoded['assistant_message'] as Map<String, dynamic>?;
        if (assistantMessage != null) {
          final aiMsg = ChatMessage.fromJson(assistantMessage);
          aiMsg.isNew = true; // Enable animation for this AI response
          _messages[currentId]?.add(aiMsg);
          _chats[currentId]?.updatedAt = DateTime.now();
          await _saveChats();
          notifyListeners();
        }
        return;
      }
    } catch (_) {
      // Fall through to local fallback.
    }

    addMessage(
      'Backend unavailable. Start the local API server to get live responses.',
      'ai',
    );
  }

  Future<void> togglePinChat(String chatId) async {
    if (_chats[chatId] != null) {
      _chats[chatId]!.isPinned = !_chats[chatId]!.isPinned;
      await _saveChats();
      notifyListeners();

      try {
        final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
        await http.patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'is_pinned': _chats[chatId]!.isPinned}),
        );
      } catch (_) {
        // Keep local state if API call fails.
      }
    }
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    if (_chats[chatId] != null) {
      _chats[chatId]!.title = newTitle;
      _chats[chatId]!.updatedAt = DateTime.now();
      await _saveChats();
      notifyListeners();

      try {
        final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
        await http.patch(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'title': newTitle}),
        );
      } catch (_) {
        // Keep local state if API call fails.
      }
    }
  }

  Future<void> deleteChat(String chatId) async {
    _chats.remove(chatId);
    _messages.remove(chatId);
    if (_currentChatId == chatId) {
      _currentChatId = null;
    }
    await _saveChats();
    notifyListeners();

    try {
      final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
      await http.delete(uri);
    } catch (_) {
      // Keep local state if API call fails.
    }

    if (_currentChatId == null && _chats.isNotEmpty) {
      final sorted = _chats.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _currentChatId = sorted.first.id;
      notifyListeners();
    }
  }
}
