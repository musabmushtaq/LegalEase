import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const LegalEaseApp());
}

class LegalEaseApp extends StatelessWidget {
  const LegalEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LegalEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ChatScreen(),
    );
  }
}
