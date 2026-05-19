import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final ChatService chatService;
  const SettingsScreen({super.key, required this.chatService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  bool _isSaved = false;
  String _initialIp = '';

  @override
  void initState() {
    super.initState();
    String currentUrl = ChatService.apiBaseUrl;
    String currentIp = '';
    try {
      final uri = Uri.parse(currentUrl);
      currentIp = uri.host;
    } catch (e) {
      currentIp = '127.0.0.1';
    }
    
    if (currentIp.isEmpty) {
      currentIp = currentUrl.replaceAll('http://', '').replaceAll(':8000', '');
    }
    _ipController.text = currentIp;
    _initialIp = currentIp;
  }

  bool get _isIpModified {
    return _ipController.text.trim() != _initialIp;
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _submitIp(String value) {
    final cleanIp = value.trim();
    
    // IP Validation check (support IPv4 or 'localhost')
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    
    final isValid = ipRegex.hasMatch(cleanIp) || cleanIp == 'localhost';
    
    if (isValid) {
      final newUrl = 'http://$cleanIp:8000';
      widget.chatService.updateApiBaseUrl(newUrl);
      setState(() {
        _initialIp = cleanIp;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Connection updated to: $cleanIp'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Revert the text back to the initial valid IP
      setState(() {
        _ipController.text = _initialIp;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✗ Invalid IP address. Reverted to previous host.'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // A premium glassmorphic confirmation modal
  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          title: Row(
            children: [
              Icon(
                isDestructive ? Icons.warning_amber_rounded : Icons.info_outline,
                color: isDestructive ? Colors.redAccent : AppTheme.highlight,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                backgroundColor: isDestructive 
                    ? Colors.redAccent.withValues(alpha: 0.85) 
                    : AppTheme.highlight.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text(
                isDestructive ? 'Delete' : 'Confirm',
                style: TextStyle(
                  color: isDestructive ? Colors.white : AppTheme.background,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper widget to construct settings sections
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 12.0),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          width: double.infinity,
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
            child: Column(
              children: children,
            ),
          ),
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  // Row items inside sections
  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.white).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
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
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text(
          'Settings', 
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // SECTION 1: NETWORK CONFIGURATION
                  _buildSection(
                    title: 'Network Configuration',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set the backend IP address.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.wifi, color: Colors.white54, size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _ipController,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: _submitIp,
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        hintText: '192.168.x.x',
                                        hintStyle: TextStyle(color: Colors.white24),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ':8000',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (widget.chatService.isAuthenticated) ...[
                    // SECTION 2: PRIVACY & DATA MANAGEMENT
                    _buildSection(
                      title: 'Privacy & Data Management',
                      children: [
                        _buildSettingsRow(
                          icon: Icons.delete_sweep_outlined,
                          iconColor: Colors.redAccent,
                          textColor: Colors.redAccent,
                          title: 'Delete Personal Context',
                          subtitle: 'Clear all inferred AI data instantly. This action is irreversible.',
                          onTap: () {
                            _showConfirmationDialog(
                              title: 'Delete Personal Context?',
                              message: 'This will completely wipe your personal context history from the server. The AI will no longer know your background details.',
                              isDestructive: true,
                              onConfirm: () async {
                                final success = await widget.chatService.clearPersonalContext();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success 
                                            ? '✓ Personal context wiped successfully.' 
                                            : '✗ Failed to clear personal context. Please check your network connection.',
                                      ),
                                      backgroundColor: success ? Colors.teal : Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                        const Divider(color: Colors.white10, height: 1.0, indent: 56.0),
                        _buildSettingsRow(
                          icon: Icons.history_rounded,
                          iconColor: Colors.redAccent,
                          textColor: Colors.redAccent,
                          title: 'Clear All Chat History',
                          subtitle: 'Wipe every active persistent conversation from this account.',
                          onTap: () {
                            _showConfirmationDialog(
                              title: 'Clear Chat History?',
                              message: 'This will delete ALL active chats permanently from the server and local database. You cannot restore them.',
                              isDestructive: true,
                              onConfirm: () async {
                                final success = await widget.chatService.clearAllChatHistory();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success 
                                            ? '✓ Chat history completely deleted.' 
                                            : '✗ Error resetting chat history.',
                                      ),
                                      backgroundColor: success ? Colors.teal : Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),

                    // SECTION 3: ACCOUNT & SESSION MANAGEMENT
                    _buildSection(
                      title: 'Account & Session Management',
                      children: [
                        _buildSettingsRow(
                          icon: Icons.no_accounts_outlined,
                          iconColor: Colors.redAccent,
                          textColor: Colors.redAccent,
                          title: 'Permanently Delete Account',
                          subtitle: 'Delete your user profile, purge all chat history, clear personal context, and close your account permanently.',
                          onTap: () {
                            _showConfirmationDialog(
                              title: 'Permanently Delete Account?',
                              message: 'WARNING: This will permanently wipe all your chats, user profile context, local tokens, and logs. This action is irreversible.',
                              isDestructive: true,
                              onConfirm: () async {
                                final success = await widget.chatService.deleteAccount();
                                if (mounted) {
                                  if (success) {
                                    Navigator.popUntil(context, (route) => route.isFirst);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✗ Failed to delete account. Connection issues.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                        const Divider(color: Colors.white10, height: 1.0, indent: 56.0),
                        _buildSettingsRow(
                          icon: Icons.logout_rounded,
                          iconColor: Colors.white70,
                          title: 'Log Out of Account',
                          subtitle: 'End this session. Cached data will be cleared from this device.',
                          onTap: () {
                            _showConfirmationDialog(
                              title: 'Log Out?',
                              message: 'Are you sure you want to end your current session?',
                              onConfirm: () async {
                                await widget.chatService.logout();
                                if (mounted) {
                                  Navigator.popUntil(context, (route) => route.isFirst);
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 36.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
