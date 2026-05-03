import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _dotController;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
      child: Row(
        children: [
          FadeTransition(
            opacity: _pulseAnimation,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.highlight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Thinking",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
          AnimatedBuilder(
            animation: _dotController,
            builder: (context, child) {
              int dots = ((_dotController.value * 10) % 7).toInt() + 1;
              return Text(
                "." * dots,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 2.0,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
