import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_interaction_provider.dart';
import '../../../core/services/voice_command_service.dart';

/// Enhanced Voice Input Widget with Visual Feedback
/// Provides comprehensive voice interaction with animations and status indicators
class EnhancedVoiceInputWidget extends ConsumerStatefulWidget {
  final Function(String)? onVoiceInput;
  final Function(VoiceCommandResult)? onVoiceCommand;
  final VoidCallback? onVoiceStart;
  final VoidCallback? onVoiceStop;
  final bool enabled;
  final bool showWaveform;

  const EnhancedVoiceInputWidget({
    super.key,
    this.onVoiceInput,
    this.onVoiceCommand,
    this.onVoiceStart,
    this.onVoiceStop,
    this.enabled = true,
    this.showWaveform = true,
  });

  @override
  ConsumerState<EnhancedVoiceInputWidget> createState() =>
      _EnhancedVoiceInputWidgetState();
}

class _EnhancedVoiceInputWidgetState
    extends ConsumerState<EnhancedVoiceInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _breatheController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Pulse animation for active listening
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Wave animation for sound visualization
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Breathing animation for idle state
    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
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

    _breatheAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOut,
    ),);

    // Start breathing animation
    _breatheController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInteractionProvider);

    // Update animations based on voice state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAnimations(voiceState);
    });

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer wave rings when listening
          if (voiceState.isListening && widget.showWaveform) ...[
            _buildWaveRing(0, 80, 0.3),
            _buildWaveRing(1, 100, 0.2),
            _buildWaveRing(2, 120, 0.1),
          ],

          // Main voice button
          AnimatedBuilder(
            animation: Listenable.merge([
              _pulseAnimation,
              _breatheAnimation,
            ]),
            builder: (context, child) {
              final scale = voiceState.isListening
                  ? _pulseAnimation.value
                  : _breatheAnimation.value;

              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: widget.enabled ? _handleVoiceButtonTap : null,
                  onLongPress: widget.enabled ? _handleVoiceLongPress : null,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getButtonColor(voiceState),
                      boxShadow: [
                        BoxShadow(
                          color: _getButtonColor(voiceState).withValues(alpha:0.4),
                          blurRadius: voiceState.isListening ? 20 : 10,
                          spreadRadius: voiceState.isListening ? 5 : 2,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha:0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getButtonIcon(voiceState),
                      color: Colors.white,
                      size: 28,
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
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

          // Confidence indicator
          if (voiceState.confidence > 0 && voiceState.recognizedText != null)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(voiceState.confidence),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(voiceState.confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaveRing(int index, double size, double opacity) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        final delay = index * 0.3;
        final animationValue = (_waveAnimation.value + delay) % 1.0;

        return Container(
          width: size + (animationValue * 40),
          height: size + (animationValue * 40),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha:opacity * (1 - animationValue)),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  void _updateAnimations(VoiceInteractionState voiceState) {
    if (voiceState.isListening) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
      _breatheController.stop();
    } else {
      _pulseController.stop();
      _waveController.stop();
      if (!_breatheController.isAnimating) {
        _breatheController.repeat(reverse: true);
      }
    }
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
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
    // Show voice commands help
    _showVoiceCommandsHelp();
  }

  void _showVoiceCommandsHelp() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return VoiceCommandsHelpSheet(scrollController: scrollController);
        },
      ),
    );
  }
}

/// Voice Commands Help Sheet
class VoiceCommandsHelpSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const VoiceCommandsHelpSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);
    final availableCommands = voiceNotifier.getAvailableCommands();
    final availableLanguages = voiceNotifier.getAvailableLanguages();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Voice Commands & Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                // Quick Start Guide
                _buildSection(
                  context,
                  'Quick Start',
                  Icons.play_circle_outline,
                  [
                    'Tap the microphone to start voice input',
                    'Speak clearly and wait for processing',
                    'Your speech will be converted to text',
                    'Long press for voice settings',
                  ],
                ),

                const SizedBox(height: 24),

                // Available Commands
                _buildSection(
                  context,
                  'Available Commands',
                  Icons.list,
                  availableCommands
                      .map((cmd) => '• ${cmd.name}: "${cmd.examples.first}"')
                      .toList(),
                ),

                const SizedBox(height: 24),

                // Language Settings
                Text(
                  'Language Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableLanguages.map((language) {
                    return ChoiceChip(
                      label: Text(language.name),
                      selected: false, // TODO: Track current language
                      onSelected: (selected) {
                        if (selected) {
                          voiceNotifier.setLanguage(language.code);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language set to ${language.name}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Tips
                _buildSection(
                  context,
                  'Tips for Better Recognition',
                  Icons.lightbulb_outline,
                  [
                    'Speak clearly and at normal pace',
                    'Minimize background noise',
                    'Hold device 6-12 inches from mouth',
                    'Use natural language and complete sentences',
                    'Wait for the processing indicator to finish',
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),),
      ],
    );
  }
}

