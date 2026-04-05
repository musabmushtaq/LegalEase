import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ConnectivityBanner extends StatelessWidget {
  final ChatService chatService;

  const ConnectivityBanner({super.key, required this.chatService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: chatService,
      builder: (context, child) {
        if (chatService.isConnected) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 90.0,
          left: 16.0,
          right: 16.0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade800,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Unable to connect to servers, please try again later',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
