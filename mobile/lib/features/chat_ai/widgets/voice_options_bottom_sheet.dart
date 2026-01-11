import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_interaction_provider.dart';
import '../../../core/services/voice_command_service.dart';
import '../../../core/services/integrated_voice_service.dart';

/// Voice Options Bottom Sheet
/// Provides voice settings and command information
class VoiceOptionsBottomSheet extends ConsumerWidget {
  final Function(String)? onLanguageChanged;
  final Function(VoiceInteractionMode)? onModeChanged;

  const VoiceOptionsBottomSheet({
    super.key,
    this.onLanguageChanged,
    this.onModeChanged,
  });

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
          // Header
          Row(
            children: [
              const Icon(Icons.settings_voice),
              const SizedBox(width: 8),
              Text(
                'Voice Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
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
                  child: FilterChip(
                    label: Text(language.name),
                    selected: false, // TODO: Track current language
                    onSelected: (selected) {
                      if (selected) {
                        onLanguageChanged?.call(language.code);
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Voice Mode Selection
          Text(
            'Voice Mode',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildModeChip(
                  context,
                  'Command',
                  VoiceInteractionMode.command,
                  Icons.keyboard_voice,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeChip(
                  context,
                  'Chat',
                  VoiceInteractionMode.conversational,
                  Icons.chat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeChip(
                  context,
                  'Dictation',
                  VoiceInteractionMode.dictation,
                  Icons.edit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Voice Commands
          Text(
            'Available Commands',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: availableCommands.length,
              itemBuilder: (context, index) {
                final command = availableCommands[index];
                return ListTile(
                  leading: const Icon(Icons.record_voice_over),
                  title: Text(command.name),
                  subtitle: Text(
                    command.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    _showCommandExamples(context, command);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(
    BuildContext context,
    String label,
    VoiceInteractionMode mode,
    IconData icon,
  ) {
    return FilterChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: false, // TODO: Track current mode
      onSelected: (selected) {
        if (selected) {
          onModeChanged?.call(mode);
        }
      },
    );
  }

  void _showCommandExamples(BuildContext context, VoiceCommandInfo command) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(command.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(command.description),
            const SizedBox(height: 16),
            const Text(
              'Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...command.examples.map(
              (example) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• "$example"'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

