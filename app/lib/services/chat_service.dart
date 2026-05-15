import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/chat.dart';

class ChatService extends ChangeNotifier {
  static String _apiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get apiBaseUrl => _apiBaseUrl;

  String? _userId;
  String? _authToken;

  String? _currentChatId;
  final Map<String, Chat> _chats = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Set<String> _generatingTitles = {}; // Track chats generating titles

  bool _isConnected = false;
  bool _isConnecting = true;
  Timer? _connectivityTimer;
  bool _isAuthenticated = false;
  bool _isTemporaryChat = false;
  int _consecutiveFailures = 0;

  StreamSubscription? _connectivitySubscription;
  bool _isRecovering = false;
  Timer? _recoveryTimer;
  ConnectivityResult? _lastConnectivityResult;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isAuthenticated => _isAuthenticated;
  bool get isTemporaryChat => _isTemporaryChat;
  String? get currentChatId => _currentChatId;
  Chat? get currentChat =>
      _currentChatId != null ? _chats[_currentChatId] : null;
  List<ChatMessage> get currentMessages =>
      _currentChatId != null ? _messages[_currentChatId] ?? [] : [];
  List<Chat> get allChats =>
      _chats.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  bool isTitleGenerating(String chatId) => _generatingTitles.contains(chatId);

  List<Chat> get displayedChats {
    // History list is strictly network-driven. 
    // If we are offline or not authenticated, we don't show the history.
    if (!_isConnected || !_isAuthenticated) return [];

    final chatsWithMessages = _chats.values
        .where((c) => (_messages[c.id]?.isNotEmpty ?? false))
        .toList();
    chatsWithMessages.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    // Don't show the current temporary chat in the history list
    if (_isTemporaryChat && _currentChatId != null) {
      chatsWithMessages.removeWhere((c) => c.id == _currentChatId);
    }
    return chatsWithMessages;
  }

  List<ChatMessage> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }

  Future<void> initialize() async {
    await _loadSettings();
    await _loadAuth();
    if (_isAuthenticated) {
      // Reactive check on startup - skip restoring from cache for fresh start
      checkInitialAndInstantNetwork();
    } else {
      _isConnecting = false;
      notifyListeners();
    }
    _listenToConnectivityChanges();
  }

  void _cleanupSessionTempChat() {
    if (_isTemporaryChat && _currentChatId != null) {
      final tempId = _currentChatId!;
      _chats.remove(tempId);
      _messages.remove(tempId);
      try {
        final uri = Uri.parse('$_apiBaseUrl/chats/$tempId');
        http.delete(uri, headers: _headers());
      } catch (_) {}
    }
  }

  void toggleTemporaryChat() {
    if (_isTemporaryChat) {
      // Exiting temporary mode, clean up the temp chat
      _cleanupSessionTempChat();
      _currentChatId = null;
    }
    _isTemporaryChat = !_isTemporaryChat;
    if (_isTemporaryChat) {
      // Clear out the current selected chat so we just start a "temporary" session view.
      _currentChatId = null;
    }
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('apiBaseUrl');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _apiBaseUrl = savedUrl;
    }
  }

  Future<void> updateApiBaseUrl(String newUrl) async {
    _apiBaseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiBaseUrl', newUrl);
    notifyListeners();
    // Re-check connectivity after updating the URL
    _checkConnectivity();
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
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

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

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    File? profilePic,
  }) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/auth/register');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

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
    await prefs.remove('currentChatCache');
    await prefs.remove('currentChatIdCache');

    notifyListeners();
  }

  void _listenToConnectivityChanges() {
    try {
      final connectivity = Connectivity();
      _connectivitySubscription = connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          if (results.isEmpty) return;
          final newResult = results.first;
          final wasOffline = _lastConnectivityResult == ConnectivityResult.none;
          final isNowOnline = newResult != ConnectivityResult.none;

          _lastConnectivityResult = newResult;

          // If we just came back online, sync from API
          if (wasOffline && isNowOnline) {
            _checkConnectivity();
          }
        },
        onError: (_) {
          // Gracefully handle missing platform implementation (e.g., in unit tests)
        },
      );
    } catch (_) {
      // Connectivity plugin not available (e.g., in unit tests) - fall back to polling only
    }
  }

  void _forceOfflineState() {
    if (_isConnected || _isConnecting) {
      _isConnected = false;
      _isConnecting = false;
      // Clear the volatile chat history when forcing offline
      _chats.clear();
      _messages.clear();
      // Restore the one cached chat so the user can still see their active conversation
      _restoreCurrentChatFromCache();
      notifyListeners();
      
      // Start aggressive recovery loop to detect when server is back
      _startRecoveryLoop();
    }
  }

  void _startRecoveryLoop() {
    if (_isRecovering) return;
    _isRecovering = true;
    
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isConnected) {
        timer.cancel();
        _isRecovering = false;
        return;
      }
      
      final online = await _checkConnectivityInternal();
      if (online) {
        timer.cancel();
        _isRecovering = false;
        _isConnected = true;
        _syncFromApi();
        notifyListeners();
      }
    });
  }

  Future<bool> _checkConnectivityInternal() async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/api/ping');
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkInitialAndInstantNetwork() async {
    _isConnecting = true;
    notifyListeners();
    
    final startTime = DateTime.now();
    try {
      final uri = Uri.parse('$_apiBaseUrl/api/ping');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      final isOnline = response.statusCode == 200;
      
      // Minimum visibility: Let the beautiful banner stay for at least 1.5s 
      // so it doesn't just "flicker" on fast networks.
      final elapsed = DateTime.now().difference(startTime);
      const minDuration = Duration(milliseconds: 1500);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      
      _isConnecting = false;
      if (!isOnline) {
        _forceOfflineState();
      } else {
        if (!_isConnected) {
          _isConnected = true;
          _consecutiveFailures = 0;
          await _syncFromApi();
        }
      }
      notifyListeners();
      return isOnline;
    } catch (_) {
      // For failures, we still wait for the full thorough check (e.g. 3-5s)
      final elapsed = DateTime.now().difference(startTime);
      const thoroughDuration = Duration(seconds: 3);
      if (elapsed < thoroughDuration) {
        await Future.delayed(thoroughDuration - elapsed);
      }
      
      _isConnecting = false;
      _forceOfflineState();
      notifyListeners();
      return false;
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final wasConnected = _isConnected;
      final uri = Uri.parse('$_apiBaseUrl/api/ping');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      final isNowConnected = response.statusCode == 200;

      if (isNowConnected) {
        _consecutiveFailures = 0;
        _isConnecting = false;

        if (!wasConnected) {
          _isConnected = true;
          await _syncFromApi();
          notifyListeners();
        }
      } else {
        // If server returns error, handle as disconnect
        if (_isConnecting || !_isConnected) {
          _isConnecting = false;
          _forceOfflineState();
          notifyListeners();
        }
      }
    } catch (e) {
      _consecutiveFailures++;
      // On startup or if already disconnected, be immediate.
      if (_consecutiveFailures >= 2 || !_isConnected || _isConnecting) {
        _isConnecting = false;
        _forceOfflineState();
        notifyListeners();
      }
    }
  }


  @override
  void dispose() {
    _recoveryTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Restore the current chat from cache for instant UI display
  /// This is lightweight - only loads the active conversation, not all chats
  Future<void> _restoreCurrentChatFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final chatCacheJson = prefs.getString('currentChatCache');
    final currentChatId = prefs.getString('currentChatIdCache');

    if (chatCacheJson != null && currentChatId != null) {
      try {
        final chatJson = jsonDecode(chatCacheJson) as Map<String, dynamic>;
        final chat = Chat.fromJson(chatJson);
        _currentChatId = currentChatId;
        _chats[chat.id] = chat;

        final rawMessages = (chatJson['messages'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _messages[chat.id] = rawMessages.map(ChatMessage.fromJson).toList();

        notifyListeners();
      } catch (_) {}
    }
  }

  /// Sync chats from backend API
  /// Only caches the current chat to shared preferences for speed
  Future<void> _syncFromApi() async {
    if (_userId == null) return;

    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/chats');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (decoded['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

        // Clear everything first - history is network driven
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

        // Only cache the current chat to shared preferences for instant load next time
        if (_currentChatId != null && _chats.containsKey(_currentChatId)) {
          await _saveCurrentChatToCache();
        }
        _isConnected = true; // Confirm we are online
        _isConnecting = false;
        notifyListeners();
      } else {
        // If server returns error, we handle it as a disconnect for the history list
        _isConnecting = false;
        _forceOfflineState();
      }
    } catch (_) {
      _isConnecting = false;
      _forceOfflineState();
    }
  }

  /// Save only the current chat to cache for fast UI restoration
  /// Shared preferences is temporary storage layer, not a database
  Future<void> _saveCurrentChatToCache() async {
    if (_currentChatId == null || !_chats.containsKey(_currentChatId)) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentChat = _chats[_currentChatId]!;
      var json = currentChat.toJson();
      json['messages'] =
          _messages[_currentChatId]?.map((m) => m.toJson()).toList() ?? [];

      await prefs.setString('currentChatCache', jsonEncode(json));
      await prefs.setString('currentChatIdCache', _currentChatId!);
    } catch (_) {}
  }

  Future<void> createNewChat() async {
    if (_userId == null && !_isTemporaryChat) return;

    final actualUserId = _userId ?? 'temp_user';

    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline && !_isTemporaryChat) {
      return;
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$actualUserId/chats');
      final response = await http
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({'title': 'New Chat'}),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final chatJson = jsonDecode(response.body) as Map<String, dynamic>;
        final chat = Chat.fromJson(chatJson);
        _currentChatId = chat.id;
        _chats[chat.id] = chat;
        _messages[chat.id] = [];
        await _saveCurrentChatToCache();
        notifyListeners();
        return;
      }
    } catch (_) {}

    final chatId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentChatId = chatId;
    _chats[chatId] = Chat(
      id: chatId,
      userId: actualUserId,
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _messages[chatId] = [];
    await _saveCurrentChatToCache();
    notifyListeners();
  }

  void selectChat(String chatId) {
    if (_isTemporaryChat) {
      _cleanupSessionTempChat();
    }
    _currentChatId = chatId;
    _isTemporaryChat = false;
    // Cache the newly selected chat for fast restoration
    _saveCurrentChatToCache();
    notifyListeners();
  }

  void clearCurrentChat() {
    if (_isTemporaryChat) {
      _cleanupSessionTempChat();
    }
    _currentChatId = null;
    notifyListeners();
  }

  Future<void> addMessage(
    String content,
    String sender, {
    String? localFilePath,
  }) async {
    if (_currentChatId == null) return;

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = ChatMessage(
      id: messageId,
      chatId: _currentChatId!,
      sender: sender,
      content: content,
      createdAt: DateTime.now(),
      localFilePath: localFilePath,
    );

    _messages[_currentChatId]?.add(message);
    _chats[_currentChatId]!.updatedAt = DateTime.now();
    await _saveCurrentChatToCache();

    notifyListeners();
  }

  Future<void> sendUserMessage(String content, {File? file}) async {
    if (_userId == null && !_isTemporaryChat) return;

    if (_currentChatId == null) {
      await createNewChat();
    }
    if (_currentChatId == null) return;

    final currentId = _currentChatId!;
    
    // ADD MESSAGE INSTANTLY - DO NOT WAIT FOR NETWORK CHECK
    addMessage(
      content + (file != null ? " [Attachment: ${file.path.split('/').last}]" : ""),
      'user',
      localFilePath: file?.path,
    );
    // Mark the last message as new for entrance animation
    _messages[currentId]?.last.isNew = true;

    // Now perform network checks in the background
    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline && !_isTemporaryChat) {
      return;
    }

    final chat = _chats[currentId];
    final isFirstMessage = chat?.title == 'New Chat';

    // Simple local echo for temporary offline chat, or try backend for temporary online chat
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
        final assistantMessage =
            decoded['assistant_message'] as Map<String, dynamic>?;
        if (assistantMessage != null) {
          final aiMsg = ChatMessage.fromJson(assistantMessage);
          aiMsg.isNew = true;
          _messages[currentId]?.add(aiMsg);
          _chats[currentId]?.updatedAt = DateTime.now();
          await _saveCurrentChatToCache();
          notifyListeners();
        }

        // Auto-generate title from first message
        if (isFirstMessage) {
          // Show loading state while generating
          _generatingTitles.add(currentId);
          _chats[currentId]!.title = 'Generating...';
          notifyListeners();

          final summary = await summarizeText(content);
          if (summary != null && summary.isNotEmpty) {
            await renameChat(currentId, summary);
          }

          _generatingTitles.remove(currentId);
        }

        return;
      }
    } catch (_) {}

    if (_isTemporaryChat) {
      addMessage(
        'Backend unavailable or network error. Please ensure API is reachable.',
        'ai',
      );
    } else {
      // If actual request fails dynamically despite earlier ping, force offline state
      _forceOfflineState();
    }
  }

  Future<List<Chat>> searchChats(String query) async {
    if (_userId == null || query.isEmpty) return [];

    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline) {
      return [];
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/search?query=$query');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body)['items'] ?? [];
        return items.map((i) => Chat.fromJson(i)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> deleteChat(String chatId) async {
    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline) return;

    _chats.remove(chatId);
    _messages.remove(chatId);
    if (_currentChatId == chatId) {
      _currentChatId = null;
      // Clear cache when current chat is deleted
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentChatCache');
      await prefs.remove('currentChatIdCache');
    }
    notifyListeners();

    try {
      final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
      await http.delete(uri, headers: _headers());
    } catch (_) {}
  }

  Future<void> togglePinChat(String chatId) async {
    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline) return;

    if (_chats[chatId] != null) {
      _chats[chatId]!.isPinned = !_chats[chatId]!.isPinned;
      // Update cache if this is the current chat
      if (_currentChatId == chatId) {
        await _saveCurrentChatToCache();
      }
      notifyListeners();
    }
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline) return;

    if (_chats[chatId] != null) {
      _chats[chatId]!.title = newTitle;
      // Update cache if this is the current chat
      if (_currentChatId == chatId) {
        await _saveCurrentChatToCache();
      }
      notifyListeners();

      // Save title to backend database
      try {
        final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
        await http
            .patch(
              uri,
              headers: _headers(),
              body: jsonEncode({'title': newTitle}),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
    }
  }

  /// Trim summary to max 12 words for chat titles (more descriptive)
  String _limitSummaryWords(String summary, {int maxWords = 12}) {
    final words = summary.split(RegExp(r'\s+'));
    if (words.length <= maxWords) return summary;
    return words.take(maxWords).join(' ');
  }

  Future<String?> summarizeText(String text) async {
    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline) return null;

    try {
      final uri = Uri.parse('$_apiBaseUrl/api/summarize');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        String? summary = data['summary'] as String?;
        if (summary != null && summary.isNotEmpty) {
          // Ensure summary is max 12 words
          summary = _limitSummaryWords(summary, maxWords: 12);
        }
        return summary;
      }
    } catch (_) {}
    return null;
  }
}
