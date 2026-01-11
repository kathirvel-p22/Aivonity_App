import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/multilingual_ai_chat_service.dart';
import '../../../core/services/localization_service.dart';

/// Multilingual Chat State
class MultilingualChatState {
  final bool isInitialized;
  final String currentLanguage;
  final bool autoDetectLanguage;
  final bool autoTranslateResponses;
  final List<MultilingualChatMessage> messages;
  final bool isLoading;
  final String? error;
  final double? lastDetectionConfidence;

  const MultilingualChatState({
    this.isInitialized = false,
    this.currentLanguage = 'en-US',
    this.autoDetectLanguage = true,
    this.autoTranslateResponses = true,
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.lastDetectionConfidence,
  });

  MultilingualChatState copyWith({
    bool? isInitialized,
    String? currentLanguage,
    bool? autoDetectLanguage,
    bool? autoTranslateResponses,
    List<MultilingualChatMessage>? messages,
    bool? isLoading,
    String? error,
    double? lastDetectionConfidence,
  }) {
    return MultilingualChatState(
      isInitialized: isInitialized ?? this.isInitialized,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
      autoTranslateResponses:
          autoTranslateResponses ?? this.autoTranslateResponses,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastDetectionConfidence:
          lastDetectionConfidence ?? this.lastDetectionConfidence,
    );
  }
}

/// Multilingual Chat Notifier
class MultilingualChatNotifier extends StateNotifier<MultilingualChatState> {
  MultilingualChatNotifier(this._multilingualService, this._localizationService)
      : super(const MultilingualChatState()) {
    _initialize();
  }

  final MultilingualAIChatService _multilingualService;
  final LocalizationService _localizationService;

  /// Initialize the multilingual chat
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _multilingualService.initialize();
      await _localizationService.initialize();

      // Load conversation history
      final history = await _multilingualService.getConversationHistory();

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        currentLanguage: _multilingualService.currentConversationLanguage,
        autoDetectLanguage: _localizationService.autoDetectLanguage,
        autoTranslateResponses: _multilingualService.autoTranslateResponses,
        messages: history,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize multilingual chat: $e',
      );
    }
  }

  /// Send a message with language detection
  Future<void> sendMessage(String message, {String? forceLanguage}) async {
    if (!state.isInitialized || message.trim().isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Add user message to state immediately
      final userMessage = MultilingualChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        response: '',
        language: forceLanguage ?? state.currentLanguage,
        timestamp: DateTime.now(),
        isUser: true,
      );

      state = state.copyWith(
        messages: [...state.messages, userMessage],
      );

      // Get AI response
      final response = await _multilingualService.sendMessage(
        message,
        forceLanguage: forceLanguage,
        detectLanguage: state.autoDetectLanguage,
      );

      // Add AI response to state
      final aiMessage = MultilingualChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        message: message,
        response: response.displayResponse,
        language: response.detectedLanguage,
        timestamp: response.timestamp,
        isUser: false,
        confidence: response.confidence,
        metadata: {
          'original_response': response.response,
          'translated_response': response.translatedResponse,
          'vehicle_context': response.vehicleContext,
        },
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        currentLanguage: response.detectedLanguage,
        lastDetectionConfidence: response.confidence,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send message: $e',
      );
    }
  }

  /// Set conversation language
  Future<void> setLanguage(String languageCode) async {
    try {
      await _multilingualService.setConversationLanguage(languageCode);
      await _localizationService.setLanguage(languageCode);

      state = state.copyWith(
        currentLanguage: languageCode,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to set language: $e',
      );
    }
  }

  /// Toggle auto-detect language
  void toggleAutoDetectLanguage() {
    final newValue = !state.autoDetectLanguage;
    _localizationService.setAutoDetectLanguage(newValue);

    state = state.copyWith(
      autoDetectLanguage: newValue,
    );
  }

  /// Toggle auto-translate responses
  void toggleAutoTranslateResponses() {
    final newValue = !state.autoTranslateResponses;
    _multilingualService.setAutoTranslateResponses(newValue);

    state = state.copyWith(
      autoTranslateResponses: newValue,
    );
  }

  /// Clear conversation history
  void clearConversation() {
    state = state.copyWith(
      messages: [],
      error: null,
    );
  }

  /// Get messages in specific language
  List<MultilingualChatMessage> getMessagesInLanguage(String languageCode) {
    return state.messages.where((msg) => msg.language == languageCode).toList();
  }

  /// Get available languages
  List<LanguageOption> getAvailableLanguages() {
    return _multilingualService.getSupportedLanguages();
  }

  /// Get localized voice commands
  List<LocalizedVoiceCommand> getVoiceCommands(String languageCode) {
    return _multilingualService.getLocalizedVoiceCommands(languageCode);
  }

  /// Translate message
  Future<String> translateMessage(
    String text,
    String fromLanguage,
    String toLanguage,
  ) async {
    try {
      return await _multilingualService.translateText(
        text,
        fromLanguage,
        toLanguage,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Translation failed: $e',
      );
      return text;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Retry last failed operation
  Future<void> retry() async {
    if (state.error != null) {
      await _initialize();
    }
  }
}

/// Providers

final multilingualAIChatServiceProvider =
    Provider<MultilingualAIChatService>((ref) {
  return MultilingualAIChatService.instance;
});

final localizationServiceProvider = Provider<LocalizationService>((ref) {
  return LocalizationService.instance;
});

final multilingualChatProvider =
    StateNotifierProvider<MultilingualChatNotifier, MultilingualChatState>(
        (ref) {
  final multilingualService = ref.read(multilingualAIChatServiceProvider);
  final localizationService = ref.read(localizationServiceProvider);

  return MultilingualChatNotifier(multilingualService, localizationService);
});

/// Computed providers

final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(multilingualChatProvider).currentLanguage;
});

final availableLanguagesProvider = Provider<List<LanguageOption>>((ref) {
  final notifier = ref.read(multilingualChatProvider.notifier);
  return notifier.getAvailableLanguages();
});

final currentLanguageVoiceCommandsProvider =
    Provider<List<LocalizedVoiceCommand>>((ref) {
  final currentLanguage = ref.watch(currentLanguageProvider);
  final notifier = ref.read(multilingualChatProvider.notifier);
  return notifier.getVoiceCommands(currentLanguage);
});

final chatMessagesProvider = Provider<List<MultilingualChatMessage>>((ref) {
  return ref.watch(multilingualChatProvider).messages;
});

final isMultilingualChatLoadingProvider = Provider<bool>((ref) {
  return ref.watch(multilingualChatProvider).isLoading;
});

final multilingualChatErrorProvider = Provider<String?>((ref) {
  return ref.watch(multilingualChatProvider).error;
});

final languageDetectionConfidenceProvider = Provider<double?>((ref) {
  return ref.watch(multilingualChatProvider).lastDetectionConfidence;
});

/// Language-specific message providers

final messagesInCurrentLanguageProvider =
    Provider<List<MultilingualChatMessage>>((ref) {
  final currentLanguage = ref.watch(currentLanguageProvider);
  final notifier = ref.read(multilingualChatProvider.notifier);
  return notifier.getMessagesInLanguage(currentLanguage);
});

Provider<List<MultilingualChatMessage>> messagesInLanguageProvider(
    String languageCode,) {
  return Provider<List<MultilingualChatMessage>>((ref) {
    final notifier = ref.read(multilingualChatProvider.notifier);
    return notifier.getMessagesInLanguage(languageCode);
  });
}

