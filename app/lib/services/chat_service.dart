import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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

  // Connection monitoring
  bool _isConnected = true;
  Timer? _connectivityTimer;

  bool get isConnected => _isConnected;

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
    await _loadChats();
    await _syncFromApi();
    _startConnectivityMonitoring();
  }

  void _startConnectivityMonitoring() {
    // Check connectivity every 5 seconds
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));

      final wasConnected = _isConnected;
      _isConnected = response.statusCode == 200;

      if (wasConnected != _isConnected) {
        if (!_isConnected) _currentChatId = null;
        notifyListeners();
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _currentChatId = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    // Local storage of chats is disabled per user request
    _chats.clear();
    _messages.clear();

    // Always start fresh
    _currentChatId = null;
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
        _currentChatId = null;
      } else {
        _currentChatId = null;
      }

      await _saveChats();
      notifyListeners();
    } catch (_) {
      // Keep local cache if API is unavailable.
    }
  }

  Future<void> _saveChats() async {
    // Local saving disabled, intentionally empty
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

  void clearCurrentChat() {
    _currentChatId = null;
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

  Future<void> sendUserMessage(String content, {File? file}) async {
    if (_currentChatId == null) {
      await createNewChat();
    }

    if (_currentChatId == null) return;

    // Check if connected to server
    if (!_isConnected) {
      addMessage(content, 'user');
      addMessage(
        'Service unavailable. Please check your connection and try again.',
        'ai',
      );
      notifyListeners();
      return;
    }

    final currentId = _currentChatId!;
    addMessage(content + (file != null ? " [Attachment]" : ""), 'user');

    try {
      final uri = Uri.parse('$_apiBaseUrl/chats/$currentId/messages');
      // For now, if we had file upload we'd use http.MultipartRequest
      // Example implementation provided as text.
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': _userId,
              'sender': 'user',
              'content':
                  content +
                  (file != null
                      ? "\n\n*(Sent an attachment: ${file.path.split('/').last})*"
                      : ""),
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
