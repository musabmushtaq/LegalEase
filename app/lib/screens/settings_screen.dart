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

  @override
  void initState() {
    super.initState();
    // Extract just the IP address from the full URL
    String currentUrl = ChatService.apiBaseUrl;
    String currentIp = '';
    try {
      final uri = Uri.parse(currentUrl);
      currentIp = uri.host;
    } catch (e) {
      currentIp = '127.0.0.1';
    }
    
    // Fallback if parsing failed but we know it contains an IP
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
      // Reconstruct the full URL
      final newUrl = 'http://$newIp:8000';
      widget.chatService.updateApiBaseUrl(newUrl);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved! Connecting to new server...', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Configuration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Update the backend API IP address. The app will automatically connect via port 8000.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            
            // Input Field
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'IPv4 Address',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: '192.168.x.x',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                prefixIcon: const Icon(Icons.wifi, color: Colors.grey),
                suffixText: ':8000',
                suffixStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.highlight, width: 1.5),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.highlight,
                  foregroundColor: AppTheme.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
