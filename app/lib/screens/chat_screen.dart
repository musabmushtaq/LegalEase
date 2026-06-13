import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import 'package:dotted_border/dotted_border.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_drawer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/thinking_indicator.dart';
import '../services/chat_service.dart';
import 'live_call_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _triggerMessageKey = GlobalKey();
  late TextEditingController _textController;
  late ChatService _chatService;
  late ScrollController _scrollController;
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _isInitialized = false;
  bool _isAiThinking = false;
  File? _attachedFile;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isAtBottom = true;
  bool _showNewMessagesPill = false;
  int _lastMessageCount = 0;
  String? _lastChatId;
  bool _hasNewUnreadMessages = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _attachedFile = File(image.path);
          _focusNode.requestFocus();
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
          _focusNode.requestFocus();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File type not supported/picked')),
      );
    }
  }

  bool _useContext = false;
  bool _isAttachmentMenuOpen = false;
  bool _showContextActivePill = false;

  void _showAttachmentOptions() {
    setState(() {
      _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
    });
  }

  Widget _buildAttachmentMenu() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _isAttachmentMenuOpen ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !_isAttachmentMenuOpen,
        child: Stack(
          children: [
            // Backdrop tap to close
            GestureDetector(
              onTap: () => setState(() => _isAttachmentMenuOpen = false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 84, // Start floating above the main button
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                tween: Tween(
                  begin: 0.0,
                  end: _isAttachmentMenuOpen ? 1.0 : 0.0,
                ),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)), // Subtle slide-up effect
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingIconButton(
                      icon: Icons.camera_alt,
                      onPressed: () {
                        _showAttachmentOptions();
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFloatingIconButton(
                      icon: Icons.image,
                      onPressed: () {
                        _showAttachmentOptions();
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFloatingIconButton(
                      icon: Icons.insert_drive_file,
                      onPressed: () {
                        _showAttachmentOptions();
                        _pickFile();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFloatingIconButton(
                      icon: Icons.person,
                      iconColor: _useContext ? Colors.yellowAccent : Colors.white,
                      onPressed: () {
                        _showAttachmentOptions();
                        setState(() {
                          _useContext = !_useContext;
                          if (_useContext) {
                            _showContextActivePill = true;
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  _showContextActivePill = false;
                                });
                              }
                            });
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAttachmentOrContextIndicator() {
    IconData icon;
    Color iconColor;
    VoidCallback onMainPressed;
    VoidCallback onClearPressed;

    if (_attachedFile != null) {
      final path = _attachedFile!.path.toLowerCase();
      final isImage = path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.gif') || path.endsWith('.webp');
      icon = isImage ? Icons.image : Icons.insert_drive_file;
      iconColor = Colors.white;
      onMainPressed = () {
        OpenFile.open(_attachedFile!.path);
      };
      onClearPressed = () {
        setState(() {
          _attachedFile = null;
        });
      };
    } else {
      icon = Icons.person;
      iconColor = Colors.white;
      onMainPressed = () {
        setState(() {
          _showContextActivePill = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showContextActivePill = false;
            });
          }
        });
      };
      onClearPressed = () {
        setState(() {
          _useContext = false;
        });
      };
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main button at bottom left
            Positioned(
              left: 0,
              bottom: 0,
              child: _buildFloatingIconButton(
                icon: icon,
                iconColor: iconColor,
                onPressed: onMainPressed,
              ),
            ),
            // Circular close badge at top right within stack boundary
            Positioned(
              right: 2,
              top: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onClearPressed();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade800,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56, // Exactly one module
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Center(
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      const threshold = 40.0;
      
      final atBottom = maxScroll - currentScroll <= threshold;
      if (atBottom != _isAtBottom) {
        setState(() {
          _isAtBottom = atBottom;
          _showNewMessagesPill = !atBottom;
          if (atBottom) {
            _hasNewUnreadMessages = false;
          }
        });
      }
    });
    _textController = TextEditingController();
    _textController.addListener(() {
      setState(() {
        _isTyping = _textController.text.trim().isNotEmpty;
      });
    });
    // Already initialized in main()
    _isInitialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatService = Provider.of<ChatService>(context);
    
    final currentChatId = _chatService.currentChatId;
    if (currentChatId != _lastChatId) {
      _lastChatId = currentChatId;
      _lastMessageCount = _chatService.currentMessages.length;
      _showNewMessagesPill = false;
      _hasNewUnreadMessages = false;
      _scrollToBottom();
    } else {
      final messageCount = _chatService.currentMessages.length;
      if (_lastMessageCount != 0 && messageCount > _lastMessageCount) {
        final lastMsg = _chatService.currentMessages.last;
        final isOwnMsg = lastMsg.sender == 'user' && lastMsg.userId == _chatService.userId;
        final isAiMsg = lastMsg.sender == 'ai';
        
        bool isResponseToOwnMsg = false;
        if (isAiMsg) {
          final messages = _chatService.currentMessages;
          for (int i = messages.length - 2; i >= 0; i--) {
            if (messages[i].sender == 'user') {
              if (messages[i].userId == _chatService.userId) {
                isResponseToOwnMsg = true;
              }
              break;
            }
          }
        }
        
        if (isOwnMsg) {
          _scrollToBottom();
          setState(() {
            _showNewMessagesPill = false;
            _hasNewUnreadMessages = false;
          });
        } else if (isAiMsg && isResponseToOwnMsg) {
          if (_isAtBottom) {
            _scrollToBottom();
          } else {
            setState(() {
              _showNewMessagesPill = true;
              _hasNewUnreadMessages = true;
            });
          }
        } else {
          // Message from another user, OR AI responding to another user's message
          // Never auto-scroll, keep position and show the new messages pill
          setState(() {
            _showNewMessagesPill = true;
            _hasNewUnreadMessages = true;
          });
        }
      }
      _lastMessageCount = messageCount;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool toTrigger = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      if (toTrigger && _triggerMessageKey.currentContext != null) {
        Scrollable.ensureVisible(
          _triggerMessageKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          alignment: 0.0, // Aligns the user message to the top of the viewport
        );
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _acceleratedScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final distance = maxScroll - currentScroll;

      const maxAnimateDistance = 1500.0;
      if (distance > maxAnimateDistance) {
        // Jump closer to the bottom to avoid lag/long animation
        _scrollController.jumpTo(maxScroll - maxAnimateDistance);
      }

      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
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
            // Main Chat Body (Scrollable) - Listens to ChatService changes
            ListenableBuilder(
              listenable: _chatService,
              builder: (context, child) {
                return _buildChatBody();
              },
            ),

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
                      // Open drawer immediately without blocking network check
                      if (mounted) {
                        _scaffoldKey.currentState?.openDrawer();
                      }
                      // Non-blocking background check
                      if (!_chatService.isTemporaryChat) {
                        _chatService.checkInitialAndInstantNetwork();
                      }
                    },
                  ),
                  _buildFloatingIconButton(
                    icon: Icons.edit_outlined,
                    isDotted: _chatService.isTemporaryChat,
                    onPressed: _createNewChat,
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // New Messages Pill
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _showNewMessagesPill
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildNewMessagesPill(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Context Active Banner/Pill
                  AnimatedContainer(
                    duration: Duration(milliseconds: _showContextActivePill ? 180 : 350),
                    curve: Curves.easeInOut,
                    height: _showContextActivePill ? 56.0 : 0.0,
                    margin: EdgeInsets.only(bottom: _showContextActivePill ? 8.0 : 0.0),
                    child: AnimatedScale(
                      duration: Duration(milliseconds: _showContextActivePill ? 180 : 350),
                      curve: Curves.easeOutCubic,
                      scale: _showContextActivePill ? 1.0 : 0.0,
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: _showContextActivePill ? 150 : 300),
                        opacity: _showContextActivePill ? 1.0 : 0.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(28.0),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.person, color: Colors.yellowAccent, size: 18),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Context/Persona mode active",
                                      style: TextStyle(
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
                  ),
                  // Connectivity Banner integrated into the same column for perfect alignment
                  ConnectivityBanner(chatService: _chatService),
                  
                  // Download Status Banner (Standardized Style)
                  ListenableBuilder(
                    listenable: _chatService,
                    builder: (context, _) {
                      final isDownloading = _chatService.isDownloading;
                      final Color pillColor = Colors.white.withValues(alpha: 0.12);
                      
                      return AnimatedContainer(
                        duration: Duration(milliseconds: isDownloading ? 180 : 350),
                        curve: Curves.easeInOut,
                        height: isDownloading ? 56.0 : 0.0,
                        margin: EdgeInsets.only(bottom: isDownloading ? 8.0 : 0.0),
                        child: AnimatedScale(
                          duration: Duration(milliseconds: isDownloading ? 180 : 350),
                          curve: Curves.easeOutCubic,
                          scale: isDownloading ? 1.0 : 0.0,
                          child: AnimatedOpacity(
                            duration: Duration(milliseconds: isDownloading ? 150 : 300),
                            opacity: isDownloading ? 1.0 : 0.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  decoration: BoxDecoration(
                                    color: pillColor,
                                    borderRadius: BorderRadius.circular(28.0),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Downloading ${_chatService.downloadingFileName ?? "file"}...',
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
                  ),
                  
                  // Consistent spacing between banner and content below
                  ListenableBuilder(
                    listenable: _chatService,
                    builder: (context, _) => (!_chatService.isConnected || _chatService.isConnecting) || _chatService.isDownloading 
                      ? const SizedBox(height: 8) 
                      : const SizedBox.shrink(),
                  ),

                  if (_chatService.isTemporaryChat && _chatService.currentMessages.isEmpty)
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Animated Attachment Button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.horizontal,
                            child: FadeTransition(opacity: animation, child: child),
                          );
                        },
                        child: !_chatService.isTemporaryChat
                            ? (_isAttachmentMenuOpen
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: _buildFloatingIconButton(
                                      icon: Icons.close,
                                      onPressed: _showAttachmentOptions,
                                    ),
                                  )
                                : ((_attachedFile != null || _useContext)
                                    ? _buildActiveAttachmentOrContextIndicator()
                                    : Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: _buildFloatingIconButton(
                                          icon: Icons.attach_file,
                                          onPressed: _showAttachmentOptions,
                                        ),
                                      )))
                            : const SizedBox.shrink(),
                      ),
                      
                      Expanded(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            // Inline Tokens are handled by the TextField now
                            _chatService.isTemporaryChat
                                ? DottedBorder(
                                    options:
                                        const RoundedRectDottedBorderOptions(
                                          radius: Radius.circular(24.0),
                                          color: AppTheme.highlight,
                                          dashPattern: [6, 4],
                                          strokeWidth: 1.5,
                                        ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24.0),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                                        child: Container(
                                          constraints: const BoxConstraints(minHeight: 52.0),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppTheme.background.withOpacity(0.7),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.1),
                                              width: 1.0,
                                            ),
                                            borderRadius: BorderRadius.circular(24.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: TextField(
                                            controller: _textController,
                                            focusNode: _focusNode,
                                            style: const TextStyle(
                                              color: AppTheme.textBody,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: "Ask LegalEase...",
                                              hintStyle: TextStyle(
                                                color: Colors.white.withOpacity(0.4),
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
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
                                      ),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(24.0),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                                      child: Container(
                                        constraints: const BoxConstraints(minHeight: 52.0),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppTheme.background.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(24.0),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            width: 1.0,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                        ),
                                        child: TextField(
                                          controller: _textController,
                                          focusNode: _focusNode,
                                          style: const TextStyle(
                                            color: AppTheme.textBody,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "Ask LegalEase...",
                                            hintStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.4),
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
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
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),

                      // Animated Send/Action Button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.horizontal,
                            child: FadeTransition(opacity: animation, child: child),
                          );
                        },
                        child: (!_chatService.isTemporaryChat || _isTyping || _attachedFile != null)
                            ? Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: _buildFloatingIconButton(
                                  icon: (_isTyping || _attachedFile != null) ? Icons.send : Icons.mic,
                                  isDotted: _chatService.isTemporaryChat,
                                  onPressed: (_isTyping || _attachedFile != null)
                                      ? _sendMessage
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LiveCallScreen(
                                                chatService: _chatService,
                                                chatId: _chatService.currentChatId,
                                              ),
                                            ),
                                          );
                                        },
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Attachment Menu Overlay
            _buildAttachmentMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    final messages = _chatService.currentMessages;

    if (messages.isEmpty) {
      final username = _chatService.isTemporaryChat ? 'Stranger' : (_chatService.username ?? 'Guest');
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: (Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ) ?? const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                    color: Colors.white,
                  )),
                  children: [
                    const TextSpan(
                      text: "Hello, ",
                    ),
                    TextSpan(
                      text: username,
                      style: TextStyle(
                        color: AppTheme.highlight,
                        shadows: [
                          Shadow(
                            color: AppTheme.highlight.withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "How can I help you today?",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black,
            Colors.black,
            Colors.black.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0], // Fade in first 20% and out last 20%
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 80.0, bottom: 80.0),
        itemCount: messages.length + (_isAiThinking ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && _isAiThinking) {
            return const ThinkingIndicator();
          }
          
          final message = messages[index];
          // We apply the trigger key to the user message that preceded the current AI response
          final isTrigger = !_isAiThinking && index == messages.length - 2 && messages[index].sender == 'user';
          
          Widget bubble = MessageBubble(message: message);
          
          if (isTrigger) {
            return KeyedSubtree(
              key: _triggerMessageKey,
              child: bubble,
            );
          }
          
          return bubble;
        },
      ),
    );
  }

  Future<void> _createNewChat() async {
    _chatService.clearCurrentChat();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final messageText = _textController.text.trim();
    if (messageText.isEmpty && _attachedFile == null) return;

    final fileToSend = _attachedFile;

    _textController.clear();
    
    // sendUserMessage now injects the message into the list instantly
    final sendFuture = _chatService.sendUserMessage(
      messageText, 
      file: fileToSend,
      useContext: _useContext,
    );

    setState(() {
      _isTyping = false;
      _attachedFile = null;
      _useContext = false;
      _isAiThinking = true;
    });
    
    _scrollToBottom();

    await sendFuture;

    if (!mounted) return;
    setState(() {
      _isAiThinking = false;
    });
    // Use smart scroll to show the context (User Message at top)
    _scrollToBottom(toTrigger: true);
  }

  Widget _buildNewMessagesPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E).withValues(alpha: 0.85),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28.0),
              onTap: () {
                HapticFeedback.lightImpact();
                _acceleratedScrollToBottom();
                setState(() {
                  _showNewMessagesPill = false;
                  _hasNewUnreadMessages = false;
                });
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _hasNewUnreadMessages ? 'New messages' : 'Scroll to bottom',
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
    );
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
    Color? iconColor,
  }) {
    final glassContainer = Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.background.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDotted 
                    ? Colors.white.withValues(alpha: 0.3) 
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
                customBorder: const CircleBorder(),
                splashColor: AppTheme.highlight.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      icon, 
                      key: ValueKey<IconData>(icon),
                      color: iconColor ?? Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (isDotted) {
      return DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          radius: Radius.circular(32),
          color: AppTheme.highlight,
          dashPattern: [6, 4],
          strokeWidth: 1.5,
        ),
        child: glassContainer,
      );
    }

    return glassContainer;
  }
}
