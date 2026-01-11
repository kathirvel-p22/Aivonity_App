import 'package:flutter/material.dart';
import '../widgets/enhanced_voice_chat_widget.dart';
import '../widgets/voice_settings_widget.dart';

/// Voice Demo Screen
/// Demonstrates the enhanced voice chat capabilities
class VoiceDemoScreen extends StatelessWidget {
  const VoiceDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Voice Assistant Demo'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VoiceSettingsWidget(),
                ),
              );
            },
          ),
        ],
      ),
      body: const EnhancedVoiceChatWidget(),
    );
  }
}

