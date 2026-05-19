import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final chatService = ChatService();
  await chatService.initialize();
  
  runApp(
    ChangeNotifierProvider.value(
      value: chatService,
      child: const LegalEaseApp(),
    ),
  );
}

class LegalEaseApp extends StatelessWidget {
  const LegalEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        return MaterialApp(
          title: 'LegalEase',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: chatService.isAuthenticated
              ? const ChatScreen()
              : LoginScreen(chatService: chatService),
        );
      },
    );
  }
}
