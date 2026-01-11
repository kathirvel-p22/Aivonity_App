import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/integrated_voice_service.dart';
import '../../../core/services/voice_command_service.dart';
import '../../../core/services/simple_gemini_service.dart';

/// Voice interaction state
class VoiceInteractionState {
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final String? recognizedText;
  final double confidence;
  final String? error;
  final bool isVoiceEnabled;

  const VoiceInteractionState({
    this.isListening = false,
    this.isSpeaking = false,
    this.isProcessing = false,
    this.recognizedText,
    this.confidence = 0.0,
    this.error,
    this.isVoiceEnabled = true,
  });

  VoiceInteractionState copyWith({
    bool? isListening,
    bool? isSpeaking,
    bool? isProcessing,
    String? recognizedText,
    double? confidence,
    String? error,
    bool? isVoiceEnabled,
  }) {
    return VoiceInteractionState(
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isProcessing: isProcessing ?? this.isProcessing,
      recognizedText: recognizedText ?? this.recognizedText,
      confidence: confidence ?? this.confidence,
      error: error ?? this.error,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
    );
  }
}

/// Voice interaction notifier
class VoiceInteractionNotifier extends StateNotifier<VoiceInteractionState> {
  VoiceInteractionNotifier(this._voiceService, this._geminiService)
      : super(const VoiceInteractionState()) {
    _initializeVoiceService();
  }

  final IntegratedVoiceService _voiceService;
  final SimpleGeminiService _geminiService;

  void _initializeVoiceService() {
    _voiceService.addListener(_onVoiceServiceUpdate);
    _updateStateFromVoiceService();

    // Initialize the service if not already done
    if (!_voiceService.isInitialized) {
      _voiceService.initialize().catchError((error) {
        state =
            state.copyWith(error: 'Failed to initialize voice service: $error');
      });
    }
  }

  void _onVoiceServiceUpdate() {
    _updateStateFromVoiceService();
  }

  void _updateStateFromVoiceService() {
    state = state.copyWith(
      isListening: _voiceService.isListening,
      isSpeaking: _voiceService.isSpeaking,
      isProcessing: _voiceService.isProcessing,
      isVoiceEnabled: _voiceService.isInitialized,
    );
  }

  /// Start voice input
  Future<void> startVoiceInput() async {
    if (!_voiceService.isInitialized) {
      state = state.copyWith(error: 'Voice service not initialized');
      return;
    }

    try {
      state = state.copyWith(error: null);

      final result = await _voiceService.startVoiceInteraction(
        mode: VoiceInteractionMode.conversational,
        languageCode: _voiceService.currentLanguage,
      );

      if (result.success) {
        // Update state with the result
        state = state.copyWith(
          recognizedText: result.transcript,
          confidence: result.confidence,
        );

        // Handle the response if available
        if (result.response != null && result.response!.isNotEmpty) {
          // The TTS is already handled by the integrated service
          // You might want to add the response to chat history here
        }
      } else {
        state =
            state.copyWith(error: result.error ?? 'Voice interaction failed');
      }
    } catch (e) {
      state = state.copyWith(error: 'Voice input error: $e');
    }
  }

  /// Process voice input result
  void processVoiceResult(VoiceInteractionResult result) {
    if (result.success && result.transcript != null) {
      state = state.copyWith(
        recognizedText: result.transcript,
        confidence: result.confidence,
      );
    } else {
      state = state.copyWith(
        error: result.error ?? 'Voice processing failed',
      );
    }
  }

  /// Stop voice input
  Future<void> stopVoiceInput() async {
    try {
      await _voiceService.stopVoiceInteraction();
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop voice input: $e');
    }
  }

  /// Speak AI response
  Future<void> speakResponse(String text) async {
    if (!_voiceService.isInitialized || text.isEmpty) return;

    try {
      await _voiceService.speak(text);
    } catch (e) {
      state = state.copyWith(error: 'Failed to speak response: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _voiceService.stopSpeaking();
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop speaking: $e');
    }
  }

  /// Toggle voice input
  Future<void> toggleVoiceInput() async {
    if (state.isListening) {
      await stopVoiceInput();
    } else {
      await startVoiceInput();
    }
  }

  /// Set voice language
  Future<void> setLanguage(String languageCode) async {
    try {
      await _voiceService.setLanguage(languageCode);
    } catch (e) {
      state = state.copyWith(error: 'Failed to set language: $e');
    }
  }

  /// Get available languages
  List<VoiceLanguage> getAvailableLanguages() {
    return _voiceService.getAvailableLanguages();
  }

  /// Set voice interaction mode
  void setVoiceMode(VoiceInteractionMode mode) {
    _voiceService.setMode(mode);
  }

  /// Get available voice commands
  List<VoiceCommandInfo> getAvailableCommands() {
    return _voiceService.getAvailableCommands();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceUpdate);
    super.dispose();
  }
}

/// Voice interaction provider
final voiceInteractionProvider =
    StateNotifierProvider<VoiceInteractionNotifier, VoiceInteractionState>(
        (ref) {
  final voiceService = IntegratedVoiceService.instance;
  final geminiService = SimpleGeminiService.instance;

  return VoiceInteractionNotifier(voiceService, geminiService);
});

/// Integrated voice service provider
final integratedVoiceServiceProvider = Provider<IntegratedVoiceService>((ref) {
  return IntegratedVoiceService.instance;
});

