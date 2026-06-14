import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat.dart';

class ChatService extends ChangeNotifier {
  static String _apiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get apiBaseUrl => _apiBaseUrl;

  String? _userId;
  String? _authToken;
  String? _username;

  String? _currentChatId;
  final Map<String, Chat> _chats = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Set<String> _generatingTitles = {}; // Track chats generating titles
  final Map<String, String> _usernamesCache = {}; // Cache resolved usernames

  WebSocketChannel? _webSocketChannel;
  StreamSubscription? _webSocketSubscription;
  String? _webSocketConnectedChatId;

  WebSocketChannel? _userWebSocketChannel;
  StreamSubscription? _userWebSocketSubscription;
  bool _isUserWebSocketConnected = false;

  bool _isConnected = false;
  bool _isConnecting = true;
  Timer? _connectivityTimer;
  bool _isAuthenticated = false;
  bool _isTemporaryChat = false;
  bool _isInitialStartup = true;
  int _consecutiveFailures = 0;
  bool _showAccessRevokedPill = false;
  bool get showAccessRevokedPill => _showAccessRevokedPill;

  StreamSubscription? _connectivitySubscription;
  bool _isRecovering = false;
  Timer? _recoveryTimer;
  ConnectivityResult? _lastConnectivityResult;

  String _searchQuery = '';
  List<Chat>? _searchResults;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  String? get userId => _userId;
  bool get isTemporaryChat => _isTemporaryChat;
  String? get currentChatId => _currentChatId;
  String get searchQuery => _searchQuery;
  List<Chat>? get searchResults => _searchResults;
  Chat? get currentChat =>
      _currentChatId != null ? _chats[_currentChatId] : null;
  List<ChatMessage> get currentMessages =>
      _currentChatId != null ? _messages[_currentChatId] ?? [] : [];
  List<Chat> get allChats =>
      _chats.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  bool isTitleGenerating(String chatId) => _generatingTitles.contains(chatId);

  List<Chat> get displayedChats {
    if (_searchQuery.isNotEmpty) {
      return _searchResults ?? [];
    }

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
      _updateWebSocketConnection();
      _updateUserWebSocketConnection();
      // Start network check on startup - skip restoring from cache for fresh start
      checkInitialAndInstantNetwork().then((_) {
        _isInitialStartup = false;
      });
    } else {
      _isConnecting = false;
      _isInitialStartup = false;
      notifyListeners();
    }
    _listenToConnectivityChanges();
  }

  void _cleanupSessionTempChat() {
    if (_isTemporaryChat && _currentChatId != null) {
      final tempId = _currentChatId!;
      _chats.remove(tempId);
      _messages.remove(tempId);
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
    _updateWebSocketConnection();
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
    _username = prefs.getString('username');
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
        _username = username;
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _userId!);
        await prefs.setString('authToken', _authToken!);
        await prefs.setString('username', _username!);

        await _syncFromApi();
        _updateUserWebSocketConnection();
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
    _username = null;
    _isAuthenticated = false;
    _currentChatId = null;
    _chats.clear();
    _messages.clear();
    _disconnectWebSocket();
    _disconnectUserWebSocket();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('authToken');
    await prefs.remove('username');
    await prefs.remove('currentChatCache');
    await prefs.remove('currentChatIdCache');

    notifyListeners();
  }

  Future<bool> clearPersonalContext() async {
    if (_userId == null) return false;
    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline) return false;

    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/context');
      final response = await http.patch(
        uri,
        headers: _headers(),
        body: jsonEncode({'context': ''}),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('ChatService: Error clearing personal context: $e');
    }
    return false;
  }

  Future<bool> clearAllChatHistory() async {
    if (_userId == null) return false;
    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline) return false;

    // 1. Optimistic Local Clear
    _chats.clear();
    _messages.clear();
    _currentChatId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentChatCache');
      await prefs.remove('currentChatIdCache');
    } catch (_) {}
    notifyListeners();

    // 2. Direct server call to clear all chats natively in MongoDB!
    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/chats');
      final response = await http.delete(uri, headers: _headers()).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('ChatService: Error clearing chats natively on backend: $e');
    }
    return false;
  }

  Future<bool> deleteAccount() async {
    if (_userId == null) return false;
    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline) return false;

    try {
      // Direct server call to delete the entire user profile & all their chats!
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId');
      final response = await http.delete(uri, headers: _headers()).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Clear local auth session and memory
        await logout();
        return true;
      }
    } catch (e) {
      debugPrint('ChatService: Error deleting account natively on backend: $e');
    }
    return false;
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
      if (!_isInitialStartup) {
        _restoreCurrentChatFromCache();
      }
      _updateWebSocketConnection();
      _updateUserWebSocketConnection();
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
    
    try {
      final uri = Uri.parse('$_apiBaseUrl/api/ping');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      final isOnline = response.statusCode == 200;
      
      _isConnecting = false;
      if (!isOnline) {
        _forceOfflineState();
      } else {
        _isConnected = true;
        _consecutiveFailures = 0;
        await _syncFromApi();
      }
      notifyListeners();
      return isOnline;
    } catch (_) {
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
    _disconnectUserWebSocket();
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

  Future<void> syncChats() async {
    await _syncFromApi();
  }

  /// Sync chats from backend API
  /// Only caches the current chat to shared preferences for speed
  Future<void> _syncFromApi() async {
    if (_userId == null) return;

    try {
      // 1. Verify that the user profile still exists in the database
      final userUri = Uri.parse('$_apiBaseUrl/users/$_userId');
      final userResponse = await http
          .get(userUri, headers: _headers())
          .timeout(const Duration(seconds: 4));

      if (userResponse.statusCode == 404 || userResponse.statusCode == 401 || userResponse.statusCode == 403) {
        debugPrint('ChatService: Cached user profile not found or unauthorized. Forcing logout.');
        await logout();
        return;
      }

      // 2. Fetch user's chats
      final uri = Uri.parse('$_apiBaseUrl/users/$_userId/chats');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (decoded['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

        // Incrementally update: only remove local records that are no longer on the server
        final serverChatIds = items.map((item) => item['id'] as String).toSet();
        _chats.removeWhere((key, value) => !serverChatIds.contains(key));
        _messages.removeWhere((key, value) => !serverChatIds.contains(key));

        for (final item in items) {
          final chat = Chat.fromJson(item);
          _chats[chat.id] = chat;

          final rawMessages = (item['messages'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();
          final parsedMessages = rawMessages.map(ChatMessage.fromJson).toList();

          if (chat.id == _currentChatId) {
            // Keep local/in-flight messages for the active conversation, merging missing ones
            final currentList = _messages[chat.id] ?? [];
            for (final incoming in parsedMessages) {
              final exists = currentList.any((m) => m.id == incoming.id);
              if (!exists) {
                // Match temporary local user message by content and sender
                final tempIndex = currentList.indexWhere((m) =>
                    m.sender == incoming.sender &&
                    m.content == incoming.content &&
                    !m.id.startsWith('msg_'));
                if (tempIndex != -1) {
                  currentList[tempIndex] = incoming;
                } else {
                  currentList.add(incoming);
                }
              }
            }
            currentList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            _messages[chat.id] = currentList;
          } else {
            _messages[chat.id] = parsedMessages;
          }
        }

        // Only cache the current chat to shared preferences for instant load next time
        if (_currentChatId != null && !_isTemporaryChat) {
          final hasAccess = _chats.containsKey(_currentChatId);
          debugPrint('ChatService: Checking if current chat ID $_currentChatId is still in user\'s chats list: $hasAccess');
          if (hasAccess) {
            await _saveCurrentChatToCache();
          } else {
            // Lost access/removed from this chat
            debugPrint('ChatService: Current chat $_currentChatId is no longer in user\'s chats list! Revoking access.');
            _currentChatId = null;
            _disconnectWebSocket();
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('currentChatCache');
            await prefs.remove('currentChatIdCache');
            _showAccessRevokedPill = true;
            notifyListeners();
            Timer(const Duration(seconds: 3), () {
              _showAccessRevokedPill = false;
              notifyListeners();
            });
          }
        }
        _updateWebSocketConnection();
        _updateUserWebSocketConnection();
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

    if (_isTemporaryChat) {
      _cleanupSessionTempChat();
    }

    if (!_isTemporaryChat) {
      final isOnline = await checkInitialAndInstantNetwork();
      if (isOnline) {
        try {
          final uri = Uri.parse('$_apiBaseUrl/users/$_userId/chats');
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
            _updateWebSocketConnection();
            notifyListeners();
            return;
          }
        } catch (_) {}
      }
    }

    final chatId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentChatId = chatId;
    _chats[chatId] = Chat(
      id: chatId,
      userId: _userId ?? 'temp_user',
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _messages[chatId] = [];
    await _saveCurrentChatToCache();
    _updateWebSocketConnection();
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
    _updateWebSocketConnection();
    notifyListeners();
  }

  void clearCurrentChat() {
    if (_isTemporaryChat) {
      _cleanupSessionTempChat();
    }
    _currentChatId = null;
    _updateWebSocketConnection();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('currentChatCache');
      prefs.remove('currentChatIdCache');
    }).catchError((_) {});
    notifyListeners();
  }

  /// Specialized method for Live Call to save interactions
  /// without triggering the standard automated AI response loop.
  Future<String?> recordLiveCallInteraction({
    required String userText,
    String? chatId,
    bool skipAiResponse = false,
  }) async {
    // 1. Resolve which chat we are working with
    String? finalChatId = chatId ?? _currentChatId;
    
    // 2. If no chat exists, create a new one first
    if (finalChatId == null) {
      await createNewChat();
      finalChatId = _currentChatId;
    }
    
    if (finalChatId == null) return null;

    // 3. Add User message locally
    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    final userMsg = ChatMessage(
      id: userMsgId,
      chatId: finalChatId,
      sender: 'user',
      content: userText,
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(finalChatId, () => []);
    _messages[finalChatId]!.add(userMsg);
    notifyListeners();

    // 4. Background sync User message to server if online and NOT temporary
    if (!_isTemporaryChat) {
      _syncMessageToServer(finalChatId, userText, 'user');
    }

    // 5. If we only want to record the user (e.g. because of an interruption), stop here
    if (skipAiResponse) {
      debugPrint('ChatService: Skipping AI response for interrupted user thought.');
      // Still trigger auto-rename if this was the first message
      if (_chats[finalChatId]?.title == 'New Chat') {
        _generateTitleInBackground(finalChatId, userText);
      }
      return null;
    }

    // 6. Generate AI Response via specialized Live endpoint.
    // IMPORTANT: Always send the full in-memory message list directly, never just the chat_id.
    // Sending only chat_id causes a race condition: the user's latest message is still being
    // background-synced to the DB, so the server fetches stale history and Gemini never sees
    // what the user just said. The in-memory list is always up-to-date and correct.
    String? aiResponseText;
    try {
      final liveUri = Uri.parse('$_apiBaseUrl/api/generate_live');
      final body = {
        'messages': _messages[finalChatId]?.map((m) => {
          'sender': m.sender,
          'content': m.content,
        }).toList() ?? [],
      };

      final response = await http.post(
        liveUri,
        headers: _headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final assistantMsg = decoded['assistant_message'];
        if (assistantMsg != null) {
          aiResponseText = assistantMsg['content'];
        }
      }
    } catch (e) {
      debugPrint('ChatService: Error generating live response: $e');
    }

    // Fallback if AI generation fails
    final finalAiText = aiResponseText ?? "I'm sorry, I encountered an error processing your voice request.";

    // 7. Add AI message locally
    final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final aiMsg = ChatMessage(
      id: aiMsgId,
      chatId: finalChatId,
      sender: 'ai',
      content: finalAiText,
      createdAt: DateTime.now().add(const Duration(milliseconds: 100)),
    );
    _messages[finalChatId]!.add(aiMsg);
    
    // Update timestamp and cache
    if (_chats.containsKey(finalChatId)) {
      _chats[finalChatId]!.updatedAt = DateTime.now();
    }
    await _saveCurrentChatToCache();
    notifyListeners();

    // 8. Background sync AI message to server if online and NOT temporary (skip on error messages)
    if (!_isTemporaryChat && !finalAiText.startsWith('Error:') && !finalAiText.startsWith("I'm sorry, I encountered an error")) {
      _syncMessageToServer(finalChatId, finalAiText, 'ai');
    }

    // 9. Auto-generate title if this is the first interaction
    if (_chats[finalChatId]?.title == 'New Chat') {
      debugPrint('ChatService: Triggering auto-rename for $finalChatId');
      _generateTitleInBackground(finalChatId, userText);
    }

    debugPrint('ChatService: Live interaction complete. Returning AI text.');
    return finalAiText;
  }

  // Helper for background syncing to avoid blocking the voice flow
  void _syncMessageToServer(String chatId, String content, String sender) async {
    // Rely on the service's current connection status instead of doing a redundant, slow API ping,
    // which can easily time out and drop messages under high server loads (e.g. concurrent TTS/STT generation).
    if (!_isConnected) {
      debugPrint('ChatService: Background sync skipped - currently offline state');
      return;
    }

    try {
      debugPrint('ChatService: Syncing $sender message to $chatId...');
      final uri = Uri.parse('$_apiBaseUrl/chats/$chatId/messages');
      final response = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({'content': content, 'sender': sender, 'user_id': sender == 'user' ? _userId : null}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        debugPrint('ChatService: Successfully synced $sender message to server');
      } else {
        debugPrint('ChatService: Sync failed for $sender. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('ChatService: Background sync exception for $sender: $e');
      // If we got a connection error, trigger standard offline fallback
      _forceOfflineState();
    }
  }

  void _generateTitleInBackground(String chatId, String firstMessage) async {
    _generatingTitles.add(chatId);
    _chats[chatId]!.title = 'Generating...';
    notifyListeners();

    final summary = await summarizeText(firstMessage);
    if (summary != null && summary.isNotEmpty) {
      await renameChat(chatId, summary);
    }
    _generatingTitles.remove(chatId);
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
      userId: sender == 'user' ? _userId : null,
    );

    _messages[_currentChatId]?.add(message);
    if (_chats.containsKey(_currentChatId)) {
      _chats[_currentChatId]!.updatedAt = DateTime.now();
    }
    await _saveCurrentChatToCache();

    notifyListeners();
  }

  Future<void> sendUserMessage(String content, {File? file, bool useContext = false}) async {
    if (_userId == null && !_isTemporaryChat) return;

    if (_currentChatId == null || !_chats.containsKey(_currentChatId)) {
      await createNewChat();
    }
    if (_currentChatId == null || !_chats.containsKey(_currentChatId)) return;

    final currentId = _currentChatId!;
    
    // ADD MESSAGE INSTANTLY - DO NOT WAIT FOR NETWORK CHECK
    addMessage(
      content,
      'user',
      localFilePath: file?.path,
    );
    // Mark the last message as new for entrance animation
    _messages[currentId]?.last.isNew = true;

    // Now perform network checks
    final isOnline = await checkInitialAndInstantNetwork();
    if (!isOnline && !_isTemporaryChat) {
      return;
    }

    if (_isTemporaryChat) {
      if (!isOnline) {
        addMessage('Backend unavailable. AI response requires connection.', 'ai');
        return;
      }
    } else {
      // 1. Persistent Chat: Save User Message to DB first
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
          final msgData = decoded['message'] as Map<String, dynamic>?;
          if (msgData != null) {
            // Find our local message and update it with the persistent IDs
            final index = _messages[currentId]?.indexWhere((m) => m.content == content) ?? -1;
            if (index != -1) {
              final oldMsg = _messages[currentId]![index];
              _messages[currentId]![index] = ChatMessage(
                id: msgData['id'] as String? ?? oldMsg.id,
                chatId: oldMsg.chatId,
                sender: oldMsg.sender,
                content: oldMsg.content,
                createdAt: oldMsg.createdAt,
                localFilePath: oldMsg.localFilePath,
                fileId: msgData['file_id'] as String?,
                fileName: msgData['filename'] as String?,
                userId: msgData['user_id'] as String? ?? oldMsg.userId,
              );
            }
          }
        }

        if (response.statusCode == 403 || response.statusCode == 401) {
          debugPrint('ChatService: sendUserMessage returned ${response.statusCode}. Access revoked.');
          _currentChatId = null;
          _disconnectWebSocket();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('currentChatCache');
          await prefs.remove('currentChatIdCache');
          _showAccessRevokedPill = true;
          notifyListeners();
          Timer(const Duration(seconds: 3), () {
            _showAccessRevokedPill = false;
            notifyListeners();
          });
          return;
        }

        if (response.statusCode == 404) {
          // Server says chat doesn't exist - clear and retry once
          _currentChatId = null;
          _saveCurrentChatToCache();
          return sendUserMessage(content, file: file, useContext: useContext);
        }

        if (response.statusCode != 200) {
          _forceOfflineState();
          return;
        }
      } catch (_) {
        _forceOfflineState();
        return;
      }
    }

    final chat = _chats[currentId];
    final isFirstMessage = chat?.title == 'New Chat';

    // 2. Fetch AI Response using unified endpoint
    try {
      final aiUri = Uri.parse('$_apiBaseUrl/api/generate_ai');
      
      final Map<String, dynamic> body = {};
      body['use_context'] = useContext;
      if (!_isTemporaryChat) {
         // App asks AI to read context from DB
         body['chat_id'] = currentId;
      } else {
         // App provides context directly for temporary chat
         final history = _messages[currentId]?.map((m) => {
           'sender': m.sender,
           'content': m.content,
         }).toList() ?? [];
         body['messages'] = history;
         body['update_context'] = false;
      }

      final aiResponse = await http.post(
        aiUri, 
        headers: _headers(),
        body: jsonEncode(body),
      );
      
      if (aiResponse.statusCode == 200) {
        final decoded = jsonDecode(aiResponse.body) as Map<String, dynamic>;
        final assistantMessage = decoded['assistant_message'] as Map<String, dynamic>?;
        
        if (assistantMessage != null) {
          // Inject the currentId so the fromJson parser doesn't crash
          assistantMessage['chat_id'] = currentId;
          
          final aiMsg = ChatMessage.fromJson(assistantMessage);
          
          final currentList = _messages[currentId] ?? [];
          final exists = currentList.any((m) => m.id == aiMsg.id);
          if (!exists) {
            aiMsg.isNew = true;
            currentList.add(aiMsg);
            _chats[currentId]?.updatedAt = DateTime.now();
            await _saveCurrentChatToCache();
            notifyListeners();
          }

          // 3. Persistent Chat: App explicitly saves AI Message to DB (skip on API error pollution)
          if (!_isTemporaryChat && !aiMsg.content.startsWith('Error:')) {
             try {
               final saveAiUri = Uri.parse('$_apiBaseUrl/chats/$currentId/messages');
               await http.post(
                 saveAiUri,
                 headers: _headers(),
                 body: jsonEncode({
                   'content': aiMsg.content,
                   'sender': 'ai',
                   'user_id': null,
                 }),
               );
             } catch (_) {}
          }
        }
      } else {
        // Show error message locally in UI
        await addMessage('Error connecting to AI. Please try again.', 'ai');
      }

      // Auto-generate title from first message
      if (isFirstMessage && !_isTemporaryChat) {
        _generatingTitles.add(currentId);
        _chats[currentId]!.title = 'Generating...';
        notifyListeners();

        debugPrint('ChatService: First message in persistent chat. Summarizing content for title...');
        final summary = await summarizeText(content);
        debugPrint('ChatService: Summary result: $summary');
        
        if (summary != null && summary.isNotEmpty) {
          await renameChat(currentId, summary);
        } else {
          // Fallback if summarizer failed
          debugPrint('ChatService: Summary was empty or failed. Setting fallback title.');
          _chats[currentId]!.title = 'New Chat';
        }

        _generatingTitles.remove(currentId);
        notifyListeners();
        debugPrint('ChatService: Title generation complete for $currentId. UI notified.');
      }
    } catch (_) {
      // Always show error message locally in UI so we don't get stuck in thinking state
      await addMessage('Error connecting to AI. Please try again.', 'ai');
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

  Future<void> setSearchQuery(String query) async {
    final trimmed = query.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;

    if (_searchQuery.isEmpty) {
      _searchResults = null;
      notifyListeners();
      return;
    }

    // Purely online search
    final isOnline = await checkInitialAndInstantNetwork();
    if (isOnline && _userId != null) {
      try {
        final serverResults = await searchChats(_searchQuery);
        // Only apply if the query hasn't changed while we were waiting for the network
        if (_searchQuery == trimmed) {
          _searchResults = serverResults;
          notifyListeners();
        }
      } catch (_) {
        if (_searchQuery == trimmed) {
          _searchResults = [];
          notifyListeners();
        }
      }
    } else {
      if (_searchQuery == trimmed) {
        _searchResults = [];
        notifyListeners();
      }
    }
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
      _updateWebSocketConnection();
    }
    notifyListeners();

    try {
      final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
      await http.delete(uri, headers: _headers());
    } catch (_) {}
  }

  Future<void> togglePinChat(String chatId) async {
    debugPrint('ChatService: togglePinChat called for $chatId');
    if (_chats[chatId] != null) {
      final newPin = !_chats[chatId]!.isPinned;
      _chats[chatId]!.isPinned = newPin;
      // Update cache if this is the current chat
      if (_currentChatId == chatId) {
        await _saveCurrentChatToCache();
      }
      notifyListeners();

      // Sync pin state to backend database
      try {
        final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
        await http
            .patch(
              uri,
              headers: _headers(),
              body: jsonEncode({'is_pinned': newPin}),
            )
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('ChatService: Error syncing pin state: $e');
      }
    }
  }

  Future<void> toggleShareChat(String chatId, bool isShared) async {
    debugPrint('ChatService: toggleShareChat called for $chatId with value $isShared');
    if (_chats[chatId] != null) {
      _chats[chatId]!.isShared = isShared;
      if (!isShared) {
        _chats[chatId]!.collaborators = [];
      }
      // Update cache if this is the current chat
      if (_currentChatId == chatId) {
        await _saveCurrentChatToCache();
      }
      notifyListeners();

      // Sync share state to backend database
      try {
        final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
        await http
            .patch(
              uri,
              headers: _headers(),
              body: jsonEncode({'is_shared': isShared}),
            )
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('ChatService: Error syncing share state: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/users/$userId');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ChatService: Error fetching profile for $userId: $e');
    }
    return null;
  }

  Future<String?> getUsernameOf(String userId) async {
    if (_usernamesCache.containsKey(userId)) {
      return _usernamesCache[userId];
    }
    final profile = await getUserProfile(userId);
    if (profile != null) {
      final username = profile['username'] as String?;
      if (username != null) {
        _usernamesCache[userId] = username;
        return username;
      }
    }
    return null;
  }

  void _updateWebSocketConnection() {
    if (_currentChatId == null || _isTemporaryChat) {
      _disconnectWebSocket();
      return;
    }

    final httpUri = Uri.parse(_apiBaseUrl);
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    final wsUri = Uri(
      scheme: wsScheme,
      host: httpUri.host,
      port: httpUri.port,
      path: 'ws/chats/$_currentChatId',
    );

    if (_webSocketConnectedChatId == _currentChatId) {
      return;
    }

    _disconnectWebSocket();

    debugPrint('ChatService: Connecting to WebSocket at $wsUri');
    _webSocketConnectedChatId = _currentChatId;
    try {
      _webSocketChannel = WebSocketChannel.connect(wsUri);
      _webSocketSubscription = _webSocketChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('ChatService: WebSocket error: $error');
          _webSocketConnectedChatId = null;
        },
        onDone: () {
          debugPrint('ChatService: WebSocket connection closed');
          _webSocketConnectedChatId = null;
          if (_isConnected && _isAuthenticated && _currentChatId != null) {
            Timer(const Duration(seconds: 2), () {
              if (_isConnected && _isAuthenticated && _currentChatId != null) {
                _updateWebSocketConnection();
              }
            });
          }
        },
      );
    } catch (e) {
      debugPrint('ChatService: Failed to connect to WebSocket: $e');
      _webSocketConnectedChatId = null;
    }
  }

  void _disconnectWebSocket() {
    _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
    _webSocketConnectedChatId = null;
  }

  void _updateUserWebSocketConnection() {
    if (_userId == null || _isTemporaryChat || !_isConnected) {
      _disconnectUserWebSocket();
      return;
    }

    final httpUri = Uri.parse(_apiBaseUrl);
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    final wsUri = Uri(
      scheme: wsScheme,
      host: httpUri.host,
      port: httpUri.port,
      path: 'ws/users/$_userId',
    );

    if (_isUserWebSocketConnected) {
      return;
    }

    _disconnectUserWebSocket();

    debugPrint('ChatService: Connecting to User WebSocket at $wsUri');
    try {
      _userWebSocketChannel = WebSocketChannel.connect(wsUri);
      _isUserWebSocketConnected = true;
      _userWebSocketSubscription = _userWebSocketChannel!.stream.listen(
        (message) {
          _handleUserWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('ChatService: User WebSocket error: $error');
          _isUserWebSocketConnected = false;
        },
        onDone: () {
          debugPrint('ChatService: User WebSocket connection closed');
          _isUserWebSocketConnected = false;
          if (_isConnected && _isAuthenticated) {
            Timer(const Duration(seconds: 2), () {
              if (_isConnected && _isAuthenticated) {
                _updateUserWebSocketConnection();
              }
            });
          }
        },
      );
    } catch (e) {
      debugPrint('ChatService: Failed to connect to User WebSocket: $e');
      _isUserWebSocketConnected = false;
    }
  }

  void _disconnectUserWebSocket() {
    _userWebSocketSubscription?.cancel();
    _userWebSocketSubscription = null;
    _userWebSocketChannel?.sink.close();
    _userWebSocketChannel = null;
    _isUserWebSocketConnected = false;
  }

  void _handleUserWebSocketMessage(dynamic messageStr) {
    debugPrint('ChatService: User WebSocket message received: $messageStr');
    try {
      final data = jsonDecode(messageStr as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      debugPrint('ChatService: Parsed User WS message type: $type');
      if (type == 'chat_list_updated') {
        debugPrint('ChatService: Chat list updated event received on User WebSocket. Syncing...');
        _syncFromApi().catchError((e) {
          debugPrint('ChatService: Error syncing chats after User WS notification: $e');
        });
      }
    } catch (e) {
      debugPrint('ChatService: Error parsing User WebSocket message: $e');
    }
  }

  void _handleWebSocketMessage(dynamic messageStr) {
    debugPrint('ChatService: WebSocket message received: $messageStr');
    try {
      final data = jsonDecode(messageStr as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final chatId = data['chat_id'] as String?;
      final userIdInMsg = data['user_id'] as String?;
      debugPrint('ChatService: Parsed WS message - type: $type, chatId: $chatId, user_id: $userIdInMsg');
      
      if (type == 'new_message' && chatId == _currentChatId) {
        final messageData = data['message'] as Map<String, dynamic>?;
        if (messageData != null) {
          final incomingMsg = ChatMessage.fromJson(messageData);
          
          final currentList = _messages[_currentChatId] ?? [];
          final existsById = currentList.any((m) => m.id == incomingMsg.id);
          if (existsById) return;

          // Check if there is a matching message with same content and sender to replace/update
          final tempIndex = currentList.indexWhere((m) {
            if (m.sender != incomingMsg.sender || m.content != incomingMsg.content) {
              return false;
            }
            if (incomingMsg.sender == 'user') {
              // For user messages, only match if the local message is temporary (doesn't start with 'msg_')
              return !m.id.startsWith('msg_');
            } else {
              // For AI messages, match any message with same content (handles double-broadcast ID change)
              return true;
            }
          });

          if (tempIndex != -1) {
            currentList[tempIndex] = incomingMsg;
          } else {
            incomingMsg.isNew = true;
            currentList.add(incomingMsg);
          }
          
          if (_chats.containsKey(_currentChatId)) {
            _chats[_currentChatId]!.updatedAt = DateTime.now();
          }
          _saveCurrentChatToCache();
          notifyListeners();
        }
      } else if (type == 'collaborator_removed' && userIdInMsg == _userId) {
        debugPrint('ChatService: You were removed from this collaborative chat.');
        _currentChatId = null;
        _disconnectWebSocket();
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove('currentChatCache');
          prefs.remove('currentChatIdCache');
        }).catchError((_) {});
        
        _syncFromApi().catchError((_) {});
        
        _showAccessRevokedPill = true;
        notifyListeners();
        
        Timer(const Duration(seconds: 3), () {
          _showAccessRevokedPill = false;
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('ChatService: Error parsing WebSocket message: $e');
    }
  }

  Future<void> _syncSingleChat(String chatId) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final chatJson = jsonDecode(response.body) as Map<String, dynamic>;
        final chat = Chat.fromJson(chatJson);
        _chats[chat.id] = chat;
        
        final rawMessages = (chatJson['messages'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        if (rawMessages.isNotEmpty) {
          _messages[chat.id] = rawMessages.map(ChatMessage.fromJson).toList();
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ChatService: Error syncing single chat: $e');
    }
  }

  Future<bool> inviteCollaborator(String chatId, String usernameOrEmail) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/chats/$chatId/invite');
      final response = await http
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({'username': usernameOrEmail}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          await _syncSingleChat(chatId);
          return true;
        }
      }
    } catch (e) {
      debugPrint('ChatService: Invite collaborator error: $e');
    }
    return false;
  }

  Future<bool> removeCollaborator(String chatId, String usernameOrEmail) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/chats/$chatId/remove');
      final response = await http
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({'username': usernameOrEmail}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          await _syncSingleChat(chatId);
          return true;
        }
      }
    } catch (e) {
      debugPrint('ChatService: Remove collaborator error: $e');
    }
    return false;
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    debugPrint('ChatService: renameChat called for $chatId with title: "$newTitle"');
    if (_chats[chatId] != null) {
      _chats[chatId]!.title = newTitle;
      // Update cache if this is the current chat
      if (_currentChatId == chatId) {
        await _saveCurrentChatToCache();
      }
      notifyListeners();

      // Save title to backend database (network request happens in background)
      try {
        final uri = Uri.parse('$_apiBaseUrl/chats/$chatId');
        debugPrint('ChatService: PATCHing title change to $uri');
        final response = await http
            .patch(
              uri,
              headers: _headers(),
              body: jsonEncode({'title': newTitle}),
            )
            .timeout(const Duration(seconds: 10));
        debugPrint('ChatService: PATCH title response code: ${response.statusCode}');
      } catch (e) {
        debugPrint('ChatService: Error PATCHing title to server: $e');
      }
    } else {
      debugPrint('ChatService: renameChat failed because _chats[$chatId] was null');
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

  bool _isDownloading = false;
  String? _downloadingFileName;
  
  bool get isDownloading => _isDownloading;
  String? get downloadingFileName => _downloadingFileName;

  Future<File?> downloadFile(String messageId, String fileId, String fileName) async {
    _isDownloading = true;
    _downloadingFileName = fileName;
    notifyListeners();
    
    try {
      final uri = Uri.parse('$_apiBaseUrl/api/files/$fileId');
      final client = http.Client();
      final request = http.Request('GET', uri);
      request.headers.addAll(_headers());
      
      final streamedResponse = await client.send(request);
      
      if (streamedResponse.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        
        final sink = file.openWrite();
        await streamedResponse.stream.forEach((chunk) {
          sink.add(chunk);
        });
        await sink.close();
        client.close();
        
        // Caching: Update the local message path so we don't download again
        if (_currentChatId != null && _messages.containsKey(_currentChatId)) {
          final index = _messages[_currentChatId]!.indexWhere((m) => m.id == messageId);
          if (index != -1) {
            final oldMsg = _messages[_currentChatId]![index];
            _messages[_currentChatId]![index] = ChatMessage(
              id: oldMsg.id,
              chatId: oldMsg.chatId,
              sender: oldMsg.sender,
              content: oldMsg.content,
              createdAt: oldMsg.createdAt,
              localFilePath: filePath, // Persist the local path
              fileId: oldMsg.fileId,
              fileName: oldMsg.fileName,
            );
            notifyListeners();
            _saveCurrentChatToCache(); // Persist to shared preferences
          }
        }
        
        return file;
      }
      client.close();
    } catch (e) {
      debugPrint('ChatService: Error downloading file: $e');
    } finally {
      _isDownloading = false;
      _downloadingFileName = null;
      notifyListeners();
    }
    return null;
  }
}
