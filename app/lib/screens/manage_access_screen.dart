import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/chat_service.dart';
import '../models/chat.dart';
import '../theme/app_theme.dart';

class ManageAccessScreen extends StatefulWidget {
  final ChatService chatService;
  final Chat chat;

  const ManageAccessScreen({
    super.key,
    required this.chatService,
    required this.chat,
  });

  @override
  State<ManageAccessScreen> createState() => _ManageAccessScreenState();
}

class _ManageAccessScreenState extends State<ManageAccessScreen> {
  bool _isLoading = false;
  String? _ownerName;
  final List<Map<String, String>> _collaborators = [];

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
    if (!widget.chat.isShared) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.chatService.toggleShareChat(widget.chat.id, true);
      });
    }
  }

  Future<void> _fetchProfiles() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _collaborators.clear();
    });

    try {
      // 1. Resolve Owner
      final ownerProfile = await widget.chatService.getUserProfile(widget.chat.userId);
      if (ownerProfile != null) {
        _ownerName = ownerProfile['username'] ?? 'Owner';
      } else {
        _ownerName = 'Owner';
      }

      // 2. Resolve Collaborators
      // Fetch the updated chat object from service in case it changed
      final currentChat = widget.chatService.allChats.firstWhere(
        (c) => c.id == widget.chat.id,
        orElse: () => widget.chat,
      );

      for (final collaboratorId in currentChat.collaborators) {
        final profile = await widget.chatService.getUserProfile(collaboratorId);
        if (profile != null) {
          _collaborators.add({
            'username': profile['username'] ?? 'User',
            'email': profile['email'] ?? '',
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading collaborator profiles: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _confirmMakePrivate() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          title: const Text(
            'Make Private?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure? All collaborators will lose access, and this chat will become completely private.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _makePrivate();
              },
              child: const Text(
                'Make Private',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePrivate() async {
    HapticFeedback.mediumImpact();
    // Revert is_shared to false on server and local cache
    await widget.chatService.toggleShareChat(widget.chat.id, false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Chat is now private.'),
          backgroundColor: AppTheme.background,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context); // Go back to the chat screen
    }
  }

  void _showInviteDialog() {
    final controller = TextEditingController();
    bool isInviting = false;
    String? errorText;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.0,
                ),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.person_add_rounded,
                    color: AppTheme.highlight,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Add Collaborator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter the username or email address of the person you want to invite to this conversation.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: errorText != null 
                            ? Colors.redAccent 
                            : Colors.white.withValues(alpha: 0.08),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.alternate_email, color: Colors.white30, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Username or email',
                              hintStyle: TextStyle(color: Colors.white24),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isInviting ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.highlight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                  onPressed: isInviting
                      ? null
                      : () async {
                          final value = controller.text.trim();
                          if (value.isEmpty) {
                            setState(() {
                              errorText = 'Please enter a username or email';
                            });
                            return;
                          }

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(this.context);

                          setState(() {
                            isInviting = true;
                            errorText = null;
                          });

                          final success = await widget.chatService.inviteCollaborator(
                            widget.chat.id,
                            value,
                          );

                          if (success) {
                            navigator.pop(); // Close dialog
                            _fetchProfiles(); // Refresh the list
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('✓ Successfully added $value to chat.'),
                                  backgroundColor: AppTheme.background,
                                ),
                              );
                            }
                          } else {
                            setState(() {
                              isInviting = false;
                              errorText = 'User not found or connection failed';
                            });
                          }
                        },
                  child: isInviting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                          ),
                        )
                      : const Text(
                          'Add',
                          style: TextStyle(
                            color: AppTheme.background,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUserRow({
    required String username,
    required String subtitle,
    required bool isOwner,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isOwner 
                ? AppTheme.highlight.withValues(alpha: 0.15) 
                : Colors.white.withValues(alpha: 0.08),
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: TextStyle(
                color: isOwner ? AppTheme.highlight : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isOwner ? AppTheme.highlight.withValues(alpha: 0.7) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCollaboratorButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.highlight,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.highlight.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _showInviteDialog();
          },
          borderRadius: BorderRadius.circular(12.0),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_rounded,
                color: AppTheme.background,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Add Collaborator',
                style: TextStyle(
                  color: AppTheme.background,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Manage Shared Access',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Deep Glassmorphic Backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD 1: Upper Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.people_outline,
                                color: AppTheme.highlight,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Collaborators',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.highlight),
                                    ),
                                  )
                                : ListView(
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      if (_ownerName != null)
                                        _buildUserRow(
                                          username: _ownerName!,
                                          subtitle: 'Owner',
                                          isOwner: true,
                                        ),
                                      const Divider(color: Colors.white10, height: 16),
                                      if (_collaborators.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                                          child: Center(
                                            child: Opacity(
                                              opacity: 0.45,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.group_add_outlined,
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                    size: 36,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    'No collaborators yet.\nInvite others to join!',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        ..._collaborators.map((c) => _buildUserRow(
                                              username: c['username'] ?? '',
                                              subtitle: c['email'] ?? '',
                                              isOwner: false,
                                            )),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _buildAddCollaboratorButton(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // CARD 2: Bottom Card (No inner button - the entire card is the button itself)
                  Container(
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
                            HapticFeedback.heavyImpact();
                            _confirmMakePrivate();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock_reset_outlined,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                                const SizedBox(width: 16.0),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Make Chat Private",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4.0),
                                      Text(
                                        "Revoke access for all collaborators.",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
