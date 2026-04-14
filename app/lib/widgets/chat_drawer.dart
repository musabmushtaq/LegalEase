import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../theme/app_theme.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../screens/login_screen.dart';

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
  String? _selectedChatId;

  Future<void> _togglePin(String id) async {
    await widget.chatService.togglePinChat(id);
    setState(() {});
  }

  Future<void> _deleteChat(String id) async {
    await widget.chatService.deleteChat(id);
    setState(() {});
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
                  setState(() {});
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
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.highlight),
              title: const Text(
                'Rename',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _renameChat(chat.id, chat.title);
              },
            ),
            ListTile(
              leading: Icon(
                chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: AppTheme.highlight,
              ),
              title: Text(
                chat.isPinned ? 'Unpin' : 'Pin',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _togglePin(chat.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteChat(chat.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show chats that have messages
    final chats = widget.chatService.displayedChats;
    final pinnedChats = chats.where((c) => c.isPinned).toList();
    final recentChats = chats.where((c) => !c.isPinned).toList();

    return Drawer(
      backgroundColor: AppTheme.background,
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
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: const Color(0xFF363537),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                  IconButton(
                    onPressed: () {
                      widget.chatService.toggleTemporaryChat();
                      if (context.mounted) {
                        widget.onChatSelected();
                        Navigator.pop(context);
                      }
                    },
                    icon: widget.chatService.isTemporaryChat
                        ? DottedBorder(
                            options: const CircularDottedBorderOptions(
                              color: AppTheme.highlight,
                              dashPattern: [4, 4],
                              strokeWidth: 1.5,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: AppTheme.highlight,
                                size: 20,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey,
                          ),
                    tooltip: "Temporary Chat Mode",
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chats List Wrapper
              Expanded(
                child: !widget.chatService.isConnected
                    ? const Center(
                        child: Text(
                          "Cannot connect",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView(
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
                      ),
              ),

              // Bottom settings/logout
              const Divider(color: Color(0xFF363537)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  widget.chatService.isAuthenticated ? Icons.logout : Icons.login,
                  color: Colors.grey,
                ),
                title: Text(
                  widget.chatService.isAuthenticated ? 'Logout' : 'Login / Sign Up',
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
                        builder: (_) => LoginScreen(chatService: widget.chatService),
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
    );
  }

  Widget _buildChatItem(Chat chat) {
    final isSelected = _selectedChatId == chat.id;

    return GestureDetector(
      onLongPress: () {
        setState(() => _selectedChatId = chat.id);
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
          color: isSelected
              ? Colors.grey.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? Colors.grey.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chat.title,
                style: const TextStyle(color: Colors.white, fontSize: 15),
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
}
