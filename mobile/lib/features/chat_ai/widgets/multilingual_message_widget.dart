import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/services/multilingual_ai_chat_service.dart';
import '../providers/multilingual_chat_provider.dart';

/// Multilingual Message Widget
/// Displays chat messages with language detection, translation options, and confidence indicators
class MultilingualMessageWidget extends ConsumerStatefulWidget {
  final MultilingualChatMessage message;
  final bool showLanguageIndicator;
  final bool showTranslationOption;
  final bool showConfidence;

  const MultilingualMessageWidget({
    super.key,
    required this.message,
    this.showLanguageIndicator = true,
    this.showTranslationOption = true,
    this.showConfidence = false,
  });

  @override
  ConsumerState<MultilingualMessageWidget> createState() =>
      _MultilingualMessageWidgetState();
}

class _MultilingualMessageWidgetState
    extends ConsumerState<MultilingualMessageWidget>
    with TickerProviderStateMixin {
  bool _showTranslation = false;
  String? _translatedText;
  bool _isTranslating = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final availableLanguages = ref.watch(availableLanguagesProvider);

    final messageLanguage = availableLanguages.firstWhere(
      (lang) => lang.code == widget.message.language,
      orElse: () => availableLanguages.first,
    );

    final isDifferentLanguage = widget.message.language != currentLanguage;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: widget.message.isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.message.isUser) ...[
              _buildAvatar(),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: widget.message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Language indicator
                  if (widget.showLanguageIndicator && isDifferentLanguage)
                    _buildLanguageIndicator(messageLanguage),

                  const SizedBox(height: 4),

                  // Message bubble
                  _buildMessageBubble(isDifferentLanguage),

                  // Translation section
                  if (widget.showTranslationOption && isDifferentLanguage)
                    _buildTranslationSection(),

                  // Confidence indicator
                  if (widget.showConfidence &&
                      widget.message.confidence != null)
                    _buildConfidenceIndicator(),
                ],
              ),
            ),
            if (widget.message.isUser) ...[
              const SizedBox(width: 8),
              _buildAvatar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.message.isUser
            ? Theme.of(context).colorScheme.primary.withValues(alpha:0.1)
            : Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.message.isUser ? Icons.person : Icons.smart_toy,
        color: widget.message.isUser
            ? Theme.of(context).colorScheme.primary
            : Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildLanguageIndicator(LanguageOption language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            language.flag,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            language.nativeName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isDifferentLanguage) {
    final displayText = widget.message.isUser
        ? widget.message.message
        : widget.message.response;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.message.isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomLeft: widget.message.isUser
              ? const Radius.circular(16)
              : const Radius.circular(4),
          bottomRight: widget.message.isUser
              ? const Radius.circular(4)
              : const Radius.circular(16),
        ),
        border: widget.message.isUser
            ? null
            : Border.all(
                color: isDifferentLanguage
                    ? Theme.of(context).colorScheme.primary.withValues(alpha:0.3)
                    : Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
                width: isDifferentLanguage ? 2 : 1,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message text
          Text(
            _showTranslation && _translatedText != null
                ? _translatedText!
                : displayText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.message.isUser
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
          ),

          const SizedBox(height: 4),

          // Timestamp and actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(widget.message.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.message.isUser
                          ? Colors.white.withValues(alpha:0.7)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha:0.5),
                    ),
              ),
              if (!widget.message.isUser) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _speakMessage(displayText),
                  child: Icon(
                    Icons.volume_up,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha:0.5),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isTranslating)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: _toggleTranslation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _showTranslation
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showTranslation
                          ? Icons.translate
                          : Icons.translate_outlined,
                      size: 14,
                      color: _showTranslation
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showTranslation ? 'Original' : 'Translate',
                      style: TextStyle(
                        fontSize: 12,
                        color: _showTranslation
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final confidence = widget.message.confidence ?? 0.0;
    final confidencePercent = (confidence * 100).toInt();

    Color confidenceColor;
    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
    } else if (confidence >= 0.6) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 12,
            color: confidenceColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Confidence: $confidencePercent%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: confidenceColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _toggleTranslation() async {
    if (_showTranslation) {
      setState(() {
        _showTranslation = false;
      });
      return;
    }

    if (_translatedText == null) {
      await _translateMessage();
    } else {
      setState(() {
        _showTranslation = true;
      });
    }
  }

  Future<void> _translateMessage() async {
    setState(() {
      _isTranslating = true;
    });

    try {
      final currentLanguage = ref.read(currentLanguageProvider);
      final notifier = ref.read(multilingualChatProvider.notifier);

      final textToTranslate = widget.message.isUser
          ? widget.message.message
          : widget.message.response;

      final translated = await notifier.translateMessage(
        textToTranslate,
        widget.message.language,
        currentLanguage,
      );

      setState(() {
        _translatedText = translated;
        _showTranslation = true;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _speakMessage(String text) {
    // Implement TTS functionality
    // This would integrate with the voice service
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

/// Language Detection Indicator Widget
class LanguageDetectionIndicator extends ConsumerWidget {
  final double? confidence;
  final String detectedLanguage;

  const LanguageDetectionIndicator({
    super.key,
    this.confidence,
    required this.detectedLanguage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (confidence == null) return const SizedBox.shrink();

    final availableLanguages = ref.watch(availableLanguagesProvider);
    final language = availableLanguages.firstWhere(
      (lang) => lang.code == detectedLanguage,
      orElse: () => availableLanguages.first,
    );

    final confidencePercent = (confidence! * 100).toInt();

    Color indicatorColor;
    if (confidence! >= 0.8) {
      indicatorColor = Colors.green;
    } else if (confidence! >= 0.6) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            language.flag,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            language.code.split('-').first.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: indicatorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.psychology,
            size: 12,
            color: indicatorColor,
          ),
          const SizedBox(width: 2),
          Text(
            '$confidencePercent%',
            style: TextStyle(
              fontSize: 10,
              color: indicatorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Conversation Language Summary Widget
class ConversationLanguageSummary extends ConsumerWidget {
  const ConversationLanguageSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider);
    final availableLanguages = ref.watch(availableLanguagesProvider);

    if (messages.isEmpty) return const SizedBox.shrink();

    // Count messages by language
    final languageCounts = <String, int>{};
    for (final message in messages) {
      languageCounts[message.language] =
          (languageCounts[message.language] ?? 0) + 1;
    }

    // Sort by count
    final sortedLanguages = languageCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversation Languages',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: sortedLanguages.map((entry) {
              final language = availableLanguages.firstWhere(
                (lang) => lang.code == entry.key,
                orElse: () => LanguageOption(
                  code: entry.key,
                  name: entry.key,
                  nativeName: entry.key,
                  flag: '🌐',
                ),
              );

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(language.flag, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      language.nativeName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

