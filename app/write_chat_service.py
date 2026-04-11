import os

content = """import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat.dart';

class ChatService extends ChangeNotifier {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  String? _userId;
  String? _authToken;

  String? _currentChatId;
  final Map<String, Chat> _chats = {};
  final Map<String, List<ChatMessage>> _messages = {};

  bool _isConnected = true;
  Timer? _connectivityTimer;
  bool _isAuthenticated = false;

  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentChatId => _currentChatId;
  Chat? get currentChat => _currentChatId != null ? _chats[_currentChatId] : null;
  List<ChatMessage> get currentMessages =>
      _currentChatId != null ? _messages[_currentChatId] ?? [] : [];
  List<Chat> get allChats =>
      _chats.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<Chat> get displayedChats {
    final chatsWithMessages = _chats.values
        .where((c) => (_messages[c.id]?.isNotEmpty ?? false))
        .toList();
    chatsWithMessages.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));       
    return chatsWithMessages;
  }

  List<ChatMessage> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }

  Future<void> initialize() async {
    await _loadAuth();
    await _loadChats();
    if (_isAuthenticated) {
      await _syncFromApi();
    }
    _startConnectivityMonitoring();
  }

  Future<void> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _authToken = prefs.getString('authToken');
    _isAuthenticated = _userId != null && _authToken != null;
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  Future<bool> login(String username, String password) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/auth/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _userId = decoded['user_id'];
        _authToken = decoded['access_token'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _userId!);
        await prefs.setString('authToken', _authToken!);

        await _syncFromApi();
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> register({required String username, required String email, required String password, File? profilePic}) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/auth/register');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await login(username, password);
      }
    } catch (_) {}
    return false;
  }

  Future<void> logout() async {
    _userId = null;
    _authToken = null;
    _isAuthenticated = false;
    _currentChatId = null;
    _chats.clear();
    _messages.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('authToken');
    await prefs.remove('chatCache');

    notifyListeners();
  }

  void _startConnectivityMonitoring() {
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
    final prefs = await SharedPreferences.getInstance();
    final cacheBytes = prefs.getString('chatCache');
    if (cacheBytes != null) {
      try {
        final List<dynamic> items = jsonDecode(cacheBytes);
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
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _syncFromApi() async {
    if (_userId == null) return;
    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/chats');
      final response = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 6)); 

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;        
        final items = (decoded['items'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();

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

        await _saveChats();
        notifyListeners();
      }
    } catch (_) { }
  }

  Future<void> _saveChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var chatList = _chats.values.map((c) {
        var json = c.toJson();
        json['messages'] = _messages[c.id]?.map((m) => m.toJson()).toList() ?? [];
        return json;
      }).toList();
      await prefs.setString('chatCache', jsonEncode(chatList));
    } catch (_) {}
  }

  Future<void> createNewChat() async {
    if (_userId == null) return;
    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/chats');
      final response = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({'title': 'New Chat'}),
      ).timeout(const Duration(seconds: 6));

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
    } catch (_) { }

    final chatId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentChatId = chatId;
    _chats[chatId] = Chat(
      id: chatId,
      userId: _userId ?? 'unknown',
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
    _chats[_currentChatId]!.updatedAt = DateTime.now();
    _saveChats();

    notifyListeners();
  }

  Future<void> sendUserMessage(String content, {File? file}) async {
    if (_userId == null) return;
    if (_currentChatId == null) {
      await createNewChat();
    }
    if (_currentChatId == null) return;

    if (!_isConnected) {
      addMessage(content, 'user');
      addMessage('Service unavailable.', 'ai');
      return;
    }

    final currentId = _currentChatId!;
    addMessage(content + (file != null ? " [Attachment: ${file.path.split('/').last}]" : ""), 'user');        

    try {
      final uri = Uri.parse('$_apiBaseUrl/chats/$currentId/messages_with_file');
      
      var request = http.MultipartRequest('POST', uri);
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.fields['content'] = content;
      
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;      
        final assistantMessage = decoded['assistant_message'] as Map<String, dynamic>?;
        if (assistantMessage != null) {
          final aiMsg = ChatMessage.fromJson(assistantMessage);
          aiMsg.isNew = true;
          _messages[currentId]?.add(aiMsg);
          _chats[currentId]?.updatedAt = DateTime.now();
          await _saveChats();
          notifyListeners();
        }
        return;
      }
    } catch (_) { }

    addMessage('Backend unavailable.', 'ai');
  }

  Future<List<Chat>> searchChats(String query) async {
    if (_userId == null || query.isEmpty) return [];
    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/search?query=$query');
      final response = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body)['items'] ?? [];
        return items.map((i) => Chat.fromJson(i)).toList();
      }
    } catch (_) {}
    return [];
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
      await http.delete(uri, headers: _headers());
    } catch (_) {}
  }

  Future<void> togglePinChat(String chatId) async {
    if (_chats[chatId] != null) {
      _chats[chatId]!.isPinned = !_chats[chatId]!.isPinned;
      await _saveChats();
      notifyListeners();
    }
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    if (_chats[chatId] != null) {
      _chats[chatId]!.title = newTitle;
      await _saveChats();
      notifyListeners();
    }
  }
}
"""

with open(r'c:\repo\LegalEase\app\lib\services\chat_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
