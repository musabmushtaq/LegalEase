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
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final newIp = _ipController.text.trim();
    if (newIp.isNotEmpty) {
      final newUrl = 'http://$newIp:8000';
      widget.chatService.updateApiBaseUrl(newUrl);
      
      setState(() {
        _isSaved = true;
      });
      
      // Reset the saved state after a few seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isSaved = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
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
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Network Configuration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set the backend API IP address. The app connects via port 8000 by default.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(28.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi, color: Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _ipController,
                            onChanged: (_) {
                              if (_isSaved) setState(() => _isSaved = false);
                            },
                            style: const TextStyle(color: Colors.white, fontSize: 16),
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
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isSaved 
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppTheme.highlight.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(28),
                          border: _isSaved 
                              ? Border.all(color: AppTheme.highlight.withValues(alpha: 0.5))
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _saveSettings,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSaved) 
                                    const Icon(Icons.check_circle_outline, color: AppTheme.highlight, size: 20),
                                  if (_isSaved) const SizedBox(width: 8),
                                  Text(
                                    _isSaved ? 'Settings Saved' : 'Save Configuration',
                                    style: TextStyle(
                                      color: _isSaved ? AppTheme.highlight : AppTheme.background,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
