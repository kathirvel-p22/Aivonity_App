import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_interaction_provider.dart';
import '../../../core/services/integrated_voice_service.dart';
import '../../../core/services/voice_command_service.dart';

/// Voice Settings Widget
/// Provides comprehensive voice interaction settings and preferences
class VoiceSettingsWidget extends ConsumerStatefulWidget {
  const VoiceSettingsWidget({super.key});

  @override
  ConsumerState<VoiceSettingsWidget> createState() =>
      _VoiceSettingsWidgetState();
}

class _VoiceSettingsWidgetState extends ConsumerState<VoiceSettingsWidget> {
  String _selectedLanguage = 'en-US';
  VoiceInteractionMode _selectedMode = VoiceInteractionMode.conversational;
  double _speechRate = 1.0;
  double _pitch = 0.0;
  double _volume = 1.0;
  bool _autoSpeak = true;
  bool _wakeWordEnabled = false;

  @override
  Widget build(BuildContext context) {
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);
    final availableLanguages = voiceNotifier.getAvailableLanguages();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Selection
          _buildSection(
            'Language & Region',
            Icons.language,
            [
              _buildLanguageSelector(availableLanguages, voiceNotifier),
            ],
          ),

          const SizedBox(height: 24),

          // Voice Mode
          _buildSection(
            'Interaction Mode',
            Icons.chat,
            [
              _buildModeSelector(),
            ],
          ),

          const SizedBox(height: 24),

          // Speech Settings
          _buildSection(
            'Speech Settings',
            Icons.record_voice_over,
            [
              _buildSliderSetting(
                'Speech Rate',
                _speechRate,
                0.5,
                2.0,
                (value) {
                  setState(() {
                    _speechRate = value;
                  });
                  _updateSpeechSettings();
                },
                '${(_speechRate * 100).toInt()}%',
              ),
              _buildSliderSetting(
                'Pitch',
                _pitch,
                -1.0,
                1.0,
                (value) {
                  setState(() {
                    _pitch = value;
                  });
                  _updateSpeechSettings();
                },
                _pitch == 0 ? 'Normal' : (_pitch > 0 ? 'Higher' : 'Lower'),
              ),
              _buildSliderSetting(
                'Volume',
                _volume,
                0.0,
                1.0,
                (value) {
                  setState(() {
                    _volume = value;
                  });
                  _updateSpeechSettings();
                },
                '${(_volume * 100).toInt()}%',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Behavior Settings
          _buildSection(
            'Behavior',
            Icons.settings,
            [
              _buildSwitchSetting(
                'Auto-speak AI responses',
                'Automatically speak AI responses aloud',
                _autoSpeak,
                (value) {
                  setState(() {
                    _autoSpeak = value;
                  });
                },
              ),
              _buildSwitchSetting(
                'Wake word detection',
                'Listen for "Hey AIVONITY" to start voice input',
                _wakeWordEnabled,
                (value) {
                  setState(() {
                    _wakeWordEnabled = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Test Voice
          _buildSection(
            'Test Voice',
            Icons.play_circle,
            [
              _buildTestVoiceButton(),
            ],
          ),

          const SizedBox(height: 24),

          // Voice Commands Help
          _buildSection(
            'Voice Commands',
            Icons.help_outline,
            [
              _buildVoiceCommandsHelp(voiceNotifier),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildLanguageSelector(
    List<VoiceLanguage> languages,
    VoiceInteractionNotifier voiceNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            'Select Language',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages.map((language) {
              final isSelected = _selectedLanguage == language.code;
              return ChoiceChip(
                label: Text(language.name),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedLanguage = language.code;
                    });
                    voiceNotifier.setLanguage(language.code);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            'Voice Interaction Mode',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...VoiceInteractionMode.values.map((mode) {
            return RadioListTile<VoiceInteractionMode>(
              title: Text(_getModeTitle(mode)),
              subtitle: Text(_getModeDescription(mode)),
              value: mode,
              groupValue: _selectedMode,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMode = value;
                  });
                  final voiceNotifier =
                      ref.read(voiceInteractionProvider.notifier);
                  voiceNotifier.setVoiceMode(value);
                }
              },
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String displayValue,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                displayValue,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTestVoiceButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Test your voice settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _testVoice,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Test Voice'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCommandsHelp(VoiceInteractionNotifier voiceNotifier) {
    final commands = voiceNotifier.getAvailableCommands();

    return Container(
      padding: const EdgeInsets.all(16),
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
            'Available Voice Commands',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...commands.take(5).map((command) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.mic,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            command.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Example: "${command.examples.first}"',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha:0.7),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showAllCommands(commands),
            child: const Text('View All Commands'),
          ),
        ],
      ),
    );
  }

  String _getModeTitle(VoiceInteractionMode mode) {
    switch (mode) {
      case VoiceInteractionMode.conversational:
        return 'Conversational';
      case VoiceInteractionMode.command:
        return 'Command Mode';
      case VoiceInteractionMode.dictation:
        return 'Dictation';
    }
  }

  String _getModeDescription(VoiceInteractionMode mode) {
    switch (mode) {
      case VoiceInteractionMode.conversational:
        return 'Natural conversation with AI assistant';
      case VoiceInteractionMode.command:
        return 'Specific voice commands for quick actions';
      case VoiceInteractionMode.dictation:
        return 'Simple speech-to-text conversion';
    }
  }

  void _updateSpeechSettings() {
    // Update TTS settings through the voice service
    // This would be implemented in the actual voice service
  }

  void _testVoice() {
    final voiceNotifier = ref.read(voiceInteractionProvider.notifier);
    voiceNotifier.speakResponse(
      'Hello! This is a test of your voice settings. Your speech rate is ${(_speechRate * 100).toInt()} percent, and the pitch is ${_pitch == 0 ? 'normal' : _pitch > 0 ? 'higher than normal' : 'lower than normal'}.',
    );
  }

  void _showAllCommands(List<VoiceCommandInfo> commands) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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

                Text(
                  'All Voice Commands',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: commands.length,
                    itemBuilder: (context, index) {
                      final command = commands[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                command.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                command.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Examples:',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              ...command.examples.map((example) => Padding(
                                    padding:
                                        const EdgeInsets.only(left: 8, top: 2),
                                    child: Text(
                                      '• "$example"',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha:0.7),
                                          ),
                                    ),
                                  ),),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

