import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class ConnectivityBanner extends StatelessWidget {
  final ChatService chatService;

  const ConnectivityBanner({
    super.key,
    required this.chatService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: chatService,
      builder: (context, child) {
        if (chatService.isConnected) {
          return const SizedBox.shrink();
        }

        final isConnecting = chatService.isConnecting;

        return Positioned(
          bottom: 125.0, // Aligned above the input area column
          left: 16.0,
          right: 16.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: isConnecting 
                      ? Colors.amber.shade900.withValues(alpha: 0.3) 
                      : Colors.red.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cloud_off, color: Colors.white, size: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isConnecting
                            ? 'Connecting to servers...'
                            : 'Connection failed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
