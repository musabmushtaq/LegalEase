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
        final showBanner = !chatService.isConnected;
        final isConnecting = chatService.isConnecting;

        return AnimatedContainer(
          duration: Duration(milliseconds: showBanner ? 180 : 350),
          curve: Curves.easeInOut,
          height: showBanner ? 56.0 : 0.0,
          margin: EdgeInsets.only(bottom: showBanner ? 8.0 : 0.0),
          child: AnimatedScale(
            duration: Duration(milliseconds: showBanner ? 180 : 350),
            curve: Curves.easeOutCubic,
            scale: showBanner ? 1.0 : 0.0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: showBanner ? 150 : 300),
              opacity: showBanner ? 1.0 : 0.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: isConnecting 
                          ? Colors.amber.shade900.withValues(alpha: 0.35) 
                          : Colors.red.shade900.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(28.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        isConnecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.cloud_off, color: Colors.white, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isConnecting
                                ? 'Connecting...'
                                : 'Connection failed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
