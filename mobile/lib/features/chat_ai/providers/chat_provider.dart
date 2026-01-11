import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chat_models.dart';

/// Chat state model
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Chat state notifier
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState()) {
    _initializeChat();
  }

  void _initializeChat() {
    // Add welcome message
    addMessage(
      ChatMessage.assistant(
        content: '''👋 Hello! I'm your AIVONITY AI assistant.

I'm here to help you with:
🚗 Vehicle health monitoring
🔧 Maintenance scheduling  
🛠️ Troubleshooting issues
📍 Finding service centers
⛽ Fuel efficiency tips

How can I assist you today?''',
      ),
    );
  }

  /// Add a message to the chat
  void addMessage(ChatMessage message) {
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set error state
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Clear all messages
  void clearMessages() {
    state = const ChatState();
    _initializeChat();
  }

  /// Remove a specific message
  void removeMessage(String messageId) {
    final updatedMessages =
        state.messages.where((message) => message.id != messageId).toList();

    state = state.copyWith(messages: updatedMessages);
  }

  /// Get conversation history
  List<ChatMessage> getConversationHistory({int limit = 10}) {
    final messages =
        state.messages.where((m) => m.isUser || !m.isUser).toList();
    return messages.length > limit
        ? messages.sublist(messages.length - limit)
        : messages;
  }
}

/// Chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

