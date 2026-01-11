import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/chat_models.dart';

/// Chat message widget with enhanced styling
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSpeak;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(context, false),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(context),
                const SizedBox(height: 4),
                _buildMessageActions(context),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            _buildAvatar(context, true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.8),
                ],
              )
            : LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
        borderRadius: BorderRadius.circular(18),
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
        color: message.isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: message.isUser
              ? const Radius.circular(20)
              : const Radius.circular(4),
          bottomRight: message.isUser
              ? const Radius.circular(4)
              : const Radius.circular(20),
        ),
        border: message.isUser
            ? null
            : Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageContent(context),
          const SizedBox(height: 8),
          _buildTimestamp(context),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Handle different message types
    switch (message.type) {
      case MessageType.text:
        return _buildTextContent(context);
      case MessageType.voice:
        return _buildVoiceContent(context);
      case MessageType.vehicleData:
        return _buildVehicleDataContent(context);
      case MessageType.recommendation:
        return _buildRecommendationContent(context);
      default:
        return _buildTextContent(context);
    }
  }

  Widget _buildTextContent(BuildContext context) {
    return SelectableText(
      message.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: message.isUser
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            height: 1.4,
          ),
    );
  }

  Widget _buildVoiceContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.volume_up,
          size: 20,
          color: message.isUser
              ? Colors.white.withValues(alpha: 0.8)
              : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: message.isUser
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDataContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isUser
            ? Colors.white.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                size: 16,
                color: message.isUser
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Vehicle Data',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: message.isUser
                          ? Colors.white.withValues(alpha: 0.8)
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: message.isUser
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommendation',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    return Text(
      _formatTime(message.timestamp),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: message.isUser
                ? Colors.white.withValues(alpha: 0.7)
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
            fontSize: 11,
          ),
    );
  }

  Widget _buildMessageActions(BuildContext context) {
    if (message.isUser) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          Icons.content_copy,
          'Copy',
          () => _copyMessage(context),
        ),
        const SizedBox(width: 8),
        if (onSpeak != null)
          _buildActionButton(
            context,
            Icons.volume_up,
            'Speak',
            onSpeak!,
          ),
        const SizedBox(width: 8),
        _buildActionButton(
          context,
          Icons.thumb_up_outlined,
          'Like',
          () => _likeMessage(context),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _likeMessage(BuildContext context) {
    // TODO: Implement message rating/feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanks for your feedback!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

