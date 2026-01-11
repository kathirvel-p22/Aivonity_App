import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_interaction_provider.dart';

/// Voice input widget with animated recording indicator
class VoiceInputWidget extends ConsumerStatefulWidget {
  final Function(String)? onVoiceResult;
  final bool enabled;

  const VoiceInputWidget({
    super.key,
    this.onVoiceResult,
    this.enabled = true,
  });

  @override
  ConsumerState<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends ConsumerState<VoiceInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
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

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VoiceInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animation updates will be handled by listening to provider state
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
    _pulseController.reset();
    _waveController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInteractionProvider);
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);

    // Update animations based on voice state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (voiceState.isListening && !_pulseController.isAnimating) {
        _startAnimations();
      } else if (!voiceState.isListening && _pulseController.isAnimating) {
        _stopAnimations();
      }
    });

    // Handle voice result callback
    if (voiceState.recognizedText != null &&
        voiceState.recognizedText!.isNotEmpty &&
        widget.onVoiceResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVoiceResult!(voiceState.recognizedText!);
      });
    }

    return GestureDetector(
      onTap: widget.enabled ? () => voiceNotifier.toggleVoiceInput() : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: voiceState.isListening
              ? Colors.red
              : widget.enabled
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.3),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated waves when listening
            if (voiceState.isListening) ...[
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return Container(
                    width: 48 + (20 * _waveAnimation.value),
                    height: 48 + (20 * _waveAnimation.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withValues(
                          alpha: 0.3 * (1 - _waveAnimation.value),
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  final delayedValue =
                      (_waveAnimation.value - 0.3).clamp(0.0, 1.0);
                  return Container(
                    width: 48 + (30 * delayedValue),
                    height: 48 + (30 * delayedValue),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red
                            .withValues(alpha: 0.2 * (1 - delayedValue)),
                        width: 1,
                      ),
                    ),
                  );
                },
              ),
            ],

            // Main button with pulse animation
            AnimatedBuilder(
              animation: voiceState.isListening
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return Transform.scale(
                  scale: voiceState.isListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: voiceState.isListening
                          ? Colors.red
                          : widget.enabled
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.3),
                      boxShadow: voiceState.isListening
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          voiceState.isListening ? Icons.stop : Icons.mic,
                          color: voiceState.isListening
                              ? Colors.white
                              : widget.enabled
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                          size: 24,
                        ),
                        // Processing indicator
                        if (voiceState.isProcessing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Recording indicator dots
            if (voiceState.isListening)
              Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        final delay = index * 0.2;
                        final animationValue =
                            (_waveController.value - delay).clamp(0.0, 1.0);
                        final opacity = (animationValue * 2).clamp(0.0, 1.0);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

