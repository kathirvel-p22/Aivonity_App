import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';

/// AIVONITY Typing Indicator Widget
/// Animated dots showing AI is typing
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // AI Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),

          const SizedBox(width: 12),

          // Typing Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(context, 0),
                const SizedBox(width: 4),
                _buildDot(context, 1),
                const SizedBox(width: 4),
                _buildDot(context, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(BuildContext context, int index) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha:0.6),
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(
          delay: Duration(milliseconds: index * 200),
          duration: 600.ms,
        )
        .then()
        .fadeOut(duration: 600.ms);
  }
}

