import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:dotted_border/dotted_border.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_drawer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/connectivity_banner.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  late ScrollController _scrollController;
  bool _isTyping = false;
  bool _isInitialized = false;
  File? _attachedFile;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _attachedFile = File(image.path);
          _isTyping = true; // allow sending immediately
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
          _isTyping = true; // allow sending immediately
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File type not supported/picked')),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.highlight),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppTheme.highlight),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file,
                color: AppTheme.highlight,
              ),
              title: const Text(
                'Document or File',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeService();
    _textController.addListener(() {
      setState(() {
        _isTyping = _textController.text.isNotEmpty;
      });
    });
  }

  Future<void> _initializeService() async {
    await _chatService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: ChatDrawer(
        chatService: _chatService,
        onChatSelected: () {
          setState(() {});
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Chat Body (Scrollable)
            _buildChatBody(),

            // Top Overlay Actions (Menu & New Chat)
            Positioned(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFloatingIconButton(
                    icon: Icons.menu,
                    isDotted: _chatService.isTemporaryChat,
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  _buildFloatingIconButton(
                    icon: Icons.chat_bubble_outline,
                    isDotted: _chatService.isTemporaryChat,
                    onPressed: _createNewChat,
                  ),
                ],
              ),
            ),

            // Bottom Overlay Actions (File, Text Input, Voice/Send)
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_chatService.isTemporaryChat)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "You are in a Temporary Chat mode. Messages won't be saved permanently.",
                        style: TextStyle(
                          color: AppTheme.highlight.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Row(
                    children: [
                      _buildFloatingIconButton(
                        icon: Icons.attach_file,
                        isDotted: _chatService.isTemporaryChat,
                        onPressed: _showAttachmentOptions,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_attachedFile != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _chatService.isTemporaryChat
                                        ? DottedBorder(
                                            options:
                                                const RoundedRectDottedBorderOptions(
                                                  radius: Radius.circular(12),
                                                  color: AppTheme.highlight,
                                                  dashPattern: [6, 4],
                                                  strokeWidth: 2.0,
                                                ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.file(
                                                _attachedFile!,
                                                height: 80,
                                                width: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return _buildFilePlaceholder();
                                                    },
                                              ),
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.file(
                                              _attachedFile!,
                                              height: 80,
                                              width: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return _buildFilePlaceholder();
                                                  },
                                            ),
                                          ),
                                    Positioned(
                                      top: -8,
                                      right: -8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _attachedFile = null;
                                            _isTyping =
                                                _textController.text.isNotEmpty;
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            _chatService.isTemporaryChat
                                ? DottedBorder(
                                    options:
                                        const RoundedRectDottedBorderOptions(
                                          radius: Radius.circular(24.0),
                                          color: AppTheme.highlight,
                                          dashPattern: [6, 4],
                                          strokeWidth: 1.5,
                                        ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.background,
                                        borderRadius: BorderRadius.circular(
                                          24.0,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: TextField(
                                        controller: _textController,
                                        style: const TextStyle(
                                          color: AppTheme.textBody,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: "Ask LegalEase...",
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (text) {
                                          setState(() {
                                            _isTyping = text.trim().isNotEmpty;
                                          });
                                        },
                                        maxLines: 3,
                                        minLines: 1,
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.background,
                                      borderRadius: BorderRadius.circular(24.0),
                                      border: Border.all(
                                        color: AppTheme.highlight,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 8.0,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: TextField(
                                      controller: _textController,
                                      style: const TextStyle(
                                        color: AppTheme.textBody,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: "Ask LegalEase...",
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (text) {
                                        setState(() {
                                          _isTyping = text.trim().isNotEmpty;
                                        });
                                      },
                                      maxLines: 3,
                                      minLines: 1,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildFloatingIconButton(
                        icon: _isTyping ? Icons.send : Icons.mic,
                        isDotted: _chatService.isTemporaryChat,
                        onPressed: _isTyping
                            ? _sendMessage
                            : () {
                                // TODO: Implement voice input
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Connection Banner Floating
            ConnectivityBanner(chatService: _chatService),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    final messages = _chatService.currentMessages;

    if (messages.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              "Ask me something...",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 80.0, bottom: 100.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  }

  Future<void> _createNewChat() async {
    _chatService.clearCurrentChat();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachedFile == null) return;

    final fileToSend = _attachedFile;
    final messageText = text.isEmpty ? "Sent an attachment" : text;

    _textController.clear();
    setState(() {
      _isTyping = false;
      _attachedFile = null;
    });

    await _chatService.sendUserMessage(messageText, file: fileToSend);

    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  Widget _buildFilePlaceholder() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: AppTheme.highlight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.highlight.withValues(alpha: 0.4)),
      ),
      child: const Center(
        child: Icon(Icons.insert_drive_file, color: AppTheme.highlight),
      ),
    );
  }

  Widget _buildFloatingIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isDotted = false,
  }) {
    if (isDotted) {
      return DottedBorder(
        options: const CircularDottedBorderOptions(
          color: AppTheme.highlight,
          dashPattern: [6, 4],
          strokeWidth: 2.0,
          padding: EdgeInsets.zero,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 16.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              splashColor: AppTheme.highlight.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.highlight, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
            spreadRadius: 2.0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashColor: AppTheme.highlight.withValues(alpha: 0.2),
          highlightColor: AppTheme.highlight.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
