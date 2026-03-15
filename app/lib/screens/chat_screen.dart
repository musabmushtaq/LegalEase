import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_drawer.dart';
import '../widgets/message_bubble.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  late ScrollController _scrollController;
  bool _isTyping = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeService();
    _textController.addListener(() {
      setState(() {
        _isTyping = _textController.text.isNotEmpty;
      });
    });
  }

  Future<void> _initializeService() async {
    await _chatService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: ChatDrawer(
        chatService: _chatService,
        onChatSelected: () {
          setState(() {});
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Chat Body (Scrollable)
            _buildChatBody(),

            // Top Overlay Actions (Menu & New Chat)
            Positioned(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFloatingIconButton(
                    icon: Icons.menu,
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  _buildFloatingIconButton(
                    icon: Icons.chat_bubble_outline,
                    onPressed: _createNewChat,
                  ),
                ],
              ),
            ),

            // Bottom Overlay Actions (File, Text Input, Voice/Send)
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Row(
                children: [
                  _buildFloatingIconButton(
                    icon: Icons.attach_file,
                    onPressed: () {
                      // TODO: Implement files/camera popup
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: AppTheme.highlight,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 8.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: AppTheme.textBody),
                        decoration: const InputDecoration(
                          hintText: "Ask LegalEase...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFloatingIconButton(
                    icon: _isTyping ? Icons.send : Icons.mic,
                    onPressed: _isTyping
                        ? _sendMessage
                        : () {
                            // TODO: Implement voice input
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    final messages = _chatService.currentMessages;

    if (messages.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              "Ask me something...",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 80.0, bottom: 100.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  }

  void _createNewChat() {
    setState(() {
      _chatService.createNewChat();
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _chatService.addMessage(text, 'user');
    _textController.clear();
    setState(() {
      _isTyping = false;
    });
    _scrollToBottom();

    // TODO: Call API to get response from backend
    // For now, add a dummy response after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _chatService.addMessage(
          'This is a placeholder response. Real responses will come from the backend.',
          'ai',
        );
        setState(() {});
        _scrollToBottom();
      }
    });
  }

  Widget _buildFloatingIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.highlight, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
            spreadRadius: 2.0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashColor: AppTheme.highlight.withValues(alpha: 0.2),
          highlightColor: AppTheme.highlight.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
