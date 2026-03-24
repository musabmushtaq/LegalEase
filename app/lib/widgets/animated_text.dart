import 'package:flutter/material.dart';

class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final bool shouldAnimate;

  const AnimatedText(
    this.text, {
    super.key,
    required this.style,
    this.duration = const Duration(milliseconds: 50),
    this.shouldAnimate = true,
  });

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();

    if (widget.shouldAnimate) {
      _controller = AnimationController(
        duration: widget.duration * widget.text.length,
        vsync: this,
      );

      _charCount = StepTween(
        begin: 0,
        end: widget.text.length,
      ).animate(_controller);

      _controller.forward();
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
