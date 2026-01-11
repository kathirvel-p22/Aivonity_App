import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/multilingual_ai_chat_service.dart';

/// Advanced Chat Bubble Widget
/// Modern chat bubble with rich formatting, actions, and animations
class AdvancedChatBubble extends ConsumerStatefulWidget {
  final MultilingualChatMessage message;
  final bool showAvatar;
  final bool showTimestamp;
  final bool showActions;
  final VoidCallback? onRetry;
  final Function(String)? onCopy;
  final Function(String)? onSpeak;
  final Function(String)? onTranslate;

  const AdvancedChatBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.showActions = true,
    this.onRetry,
    this.onCopy,
    this.onSpeak,
    this.onTranslate,
  });

  @override
  ConsumerState<AdvancedChatBubble> createState() => _AdvancedChatBubbleState();
}

class _AdvancedChatBubbleState extends ConsumerState<AdvancedChatBubble>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _showActions = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startEntryAnimation();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.message.isUser
          ? const Offset(1.0, 0.0)
          : const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ),);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ),);
  }

  void _startEntryAnimation() {
    Future.delayed(Duration(milliseconds: widget.message.isUser ? 0 : 300), () {
      if (mounted) {
        _slideController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: widget.message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.message.isUser && widget.showAvatar) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: _toggleActions,
                  onTap: () {
                    if (_showActions) {
                      setState(() => _showActions = false);
                    }
                  },
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHovered = true),
                    onExit: (_) => setState(() => _isHovered = false),
                    child: Column(
                      crossAxisAlignment: widget.message.isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        _buildMessageBubble(),
                        if (_showActions || _isHovered) _buildActionBar(),
                        if (widget.showTimestamp) _buildTimestamp(),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.message.isUser && widget.showAvatar) ...[
                const SizedBox(width: 8),
                _buildAvatar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Hero(
      tag: 'avatar_${widget.message.isUser ? 'user' : 'ai'}',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: widget.message.isUser
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha:0.7),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.secondary.withValues(alpha:0.7),
                  ],
                ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (widget.message.isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary)
                  .withValues(alpha:0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          widget.message.isUser ? Icons.person : Icons.smart_toy,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMessageBubble() {
    final displayText = widget.message.isUser
        ? widget.message.message
        : widget.message.response;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        gradient: widget.message.isUser
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: widget.message.isUser
            ? null
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: widget.message.isUser
              ? const Radius.circular(20)
              : const Radius.circular(4),
          bottomRight: widget.message.isUser
              ? const Radius.circular(4)
              : const Radius.circular(20),
        ),
        border: widget.message.isUser
            ? null
            : Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageContent(displayText),
          if (widget.message.metadata != null) _buildMetadata(),
        ],
      ),
    );
  }

  Widget _buildMessageContent(String text) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: widget.message.isUser
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
        children: _parseMessageContent(text),
      ),
    );
  }

  List<TextSpan> _parseMessageContent(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*|__(.*?)__|`(.*?)`|•\s*(.*?)(?=\n|$)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Add formatted text
      if (match.group(1) != null) {
        // Bold text **text**
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),);
      } else if (match.group(2) != null) {
        // Italic text __text__
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),);
      } else if (match.group(3) != null) {
        // Code text `text`
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor:
                Theme.of(context).colorScheme.surface.withValues(alpha:0.3),
          ),
        ),);
      } else if (match.group(4) != null) {
        // Bullet point • text
        spans.add(TextSpan(
          text: '• ${match.group(4)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),);
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans.isNotEmpty ? spans : [TextSpan(text: text)];
  }

  Widget _buildMetadata() {
    final metadata = widget.message.metadata;
    if (metadata == null || metadata.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (metadata.containsKey('vehicle_context'))
            _buildMetadataChip(
              Icons.directions_car,
              'Vehicle Data',
              Theme.of(context).colorScheme.primary,
            ),
          if (metadata.containsKey('translated_response'))
            _buildMetadataChip(
              Icons.translate,
              'Translated',
              Colors.blue,
            ),
          if (widget.message.confidence != null &&
              widget.message.confidence! < 0.8)
            _buildMetadataChip(
              Icons.warning_amber,
              'Low Confidence',
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            Icons.copy,
            'Copy',
            () => _copyMessage(),
          ),
          if (!widget.message.isUser) ...[
            _buildActionButton(
              Icons.volume_up,
              'Speak',
              () => widget.onSpeak?.call(widget.message.response),
            ),
            _buildActionButton(
              Icons.translate,
              'Translate',
              () => widget.onTranslate?.call(widget.message.response),
            ),
          ],
          if (widget.message.isUser && widget.onRetry != null)
            _buildActionButton(
              Icons.refresh,
              'Retry',
              widget.onRetry!,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha:0.3),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        _formatTime(widget.message.timestamp),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
              fontSize: 11,
            ),
      ),
    );
  }

  void _toggleActions() {
    setState(() {
      _showActions = !_showActions;
    });
  }

  void _copyMessage() {
    final text = widget.message.isUser
        ? widget.message.message
        : widget.message.response;

    Clipboard.setData(ClipboardData(text: text));
    widget.onCopy?.call(text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

