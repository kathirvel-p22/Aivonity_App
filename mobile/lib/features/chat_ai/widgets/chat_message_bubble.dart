import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';

/// AIVONITY Chat Message Bubble Widget
/// Animated message bubble with contextual actions
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final VoidCallback? onSpeakTap;
  final VoidCallback? onCopyTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.onSpeakTap,
    this.onCopyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(context), const SizedBox(width: 12)],

          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(context),
                if (!isUser) _buildActionButtons(context),
              ],
            ),
          ),

          if (isUser) ...[const SizedBox(width: 12), _buildAvatar(context)],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.secondary.withValues(alpha:0.7),
                ],
              )
            : AppTheme.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                ],
              )
            : null,
        color: isUser ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isUser
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isUser
                      ? Colors.white.withValues(alpha:0.7)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha:0.5),
                  fontSize: 11,
                ),
              ),

              if (message.isDelivered) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check,
                  size: 12,
                  color: isUser ? Colors.white.withValues(alpha:0.7) : Colors.green,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onSpeakTap != null)
            _buildActionButton(
              context,
              icon: Icons.volume_up,
              onTap: onSpeakTap!,
              tooltip: 'Speak',
            ),

          if (onSpeakTap != null && onCopyTap != null) const SizedBox(width: 8),

          if (onCopyTap != null)
            _buildActionButton(
              context,
              icon: Icons.copy,
              onTap: onCopyTap!,
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.8, 0.8));
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

