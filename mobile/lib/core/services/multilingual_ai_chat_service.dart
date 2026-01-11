import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'localization_service.dart';
import 'ai_chat_service.dart';

/// Multilingual AI Chat Service
/// Extends the base AI chat service with multi-language support and automatic language detection
class MultilingualAIChatService extends ChangeNotifier {
  static MultilingualAIChatService? _instance;
  static MultilingualAIChatService get instance =>
      _instance ??= MultilingualAIChatService._();

  MultilingualAIChatService._();

  final Logger _logger = Logger();
  late final LocalizationService _localizationService;
  late final AIChatService _baseChatService;

  bool _isInitialized = false;
  String _currentConversationLanguage = 'en-US';
  bool _autoTranslateResponses = true;

  // Getters
  bool get isInitialized => _isInitialized;
  String get currentConversationLanguage => _currentConversationLanguage;
  bool get autoTranslateResponses => _autoTranslateResponses;

  /// Initialize the multilingual chat service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.i('Initializing Multilingual AI Chat Service...');

      _localizationService = LocalizationService.instance;
      _baseChatService = AIChatService.instance;

      await _localizationService.initialize();
      await _baseChatService.initialize();

      _currentConversationLanguage = _localizationService.currentLanguage;

      _isInitialized = true;
      _logger.i('Multilingual AI Chat Service initialized successfully');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to initialize Multilingual AI Chat Service: $e');
      throw Exception('Multilingual chat initialization failed: $e');
    }
  }

  /// Send message with automatic language detection and localized response
  Future<MultilingualChatResponse> sendMessage(
    String message, {
    String? forceLanguage,
    bool detectLanguage = true,
  }) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      _logger.i(
          'Processing multilingual message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...',);

      // Detect or use specified language
      final String detectedLanguage = forceLanguage ??
          (detectLanguage
              ? _localizationService.detectLanguage(message)
              : _currentConversationLanguage);

      // Update conversation language if different
      if (detectedLanguage != _currentConversationLanguage) {
        _currentConversationLanguage = detectedLanguage;
        _logger.i('Conversation language changed to: $detectedLanguage');
        notifyListeners();
      }

      // Get localized response
      final localizedResponse =
          await _localizationService.getLocalizedAIResponse(
        message,
        detectedLanguage,
      );

      // Create enhanced response with vehicle context
      final enhancedResponse = await _enhanceResponseWithVehicleContext(
        message,
        localizedResponse,
        detectedLanguage,
      );

      // Get translation if needed
      String? translatedResponse;
      if (_autoTranslateResponses &&
          detectedLanguage != _localizationService.currentLanguage) {
        translatedResponse = await _translateResponse(
          enhancedResponse,
          detectedLanguage,
          _localizationService.currentLanguage,
        );
      }

      return MultilingualChatResponse(
        originalMessage: message,
        detectedLanguage: detectedLanguage,
        response: enhancedResponse,
        translatedResponse: translatedResponse,
        confidence: _calculateLanguageConfidence(message, detectedLanguage),
        timestamp: DateTime.now(),
        vehicleContext: await _getVehicleContext(),
      );
    } catch (e) {
      _logger.e('Failed to process multilingual message: $e');

      // Return error response in appropriate language
      final errorLanguage = forceLanguage ?? _currentConversationLanguage;
      final errorMessage = _localizationService.getLocalizedErrorMessage(
          'ai_error', errorLanguage,);

      return MultilingualChatResponse(
        originalMessage: message,
        detectedLanguage: errorLanguage,
        response: errorMessage,
        confidence: 0.0,
        timestamp: DateTime.now(),
        isError: true,
        error: e.toString(),
      );
    }
  }

  /// Get conversation history with language metadata
  Future<List<MultilingualChatMessage>> getConversationHistory({
    int limit = 50,
    String? languageFilter,
  }) async {
    try {
      // In a real implementation, this would fetch from a database
      // For now, return mock data
      return _getMockConversationHistory(limit, languageFilter);
    } catch (e) {
      _logger.e('Failed to get conversation history: $e');
      return [];
    }
  }

  /// Set conversation language manually
  Future<void> setConversationLanguage(String languageCode) async {
    try {
      _currentConversationLanguage = languageCode;
      await _localizationService.setLanguage(languageCode);
      _logger.i('Conversation language set to: $languageCode');
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to set conversation language: $e');
    }
  }

  /// Toggle auto-translate responses
  void setAutoTranslateResponses(bool enabled) {
    _autoTranslateResponses = enabled;
    _logger.i('Auto-translate responses: $enabled');
    notifyListeners();
  }

  /// Get supported languages for chat
  List<LanguageOption> getSupportedLanguages() {
    return _localizationService.getAvailableLanguages();
  }

  /// Get language-specific voice commands
  List<LocalizedVoiceCommand> getLocalizedVoiceCommands(String languageCode) {
    return _getVoiceCommandsForLanguage(languageCode);
  }

  /// Translate text between languages
  Future<String> translateText(
    String text,
    String fromLanguage,
    String toLanguage,
  ) async {
    try {
      // In a real implementation, integrate with translation service (Google Translate, etc.)
      return await _translateResponse(text, fromLanguage, toLanguage);
    } catch (e) {
      _logger.e('Translation failed: $e');
      return text; // Return original text if translation fails
    }
  }

  // Private helper methods

  Future<String> _enhanceResponseWithVehicleContext(
    String userMessage,
    String baseResponse,
    String language,
  ) async {
    try {
      // Add vehicle-specific context to the response
      final vehicleContext = await _getVehicleContext();

      // Enhance response based on vehicle data
      if (vehicleContext.isNotEmpty) {
        return _addVehicleContextToResponse(
            baseResponse, vehicleContext, language,);
      }

      return baseResponse;
    } catch (e) {
      _logger.w('Failed to enhance response with vehicle context: $e');
      return baseResponse;
    }
  }

  String _addVehicleContextToResponse(
    String response,
    Map<String, dynamic> vehicleContext,
    String language,
  ) {
    // Add vehicle-specific information to the response
    final vehicleName = vehicleContext['name'] ?? 'your vehicle';
    final mileage = vehicleContext['mileage'] ?? 'unknown';

    switch (language) {
      case 'es-ES':
        return '$response\n\n📊 Información de tu $vehicleName:\n• Kilometraje: $mileage millas';
      case 'fr-FR':
        return '$response\n\n📊 Informations sur votre $vehicleName:\n• Kilométrage: $mileage miles';
      case 'de-DE':
        return '$response\n\n📊 Informationen zu Ihrem $vehicleName:\n• Laufleistung: $mileage Meilen';
      default:
        return '$response\n\n📊 Your $vehicleName info:\n• Mileage: $mileage miles';
    }
  }

  Future<String> _translateResponse(
    String text,
    String fromLanguage,
    String toLanguage,
  ) async {
    // Mock translation - in real implementation, use translation API
    if (fromLanguage == toLanguage) return text;

    // Simple mock translations for demonstration
    if (fromLanguage == 'en-US' && toLanguage == 'es-ES') {
      return _mockTranslateToSpanish(text);
    } else if (fromLanguage == 'es-ES' && toLanguage == 'en-US') {
      return _mockTranslateToEnglish(text);
    }

    return text; // Return original if no translation available
  }

  String _mockTranslateToSpanish(String text) {
    // Very basic mock translation
    return text
        .replaceAll('Hello', 'Hola')
        .replaceAll('Thank you', 'Gracias')
        .replaceAll('vehicle', 'vehículo')
        .replaceAll('health', 'salud')
        .replaceAll('maintenance', 'mantenimiento');
  }

  String _mockTranslateToEnglish(String text) {
    // Very basic mock translation
    return text
        .replaceAll('Hola', 'Hello')
        .replaceAll('Gracias', 'Thank you')
        .replaceAll('vehículo', 'vehicle')
        .replaceAll('salud', 'health')
        .replaceAll('mantenimiento', 'maintenance');
  }

  double _calculateLanguageConfidence(String text, String detectedLanguage) {
    // Simple confidence calculation based on text characteristics
    if (text.length < 5) return 0.5;

    // Higher confidence for longer texts with language-specific patterns
    double confidence = 0.7;

    // Boost confidence for language-specific characters
    if (detectedLanguage == 'zh-CN' &&
        RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
      confidence = 0.95;
    } else if (detectedLanguage == 'ja-JP' &&
        RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(text)) {
      confidence = 0.95;
    } else if (detectedLanguage == 'ko-KR' &&
        RegExp(r'[\uac00-\ud7af]').hasMatch(text)) {
      confidence = 0.95;
    }

    return confidence;
  }

  Future<Map<String, dynamic>> _getVehicleContext() async {
    // Mock vehicle context - in real implementation, fetch from vehicle service
    return {
      'name': '2023 Tesla Model 3',
      'mileage': 15420,
      'health_score': 92,
      'last_service': '2024-10-15',
      'next_service_due': 2500,
    };
  }

  List<MultilingualChatMessage> _getMockConversationHistory(
      int limit, String? languageFilter,) {
    // Mock conversation history
    final messages = <MultilingualChatMessage>[
      MultilingualChatMessage(
        id: '1',
        message: 'Hello, how is my vehicle health?',
        response: 'Your vehicle health looks great! Engine: 95%, Battery: 87%.',
        language: 'en-US',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isUser: true,
      ),
      MultilingualChatMessage(
        id: '2',
        message: '¿Cuándo necesito el próximo mantenimiento?',
        response: 'Tu próximo mantenimiento está programado en 2,500 millas.',
        language: 'es-ES',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isUser: true,
      ),
    ];

    if (languageFilter != null) {
      return messages
          .where((msg) => msg.language == languageFilter)
          .take(limit)
          .toList();
    }

    return messages.take(limit).toList();
  }

  List<LocalizedVoiceCommand> _getVoiceCommandsForLanguage(
      String languageCode,) {
    switch (languageCode) {
      case 'es-ES':
        return [
          const LocalizedVoiceCommand(
            command: 'check_health',
            phrase: 'revisar salud del vehículo',
            description: 'Verificar el estado de salud del vehículo',
          ),
          const LocalizedVoiceCommand(
            command: 'schedule_maintenance',
            phrase: 'programar mantenimiento',
            description: 'Programar una cita de mantenimiento',
          ),
        ];
      case 'fr-FR':
        return [
          const LocalizedVoiceCommand(
            command: 'check_health',
            phrase: 'vérifier la santé du véhicule',
            description: 'Vérifier l\'état de santé du véhicule',
          ),
          const LocalizedVoiceCommand(
            command: 'schedule_maintenance',
            phrase: 'programmer l\'entretien',
            description: 'Programmer un rendez-vous d\'entretien',
          ),
        ];
      case 'de-DE':
        return [
          const LocalizedVoiceCommand(
            command: 'check_health',
            phrase: 'fahrzeugzustand prüfen',
            description: 'Den Gesundheitszustand des Fahrzeugs überprüfen',
          ),
          const LocalizedVoiceCommand(
            command: 'schedule_maintenance',
            phrase: 'wartung planen',
            description: 'Einen Wartungstermin planen',
          ),
        ];
      default:
        return [
          const LocalizedVoiceCommand(
            command: 'check_health',
            phrase: 'check vehicle health',
            description: 'Check the vehicle\'s health status',
          ),
          const LocalizedVoiceCommand(
            command: 'schedule_maintenance',
            phrase: 'schedule maintenance',
            description: 'Schedule a maintenance appointment',
          ),
        ];
    }
  }
}

/// Multilingual Chat Response Model
class MultilingualChatResponse {
  final String originalMessage;
  final String detectedLanguage;
  final String response;
  final String? translatedResponse;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic>? vehicleContext;
  final bool isError;
  final String? error;

  const MultilingualChatResponse({
    required this.originalMessage,
    required this.detectedLanguage,
    required this.response,
    this.translatedResponse,
    required this.confidence,
    required this.timestamp,
    this.vehicleContext,
    this.isError = false,
    this.error,
  });

  bool get hasTranslation =>
      translatedResponse != null && translatedResponse!.isNotEmpty;

  String get displayResponse => translatedResponse ?? response;
}

/// Multilingual Chat Message Model
class MultilingualChatMessage {
  final String id;
  final String message;
  final String response;
  final String language;
  final DateTime timestamp;
  final bool isUser;
  final double? confidence;
  final Map<String, dynamic>? metadata;

  const MultilingualChatMessage({
    required this.id,
    required this.message,
    required this.response,
    required this.language,
    required this.timestamp,
    required this.isUser,
    this.confidence,
    this.metadata,
  });
}

/// Localized Voice Command Model
class LocalizedVoiceCommand {
  final String command;
  final String phrase;
  final String description;

  const LocalizedVoiceCommand({
    required this.command,
    required this.phrase,
    required this.description,
  });
}

