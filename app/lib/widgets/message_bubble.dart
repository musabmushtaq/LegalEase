import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';
    final shouldAnimate = message.isNew && message.sender == 'ai';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.highlight : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.localFilePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(message.localFilePath!),
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.insert_drive_file,
                          color: Colors.white70,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8.0),
            ],
            shouldAnimate
                ? _FadeSlideText(
                    message.content,
                    style: TextStyle(
                      color: AppTheme.textBody,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    duration: const Duration(milliseconds: 600),
                    shouldAnimate: true,
                  )
                : Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? AppTheme.background : AppTheme.textBody,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _FadeSlideText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final bool shouldAnimate;

  const _FadeSlideText(
    this.text, {
    required this.style,
    required this.duration,
    this.shouldAnimate = true,
  });

  @override
  State<_FadeSlideText> createState() => _FadeSlideTextState();
}

class _FadeSlideTextState extends State<_FadeSlideText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.shouldAnimate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shouldAnimate) {
      return Text(widget.text, style: widget.style);
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}
