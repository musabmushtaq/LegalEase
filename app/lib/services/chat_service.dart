import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chat.dart';

class ChatService extends ChangeNotifier {
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

  void createNewChat() {
    final chatId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentChatId = chatId;
    _chats[chatId] = Chat(
      id: chatId,
      userId: 'user1',
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _messages[chatId] = [];
    _saveChats();
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

  void togglePinChat(String chatId) {
    if (_chats[chatId] != null) {
      _chats[chatId]!.isPinned = !_chats[chatId]!.isPinned;
      _saveChats();
      notifyListeners();
    }
  }

  void renameChat(String chatId, String newTitle) {
    if (_chats[chatId] != null) {
      _chats[chatId]!.title = newTitle;
      _chats[chatId]!.updatedAt = DateTime.now();
      _saveChats();
      notifyListeners();
    }
  }

  void deleteChat(String chatId) {
    _chats.remove(chatId);
    _messages.remove(chatId);
    if (_currentChatId == chatId) {
      _currentChatId = null;
    }
    _saveChats();
    notifyListeners();
  }
}
