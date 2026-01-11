import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_interaction_provider.dart';

/// Voice Message Widget
/// Displays voice messages with playback controls and waveform visualization
class VoiceMessageWidget extends ConsumerStatefulWidget {
  final String text;
  final Duration? duration;
  final bool isUser;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final bool autoPlay;
  final String? language;
  final double? confidence;
  final bool showTranslation;
  final bool showSentiment;
  final VoidCallback? onTranslate;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const VoiceMessageWidget({
    super.key,
    required this.text,
    this.duration,
    required this.isUser,
    this.onPlay,
    this.onPause,
    this.autoPlay = false,
    this.language,
    this.confidence,
    this.showTranslation = false,
    this.showSentiment = false,
    this.onTranslate,
    this.onShare,
    this.onDelete,
  });

  @override
  ConsumerState<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends ConsumerState<VoiceMessageWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  bool _isPlaying = false;
  bool _showControls = false;
  String? _translatedText;
  String? _sentiment;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Analyze sentiment if enabled
    if (widget.showSentiment) {
      _analyzeSentiment();
    }

    if (widget.autoPlay && !widget.isUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playMessage();
      });
    }
  }

  void _setupAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInteractionProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isUser
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomLeft: widget.isUser
              ? const Radius.circular(16)
              : const Radius.circular(4),
          bottomRight: widget.isUser
              ? const Radius.circular(4)
              : const Radius.circular(16),
        ),
        border: widget.isUser
            ? null
            : Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice message header with enhanced info
          Row(
            children: [
              Icon(
                Icons.mic,
                size: 16,
                color: widget.isUser
                    ? Colors.white.withValues(alpha: 0.8)
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Voice Message',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isUser
                      ? Colors.white.withValues(alpha: 0.8)
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.language != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isUser
                        ? Colors.white.withValues(alpha: 0.2)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.language!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isUser
                          ? Colors.white.withValues(alpha: 0.8)
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (widget.confidence != null) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.confidence! > 0.8 ? Icons.verified : Icons.warning,
                  size: 12,
                  color:
                      widget.confidence! > 0.8 ? Colors.green : Colors.orange,
                ),
              ],
              const Spacer(),
              if (widget.duration != null) ...[
                Text(
                  _formatDuration(widget.duration!),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isUser
                        ? Colors.white.withValues(alpha: 0.6)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                  ),
                ),
              ],
              IconButton(
                icon: Icon(
                  _showControls ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: widget.isUser
                      ? Colors.white.withValues(alpha: 0.6)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                ),
                onPressed: () => setState(() => _showControls = !_showControls),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // Sentiment indicator
          if (widget.showSentiment && _sentiment != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getSentimentIcon(_sentiment!),
                  size: 12,
                  color: _getSentimentColor(_sentiment!),
                ),
                const SizedBox(width: 4),
                Text(
                  _sentiment!,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getSentimentColor(_sentiment!),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Waveform visualization
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlayback,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.isUser
                        ? Colors.white.withValues(alpha: 0.2)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying || voiceState.isSpeaking
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 18,
                    color: widget.isUser
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Waveform bars
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(20, (index) {
                      return AnimatedBuilder(
                        animation: _waveAnimation,
                        builder: (context, child) {
                          final height = _isPlaying || voiceState.isSpeaking
                              ? _getWaveHeight(index, _waveAnimation.value)
                              : _getStaticWaveHeight(index);

                          return Container(
                            width: 2,
                            height: height,
                            decoration: BoxDecoration(
                              color: widget.isUser
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Transcribed text
          Text(
            widget.text,
            style: TextStyle(
              color: widget.isUser
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),

          // Translation
          if (_translatedText != null && _translatedText != widget.text) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isUser
                    ? Colors.white.withValues(alpha: 0.1)
                    : Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.translate,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Translation',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _translatedText!,
                    style: TextStyle(
                      color: widget.isUser
                          ? Colors.white.withValues(alpha: 0.9)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.8),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Enhanced controls
          if (_showControls) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Speed control
                PopupMenuButton<double>(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isUser
                          ? Colors.white.withValues(alpha: 0.2)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.speed,
                          size: 14,
                          color: widget.isUser
                              ? Colors.white.withValues(alpha: 0.8)
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_playbackSpeed}x',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isUser
                                ? Colors.white.withValues(alpha: 0.8)
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onSelected: (speed) => setState(() => _playbackSpeed = speed),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                    const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                    const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                    const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                    const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                    const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                  ],
                ),

                // Translate button
                if (widget.onTranslate != null)
                  IconButton(
                    icon: Icon(
                      Icons.translate,
                      size: 18,
                      color: widget.isUser
                          ? Colors.white.withValues(alpha: 0.8)
                          : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () async {
                      await _translateMessage();
                      widget.onTranslate?.call();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                // Share button
                if (widget.onShare != null)
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      size: 18,
                      color: widget.isUser
                          ? Colors.white.withValues(alpha: 0.8)
                          : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: widget.onShare,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                // Delete button
                if (widget.onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red.withValues(alpha: 0.8),
                    ),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double _getWaveHeight(int index, double animationValue) {
    // Create a wave pattern that moves across the bars
    final phase = (animationValue * 2 * 3.14159) + (index * 0.3);
    final baseHeight = 8.0;
    final amplitude = 16.0;
    return baseHeight + (amplitude * (0.5 + 0.5 * sin(phase)));
  }

  double _getStaticWaveHeight(int index) {
    // Static wave pattern based on text content
    final textHash = widget.text.hashCode;
    final height = 8.0 + ((textHash + index) % 20).toDouble();
    return height.clamp(4.0, 24.0);
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _pauseMessage();
    } else {
      _playMessage();
    }
  }

  void _playMessage() {
    setState(() {
      _isPlaying = true;
    });

    _waveController.repeat();

    // Use TTS to speak the message
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);
    voiceNotifier.speakResponse(widget.text);

    widget.onPlay?.call();

    // Auto-stop after estimated duration
    final estimatedDuration = widget.duration ??
        Duration(milliseconds: widget.text.length * 100); // Rough estimate

    Future.delayed(estimatedDuration, () {
      if (mounted) {
        _pauseMessage();
      }
    });
  }

  void _pauseMessage() {
    setState(() {
      _isPlaying = false;
    });

    _waveController.stop();

    // Stop TTS
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);
    voiceNotifier.stopSpeaking();

    widget.onPause?.call();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Icons.sentiment_satisfied;
      case 'negative':
        return Icons.sentiment_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _analyzeSentiment() {
    // Simple sentiment analysis based on keywords
    final text = widget.text.toLowerCase();
    if (text.contains('good') ||
        text.contains('great') ||
        text.contains('excellent') ||
        text.contains('happy')) {
      _sentiment = 'Positive';
    } else if (text.contains('bad') ||
        text.contains('terrible') ||
        text.contains('angry') ||
        text.contains('sad')) {
      _sentiment = 'Negative';
    } else {
      _sentiment = 'Neutral';
    }
  }

  Future<void> _translateMessage() async {
    // Mock translation - in real implementation, use translation service
    if (widget.language != null && widget.language != 'en') {
      _translatedText = '[Translated from ${widget.language}]: ${widget.text}';
    } else {
      _translatedText = widget.text;
    }
    setState(() {});
  }
}

/// Voice Recording Widget
/// Shows recording status and waveform during voice input
class VoiceRecordingWidget extends ConsumerStatefulWidget {
  final VoidCallback? onStop;
  final Function(String)? onComplete;

  const VoiceRecordingWidget({
    super.key,
    this.onStop,
    this.onComplete,
  });

  @override
  ConsumerState<VoiceRecordingWidget> createState() =>
      _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends ConsumerState<VoiceRecordingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInteractionProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'Recording...',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  widget.onStop?.call();
                  final voiceNotifier =
                      ref.read(voiceInteractionProvider.notifier);
                  voiceNotifier.stopVoiceInput();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Waveform visualization
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(30, (index) {
                return AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    final height =
                        _getRecordingWaveHeight(index, _waveAnimation.value);

                    return Container(
                      width: 3,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          const SizedBox(height: 12),

          // Recognized text preview
          if (voiceState.recognizedText != null &&
              voiceState.recognizedText!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                voiceState.recognizedText!,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _getRecordingWaveHeight(int index, double animationValue) {
    // Simulate real-time audio levels
    final phase = (animationValue * 4 * 3.14159) + (index * 0.2);
    final baseHeight = 8.0;
    final amplitude = 24.0;
    final randomFactor = (index * 17) % 100 / 100.0; // Pseudo-random
    return baseHeight + (amplitude * randomFactor * (0.5 + 0.5 * sin(phase)));
  }
}

/// Voice Command Suggestions Widget
/// Shows contextual voice command suggestions during recording
class VoiceCommandSuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final Function(String)? onSuggestionSelected;

  const VoiceCommandSuggestionsWidget({
    super.key,
    required this.suggestions,
    this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice Command Suggestions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return GestureDetector(
                onTap: () => onSuggestionSelected?.call(suggestion),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Enhanced Voice Recording Widget with Suggestions
class EnhancedVoiceRecordingWidget extends ConsumerStatefulWidget {
  final VoidCallback? onStop;
  final Function(String)? onComplete;
  final List<String> suggestions;

  const EnhancedVoiceRecordingWidget({
    super.key,
    this.onStop,
    this.onComplete,
    this.suggestions = const [],
  });

  @override
  ConsumerState<EnhancedVoiceRecordingWidget> createState() =>
      _EnhancedVoiceRecordingWidgetState();
}

class _EnhancedVoiceRecordingWidgetState
    extends ConsumerState<EnhancedVoiceRecordingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  Timer? _suggestionTimer;
  List<String> _currentSuggestions = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _startSuggestionUpdates();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  void _startSuggestionUpdates() {
    _suggestionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          // Rotate through different suggestion categories
          final categories = [
            ['Check vehicle health', 'Show fuel level', 'Check alerts'],
            ['Navigate to home', 'Find service center', 'Schedule maintenance'],
            ['Turn on AC', 'Lock doors', 'Start engine'],
          ];
          final randomCategory = categories[(timer.tick % categories.length)];
          _currentSuggestions = randomCategory;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInteractionProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recording indicator
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Recording...',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      widget.onStop?.call();
                      final voiceNotifier =
                          ref.read(voiceInteractionProvider.notifier);
                      voiceNotifier.stopVoiceInput();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Waveform visualization
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(30, (index) {
                    return AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        final height = _getRecordingWaveHeight(
                          index,
                          _waveAnimation.value,
                        );

                        return Container(
                          width: 3,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),

              // Recognized text preview
              if (voiceState.recognizedText != null &&
                  voiceState.recognizedText!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    voiceState.recognizedText!,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Voice command suggestions
        if (_currentSuggestions.isNotEmpty)
          VoiceCommandSuggestionsWidget(
            suggestions: _currentSuggestions,
            onSuggestionSelected: (suggestion) {
              // Handle suggestion selection
              widget.onComplete?.call(suggestion);
            },
          ),
      ],
    );
  }

  double _getRecordingWaveHeight(int index, double animationValue) {
    // Simulate real-time audio levels
    final phase = (animationValue * 4 * 3.14159) + (index * 0.2);
    final baseHeight = 8.0;
    final amplitude = 24.0;
    final randomFactor = (index * 17) % 100 / 100.0; // Pseudo-random
    return baseHeight + (amplitude * randomFactor * (0.5 + 0.5 * sin(phase)));
  }
}

