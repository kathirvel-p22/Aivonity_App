import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/multilingual_chat_provider.dart';
import '../providers/voice_interaction_provider.dart';
import 'multilingual_message_widget.dart';
import 'voice_input_widget.dart';
import 'quick_suggestions.dart';

/// Enhanced Voice Chat Widget
/// Combines multilingual chat with voice interaction capabilities
class EnhancedVoiceChatWidget extends ConsumerStatefulWidget {
  const EnhancedVoiceChatWidget({super.key});

  @override
  ConsumerState<EnhancedVoiceChatWidget> createState() =>
      _EnhancedVoiceChatWidgetState();
}

class _EnhancedVoiceChatWidgetState
    extends ConsumerState<EnhancedVoiceChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleVoiceResult(String text) {
    if (text.isNotEmpty) {
      _sendMessage(text);
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final notifier = ref.read(multilingualChatProvider.notifier);
    notifier.sendMessage(text);

    _textController.clear();
    setState(() {
      _isTyping = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onSuggestionTap(String suggestion) {
    _sendMessage(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final voiceState = ref.watch(voiceInteractionProvider);
    final chatState = ref.watch(multilingualChatProvider);

    // Auto-scroll on new messages
    ref.listen(chatMessagesProvider, (previous, next) {
      if (next.length > (previous?.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Column(
      children: [
        // Chat Area
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha:0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start a conversation',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha:0.5),
                                ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (chatState.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha:0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI is typing...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha:0.6),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return MultilingualMessageWidget(message: messages[index]);
                  },
                ),
        ),

        // Quick Suggestions
        if (messages.isEmpty)
          QuickSuggestions(onSuggestionTap: _onSuggestionTap),

        // Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha:0.5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isTyping = value.trim().isNotEmpty;
                        });
                      },
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_isTyping)
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _sendMessage(_textController.text),
                      ),
                    )
                  else
                    VoiceInputWidget(
                      onVoiceResult: _handleVoiceResult,
                      enabled: !voiceState.isProcessing,
                    ),
                ],
              ),
              if (voiceState.isListening) ...[
                const SizedBox(height: 8),
                Text(
                  'Listening...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

