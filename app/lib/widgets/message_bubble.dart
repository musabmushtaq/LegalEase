import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';
    
    if (isUser) {
      return _UserMessageCard(message: message);
    } else {
      return _AiDocumentationMessage(message: message);
    }
  }
}

class _UserMessageCard extends StatefulWidget {
  final ChatMessage message;
  const _UserMessageCard({required this.message});

  @override
  State<_UserMessageCard> createState() => _UserMessageCardState();
}

class _UserMessageCardState extends State<_UserMessageCard> with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _offset = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    if (widget.message.isNew) {
      _entranceController.forward();
      widget.message.isNew = false;
    } else {
      _entranceController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String content = widget.message.content;
    final bool hasAttachment = widget.message.localFilePath != null || widget.message.fileId != null;
    final String cleanContent = content.replaceAll('\uFFFC', '').trim();

    // =============================================================
    // VISUAL FINE-CONTROL VARIABLES (Feel free to adjust!)
    // =============================================================
    const double bubbleBorderRadius = 18.0;
    
    // Padding around the text inside the bubble
    const double textTopPadding = 12.0;
    const double textBottomPadding = 12.0;
    const double textHorizontalPadding = 14.0;
    
    // Spacing between the text and the attachment card
    const double textToCardSpacing = 8.0;
    
    // Padding inside the attachment card itself
    const double cardHorizontalPadding = 12.0;
    const double cardVerticalPadding = 10.0;
    
    // Nested corners for the attachment card (top-left & top-right)
    const double cardInnerTopRadius = 12.0;
    
    // Card margins (set to 0.0 for completely flush left/right/bottom)
    const double cardMarginLeft = 0.0;
    const double cardMarginRight = 0.0;
    const double cardMarginBottom = 0.0;
    // =============================================================

    final hasText = cleanContent.isNotEmpty;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 80.0, right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(bubbleBorderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(bubbleBorderRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.0,
                    ),
                  ),
                  padding: EdgeInsets.zero, // Zero out parent padding so child can sit flush!
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasText)
                          Padding(
                            padding: EdgeInsets.only(
                              left: textHorizontalPadding,
                              right: textHorizontalPadding,
                              top: textTopPadding,
                              bottom: hasAttachment ? textToCardSpacing : textBottomPadding,
                            ),
                            child: SelectableText(
                              cleanContent,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        if (hasAttachment)
                          _buildFullWidthAttachment(
                            context,
                            hasText: hasText,
                            cardHorizontalPadding: cardHorizontalPadding,
                            cardVerticalPadding: cardVerticalPadding,
                            cardInnerTopRadius: cardInnerTopRadius,
                            bubbleBorderRadius: bubbleBorderRadius,
                            cardMarginLeft: cardMarginLeft,
                            cardMarginRight: cardMarginRight,
                            cardMarginBottom: cardMarginBottom,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthAttachment(
    BuildContext context, {
    required bool hasText,
    required double cardHorizontalPadding,
    required double cardVerticalPadding,
    required double cardInnerTopRadius,
    required double bubbleBorderRadius,
    required double cardMarginLeft,
    required double cardMarginRight,
    required double cardMarginBottom,
  }) {
    final fileName = widget.message.fileName ?? 'Attachment';
    
    final lowercaseName = fileName.toLowerCase();
    final isImage = lowercaseName.endsWith('.png') ||
                    lowercaseName.endsWith('.jpg') ||
                    lowercaseName.endsWith('.jpeg') ||
                    lowercaseName.endsWith('.gif') ||
                    lowercaseName.endsWith('.webp') ||
                    lowercaseName.endsWith('.bmp');
    
    final IconData attachmentIcon = isImage 
        ? Icons.image_outlined 
        : Icons.insert_drive_file_outlined;
    
    return GestureDetector(
      onTap: () => _handleFileTap(context),
      child: Container(
        constraints: const BoxConstraints(minWidth: 160.0),
        margin: EdgeInsets.only(
          left: cardMarginLeft,
          right: cardMarginRight,
          bottom: cardMarginBottom,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: cardHorizontalPadding,
          vertical: cardVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(hasText ? cardInnerTopRadius : bubbleBorderRadius),
            topRight: Radius.circular(hasText ? cardInnerTopRadius : bubbleBorderRadius),
            bottomLeft: Radius.circular(bubbleBorderRadius),
            bottomRight: Radius.circular(bubbleBorderRadius),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                attachmentIcon,
                color: AppTheme.highlight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160.0),
                child: Text(
                  fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    letterSpacing: 0.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileTap(BuildContext context) async {
    final chatService = context.read<ChatService>();
    
    // 1. Try local file first
    if (widget.message.localFilePath != null) {
      final file = File(widget.message.localFilePath!);
      if (await file.exists()) {
        final result = await OpenFile.open(file.path);
        if (result.type == ResultType.done) return;
      }
    }
    
    // 2. Try download if fileId exists
    if (widget.message.fileId != null) {
      final fileName = widget.message.fileName ?? 'attachment';
      final downloadedFile = await chatService.downloadFile(widget.message.id, widget.message.fileId!, fileName);
      
      if (downloadedFile != null) {
        await OpenFile.open(downloadedFile.path);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download file from server.')),
          );
        }
      }
    }
  }
}

class _AiDocumentationMessage extends StatefulWidget {
  final ChatMessage message;
  const _AiDocumentationMessage({required this.message});

  @override
  State<_AiDocumentationMessage> createState() => _AiDocumentationMessageState();
}

class _AiDocumentationMessageState extends State<_AiDocumentationMessage> with SingleTickerProviderStateMixin {
  bool? _isPositiveFeedback;
  late AnimationController _entranceController;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 1.0, curve: Curves.easeIn)),
    );

    _offset = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    if (widget.message.isNew) {
      _entranceController.forward();
      widget.message.isNew = false;
    } else {
      _entranceController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: widget.message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: AppTheme.textBody,
                    fontSize: 15,
                    height: 1.7,
                    letterSpacing: 0.3,
                  ),
                  h1: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 2.0,
                  ),
                  h2: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.8,
                  ),
                  h3: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                  h4: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  h5: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  h6: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  strong: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    color: AppTheme.textBody.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: const TextStyle(color: AppTheme.highlight, fontSize: 16),
                  blockquote: TextStyle(
                    color: AppTheme.textBody.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    border: const Border(
                      left: BorderSide(
                        color: AppTheme.highlight,
                        width: 4.0,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                  ),
                  blockquotePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  tableHead: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tableBody: const TextStyle(
                    color: AppTheme.textBody,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  tableBorder: TableBorder.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                  tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  code: TextStyle(
                    color: AppTheme.highlight,
                    backgroundColor: Colors.transparent,
                    fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  codeblockPadding: const EdgeInsets.all(12.0),
                ),
              ),
              const SizedBox(height: 24),
              _buildActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        _ActionButton(
          icon: _isPositiveFeedback == true ? Icons.thumb_up : Icons.thumb_up_outlined,
          color: _isPositiveFeedback == true ? AppTheme.highlight : Colors.white24,
          onPressed: () => setState(() => _isPositiveFeedback = _isPositiveFeedback == true ? null : true),
        ),
        _ActionButton(
          icon: _isPositiveFeedback == false ? Icons.thumb_down : Icons.thumb_down_outlined,
          color: _isPositiveFeedback == false ? Colors.redAccent.withValues(alpha: 0.6) : Colors.white24,
          onPressed: () => setState(() => _isPositiveFeedback = _isPositiveFeedback == false ? null : false),
        ),
        _ActionButton(
          icon: Icons.content_copy_outlined,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.message.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
            );
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white24,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(right: 4),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
