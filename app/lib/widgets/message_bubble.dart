import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat.dart';
import '../theme/app_theme.dart';

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
  bool _isExpanded = false;
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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(top: 12.0, bottom: 12.0, left: 80.0, right: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18.0),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.message.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                        maxLines: _isExpanded ? null : 4,
                        overflow: _isExpanded ? null : TextOverflow.ellipsis,
                      ),
                      if (widget.message.content.length > 150)
                        GestureDetector(
                          onTap: () => setState(() => _isExpanded = !_isExpanded),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              _isExpanded ? "COLLAPSE" : "READ MORE",
                              style: TextStyle(
                                color: AppTheme.highlight.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      if (widget.message.localFilePath != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(widget.message.localFilePath!),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                  strong: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: const TextStyle(color: AppTheme.highlight, fontSize: 16),
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
