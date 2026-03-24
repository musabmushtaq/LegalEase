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
        child: shouldAnimate
            ? _TypewriterText(
                message.content,
                style: TextStyle(
                  color: AppTheme.textBody,
                  fontSize: 15,
                  height: 1.4,
                ),
                duration: const Duration(milliseconds: 10),
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
      ),
    );
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final bool shouldAnimate;

  const _TypewriterText(
    this.text, {
    required this.style,
    required this.duration,
    this.shouldAnimate = true,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration * widget.text.length,
      vsync: this,
    );
    _charCount = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(_controller);

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

    return AnimatedBuilder(
      animation: _charCount,
      builder: (context, child) {
        final displayText = widget.text.substring(0, _charCount.value);
        return Text(displayText, style: widget.style);
      },
    );
  }
}
