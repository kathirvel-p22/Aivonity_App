import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_interaction_provider.dart';

/// Enhanced Voice Interaction Widget
/// Provides comprehensive voice input and output capabilities for AI chat
class VoiceInteractionWidget extends ConsumerStatefulWidget {
  final Function(String)? onVoiceInput;
  final VoidCallback? onVoiceStart;
  final VoidCallback? onVoiceStop;
  final bool enabled;

  const VoiceInteractionWidget({
    super.key,
    this.onVoiceInput,
    this.onVoiceStart,
    this.onVoiceStop,
    this.enabled = true,
  });

  @override
  ConsumerState<VoiceInteractionWidget> createState() =>
      _VoiceInteractionWidgetState();
}

class _VoiceInteractionWidgetState extends ConsumerState<VoiceInteractionWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
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
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ),);

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ),);
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
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);

    // Update animations based on voice state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (voiceState.isListening) {
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
      } else {
        _pulseController.stop();
        _waveController.stop();
      }
    });

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated waves when listening
          if (voiceState.isListening) ...[
            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Container(
                  width: 60 + (_waveAnimation.value * 20),
                  height: 60 + (_waveAnimation.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha:0.3 - (_waveAnimation.value * 0.3)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          ],

          // Main voice button
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: voiceState.isListening ? _pulseAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: widget.enabled ? _handleVoiceButtonTap : null,
                  onLongPress: widget.enabled ? _handleVoiceLongPress : null,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getButtonColor(voiceState),
                      boxShadow: [
                        BoxShadow(
                          color: _getButtonColor(voiceState).withValues(alpha:0.3),
                          blurRadius: voiceState.isListening ? 15 : 8,
                          spreadRadius: voiceState.isListening ? 3 : 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getButtonIcon(voiceState),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),

          // Processing indicator
          if (voiceState.isProcessing)
            Positioned.fill(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getButtonColor(VoiceInteractionState state) {
    if (!widget.enabled) {
      return Colors.grey;
    }

    if (state.isListening) {
      return Colors.red;
    } else if (state.isSpeaking) {
      return Colors.blue;
    } else if (state.isProcessing) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getButtonIcon(VoiceInteractionState state) {
    if (state.isListening) {
      return Icons.stop;
    } else if (state.isSpeaking) {
      return Icons.volume_up;
    } else if (state.isProcessing) {
      return Icons.hourglass_empty;
    } else {
      return Icons.mic;
    }
  }

  void _handleVoiceButtonTap() async {
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);
    final voiceState = ref.read(voiceInteractionProvider);

    if (voiceState.isListening) {
      // Stop listening
      await voiceNotifier.stopVoiceInput();
      widget.onVoiceStop?.call();
    } else if (voiceState.isSpeaking) {
      // Stop speaking
      await voiceNotifier.stopSpeaking();
    } else {
      // Start voice input
      widget.onVoiceStart?.call();
      await voiceNotifier.startVoiceInput();

      // Handle the recognized text
      final updatedState = ref.read(voiceInteractionProvider);
      if (updatedState.recognizedText != null &&
          updatedState.recognizedText!.isNotEmpty) {
        widget.onVoiceInput?.call(updatedState.recognizedText!);
      }
    }
  }

  void _handleVoiceLongPress() {
    // Show voice settings or commands
    _showVoiceOptions();
  }

  void _showVoiceOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const VoiceOptionsBottomSheet(),
    );
  }
}

/// Voice Options Bottom Sheet
class VoiceOptionsBottomSheet extends ConsumerWidget {
  const VoiceOptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);
    final availableLanguages = voiceNotifier.getAvailableLanguages();
    final availableCommands = voiceNotifier.getAvailableCommands();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Language Selection
          Text(
            'Language',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableLanguages.length,
              itemBuilder: (context, index) {
                final language = availableLanguages[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(language.name),
                    selected: false, // TODO: Track current language
                    onSelected: (selected) {
                      if (selected) {
                        voiceNotifier.setLanguage(language.code);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Available Commands
          Text(
            'Available Voice Commands',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...availableCommands.take(5).map((command) => ListTile(
                leading: const Icon(Icons.mic),
                title: Text(command.name),
                subtitle: Text(command.examples.first),
                dense: true,
              ),),

          const SizedBox(height: 16),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

