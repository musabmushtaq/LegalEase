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
  @override
  void initState() {
    super.initState();
    if (!widget.chat.isShared) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.chatService.toggleShareChat(widget.chat.id, true);
      });
    }
  }

  void _confirmRemoveAccess() {
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
            'Remove Access?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure? All collaborators will lose access, and this chat will revert to private.',
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
                _removeAccessAll();
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeAccessAll() async {
    HapticFeedback.mediumImpact();
    // Revert is_shared to false on server and local cache
    await widget.chatService.toggleShareChat(widget.chat.id, false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Shared access removed successfully.'),
          backgroundColor: AppTheme.background,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context); // Go back to the chat screen
    }
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Icon and Card
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: AppTheme.highlight,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Shared Conversation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This chat is currently collaborative. You can revoke access for all invited collaborators below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Revoke Access Button
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(27),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            _confirmRemoveAccess();
                          },
                          borderRadius: BorderRadius.circular(27),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_reset_outlined,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Remove Access All",
                                  style: TextStyle(
                                    color: Colors.redAccent,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
