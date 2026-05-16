import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:dotted_border/dotted_border.dart';
import '../theme/app_theme.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';

class ChatDrawer extends StatefulWidget {
  final ChatService chatService;
  final VoidCallback onChatSelected;

  const ChatDrawer({
    super.key,
    required this.chatService,
    required this.onChatSelected,
  });

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  Future<void> _togglePin(String id) async {
    await widget.chatService.togglePinChat(id);
    // Don't call setState - ChatService notifies listeners
  }

  Future<void> _deleteChat(String id) async {
    final wasCurrentChat = widget.chatService.currentChatId == id;
    await widget.chatService.deleteChat(id);

    if (wasCurrentChat) {
      // If the deleted chat was the current one, trigger ChatScreen rebuild
      if (mounted) {
        widget.onChatSelected();
      }
    }
    // Don't call setState - ChatService notifies listeners
  }

  void _renameChat(String id, String currentTitle) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentTitle);
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: const Text(
            'Rename Chat',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'New name',
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppTheme.highlight),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: AppTheme.highlight,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  widget.chatService.renameChat(id, controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Rename',
                style: TextStyle(color: AppTheme.highlight),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showChatMenu(Chat chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.edit,
                    label: 'Rename',
                    color: AppTheme.highlight,
                    onTap: () {
                      Navigator.pop(context);
                      _renameChat(chat.id, chat.title);
                    },
                  ),
                  _buildMenuItem(
                    icon: chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    label: chat.isPinned ? 'Unpin' : 'Pin',
                    color: AppTheme.highlight,
                    onTap: () {
                      Navigator.pop(context);
                      _togglePin(chat.id);
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildMenuItem(
                    icon: Icons.delete,
                    label: 'Delete',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteChat(chat.id);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chats = widget.chatService.displayedChats;
    final pinnedChats = chats.where((c) => c.isPinned).toList();
    final recentChats = chats.where((c) => !c.isPinned).toList();

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.0,
                  ),
                ),
              ),
              child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Search Bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: AppTheme.textBody,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search for chats",
                          hintStyle: TextStyle(color: Color(0xFF69676C)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // New Chat and Temp Chat Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await widget.chatService.createNewChat();
                      if (!context.mounted) return;
                      widget.onChatSelected();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    label: Text(
                      "New chat",
                      style: TextStyle(
                        color: AppTheme.highlight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  _buildGlassActionButton(
                    icon: Icons.chat_bubble_outline,
                    isActive: widget.chatService.isTemporaryChat,
                    onTap: () {
                      widget.chatService.toggleTemporaryChat();
                      if (context.mounted) {
                        widget.onChatSelected();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chats List Wrapper
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.chatService,
                  builder: (context, _) {
                    if (widget.chatService.isConnecting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.highlight),
                        ),
                      );
                    }
                    if (!widget.chatService.isConnected) {
                      return const Center(
                        child: Text(
                          "History unavailable",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "Chats",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Pinned Sublist
                        if (pinnedChats.isNotEmpty)
                          ...pinnedChats.map((c) => _buildChatItem(c)),

                        // Recent Sublist
                        if (recentChats.isNotEmpty) ...[
                          const SizedBox(height: 12), // Visual separation
                          ...recentChats.map((c) => _buildChatItem(c)),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // Bottom settings/logout
              const Divider(color: Color(0xFF363537)),
              ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Close drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(chatService: widget.chatService),
                  ),
                );
              },
            ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  widget.chatService.isAuthenticated
                      ? Icons.logout
                      : Icons.login,
                  color: Colors.grey,
                ),
                title: Text(
                  widget.chatService.isAuthenticated
                      ? 'Logout'
                      : 'Login / Sign Up',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  if (widget.chatService.isAuthenticated) {
                    await widget.chatService.logout();
                  }
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LoginScreen(chatService: widget.chatService),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildChatItem(Chat chat) {
    final isCurrentChat = widget.chatService.currentChatId == chat.id;
    final isGeneratingTitle = widget.chatService.isTitleGenerating(chat.id);

    return GestureDetector(
      onLongPress: () {
        _showChatMenu(chat);
      },
      onTap: () {
        widget.chatService.selectChat(chat.id);
        widget.onChatSelected();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: isCurrentChat
              ? AppTheme.highlight.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isCurrentChat
                ? AppTheme.highlight.withValues(alpha: 0.5)
                : Colors.transparent,
            width: isCurrentChat ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: isGeneratingTitle
                  ? _buildAnimatedTitle(chat.title, isCurrentChat)
                  : Text(
                      chat.title,
                      style: TextStyle(
                        color: isCurrentChat
                            ? AppTheme.highlight
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: isCurrentChat
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (chat.isPinned)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.push_pin,
                  color: AppTheme.highlight,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle(String title, bool isCurrentChat) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, opacity, child) {
        return Text(
          title,
          style: TextStyle(
            color: (isCurrentChat ? AppTheme.highlight : Colors.white)
                .withValues(alpha: opacity),
            fontSize: 15,
            fontWeight: isCurrentChat ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  Widget _buildGlassActionButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final container = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: isActive 
              ? AppTheme.highlight.withValues(alpha: 0.4) 
              : Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(
              icon,
              color: isActive ? AppTheme.highlight : Colors.grey[400],
              size: 20,
            ),
          ),
        ),
      ),
    );

    if (isActive) {
      return DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          radius: Radius.circular(30),
          color: AppTheme.highlight,
          dashPattern: [4, 4],
          strokeWidth: 1.5,
        ),
        child: container,
      );
    }

    return container;
  }
}
