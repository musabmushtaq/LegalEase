import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:dotted_border/dotted_border.dart';
import '../theme/app_theme.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/manage_access_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.chatService.searchQuery;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.chatService.setSearchQuery(_searchController.text);
    });
    setState(() {});
  }

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
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 16.0, // Reduced bottom padding to prevent double spacing
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
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
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuItem(
                          icon: Icons.edit,
                          label: 'Rename',
                          color: AppTheme.highlight,
                          onTap: () {
                            Navigator.pop(context);
                            _renameChat(chat.id, chat.title);
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildMenuItem(
                          icon: chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          label: chat.isPinned ? 'Unpin' : 'Pin',
                          color: AppTheme.highlight,
                          onTap: () {
                            Navigator.pop(context);
                            _togglePin(chat.id);
                          },
                        ),
                        const SizedBox(height: 10),
                        if (chat.userId == widget.chatService.userId) ...[
                          _buildMenuItem(
                            icon: chat.isShared ? Icons.people_outline : Icons.share_outlined,
                            label: chat.isShared ? 'Manage Shared Access' : 'Share Chat',
                            color: AppTheme.highlight,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManageAccessScreen(
                                    chatService: widget.chatService,
                                    chat: chat,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        _buildMenuItem(
                          icon: Icons.delete,
                          label: 'Delete',
                          color: Colors.redAccent,
                          onTap: () {
                            Navigator.pop(context);
                            _deleteChat(chat.id);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), // Match horizontal padding (16.0)
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F11).withValues(alpha: 0.85),
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // Capsule Search Bar
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(26.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, 
                             color: Colors.white.withValues(alpha: 0.3), 
                             size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: "Search conversations",
                              hintStyle: TextStyle(
                                color: Color(0xFF69676C),
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              widget.chatService.setSearchQuery('');
                              FocusScope.of(context).unfocus();
                            },
                            child: Icon(
                              Icons.clear_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Capsule Action Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.highlight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: AppTheme.highlight.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                widget.chatService.clearCurrentChat();
                                _searchController.clear();
                                widget.chatService.setSearchQuery('');
                                if (!context.mounted) return;
                                widget.onChatSelected();
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(26),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_rounded, 
                                         color: AppTheme.highlight, 
                                         size: 22),
                                    SizedBox(width: 12),
                                    Text(
                                      "New Chat",
                                      style: TextStyle(
                                        color: AppTheme.highlight,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildGlassActionButton(
                        icon: Icons.chat_bubble_outline,
                        isActive: widget.chatService.isTemporaryChat,
                        onTap: () {
                          widget.chatService.toggleTemporaryChat();
                          _searchController.clear();
                          widget.chatService.setSearchQuery('');
                          if (context.mounted) {
                            widget.onChatSelected();
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      "HISTORY",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  // Chats List Wrapper
                  Expanded(
                    child: ListenableBuilder(
                      listenable: widget.chatService,
                      builder: (context, _) {
                        final chats = widget.chatService.displayedChats;
                        // Sort: Shared chats float above pinned chats, which float above others, sorted by updatedAt
                        final sortedChats = List<Chat>.from(chats)..sort((a, b) {
                          if (a.isShared && !b.isShared) return -1;
                          if (!a.isShared && b.isShared) return 1;
                          if (a.isPinned && !b.isPinned) return -1;
                          if (!a.isPinned && b.isPinned) return 1;
                          return b.updatedAt.compareTo(a.updatedAt);
                        });

                        if (widget.chatService.isConnecting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.highlight),
                            ),
                          );
                        }
                        
                        if (chats.isEmpty) {
                          final isSearching = widget.chatService.searchQuery.isNotEmpty;
                          return Center(
                            child: Opacity(
                              opacity: 0.4,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSearching ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded, 
                                    color: Colors.white.withValues(alpha: 0.2), 
                                    size: 40,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isSearching ? "No matching chats found" : "No chats yet",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView(
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            ...sortedChats.map((c) => _buildChatItem(c)),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ),

                  // Bottom Section
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildFooterItem(
                          icon: Icons.settings_suggest_rounded,
                          label: "Settings",
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(chatService: widget.chatService),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        _buildFooterItem(
                          icon: widget.chatService.isAuthenticated
                              ? Icons.logout_rounded
                              : Icons.login_rounded,
                          label: widget.chatService.isAuthenticated
                              ? "Logout"
                              : "Login / Sign Up",
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
                      ],
                    ),
                  ),
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
      key: ValueKey(chat.id),
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _showChatMenu(chat);
      },
      onTap: () {
        HapticFeedback.selectionClick();
        widget.chatService.selectChat(chat.id);
        _searchController.clear();
        widget.chatService.setSearchQuery('');
        widget.onChatSelected();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isCurrentChat
              ? AppTheme.highlight.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26.0),
          border: Border.all(
            color: isCurrentChat
                ? AppTheme.highlight.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.0,
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
            if (chat.isShared)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.share_outlined,
                  color: AppTheme.highlight,
                  size: 16,
                ),
              )
            else if (chat.isPinned)
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

  Widget _buildFooterItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
      width: 52,
      height: 52,
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
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              color: isActive ? AppTheme.highlight : Colors.white.withValues(alpha: 0.4),
              size: 20,
            ),
          ),
        ),
      ),
    );

    if (isActive) {
      return DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          radius: Radius.circular(26),
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
