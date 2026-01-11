import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Localization Service
/// Handles multi-language support, automatic language detection, and localized AI responses
class LocalizationService extends ChangeNotifier {
  static LocalizationService? _instance;
  static LocalizationService get instance =>
      _instance ??= LocalizationService._();

  LocalizationService._();

  final Logger _logger = Logger();

  String _currentLanguage = 'en-US';
  Locale _currentLocale = const Locale('en', 'US');
  bool _autoDetectLanguage = true;

  // Getters
  String get currentLanguage => _currentLanguage;
  Locale get currentLocale => _currentLocale;
  bool get autoDetectLanguage => _autoDetectLanguage;

  /// Initialize localization service
  Future<void> initialize() async {
    try {
      // Load saved language preference or use system default
      await _loadLanguagePreference();
      _logger.i(
          'Localization service initialized with language: $_currentLanguage',);
    } catch (e) {
      _logger.e('Failed to initialize localization service: $e');
    }
  }

  /// Set current language
  Future<void> setLanguage(String languageCode) async {
    try {
      final locale = _parseLanguageCode(languageCode);
      if (locale != null) {
        _currentLanguage = languageCode;
        _currentLocale = locale;

        // Save preference
        await _saveLanguagePreference(languageCode);

        _logger.i('Language changed to: $languageCode');
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Failed to set language: $e');
    }
  }

  /// Auto-detect language from text input
  String detectLanguage(String text) {
    if (!_autoDetectLanguage || text.trim().isEmpty) {
      return _currentLanguage;
    }

    try {
      // Simple language detection based on common words and patterns
      final lowerText = text.toLowerCase();

      // Spanish detection
      if (_containsSpanishWords(lowerText)) {
        return 'es-ES';
      }

      // French detection
      if (_containsFrenchWords(lowerText)) {
        return 'fr-FR';
      }

      // German detection
      if (_containsGermanWords(lowerText)) {
        return 'de-DE';
      }

      // Italian detection
      if (_containsItalianWords(lowerText)) {
        return 'it-IT';
      }

      // Portuguese detection
      if (_containsPortugueseWords(lowerText)) {
        return 'pt-BR';
      }

      // Chinese detection (simplified characters)
      if (_containsChineseCharacters(text)) {
        return 'zh-CN';
      }

      // Japanese detection (hiragana/katakana)
      if (_containsJapaneseCharacters(text)) {
        return 'ja-JP';
      }

      // Korean detection (hangul)
      if (_containsKoreanCharacters(text)) {
        return 'ko-KR';
      }

      // Default to current language if no detection
      return _currentLanguage;
    } catch (e) {
      _logger.w('Language detection failed: $e');
      return _currentLanguage;
    }
  }

  /// Get localized AI response based on detected or current language
  Future<String> getLocalizedAIResponse(
      String userInput, String detectedLanguage,) async {
    try {
      final responses = _getLocalizedResponses(detectedLanguage);
      final lowerInput = userInput.toLowerCase();

      // Health check responses
      if (lowerInput
          .contains(_getLocalizedKeywords(detectedLanguage, 'health'))) {
        return responses['health'] ?? _getDefaultResponse(detectedLanguage);
      }

      // Maintenance responses
      if (lowerInput
          .contains(_getLocalizedKeywords(detectedLanguage, 'maintenance'))) {
        return responses['maintenance'] ??
            _getDefaultResponse(detectedLanguage);
      }

      // Fuel efficiency responses
      if (lowerInput
          .contains(_getLocalizedKeywords(detectedLanguage, 'fuel'))) {
        return responses['fuel'] ?? _getDefaultResponse(detectedLanguage);
      }

      // Greeting responses
      if (lowerInput
          .contains(_getLocalizedKeywords(detectedLanguage, 'greeting'))) {
        return responses['greeting'] ?? _getDefaultResponse(detectedLanguage);
      }

      // Problem/troubleshooting responses
      if (lowerInput
          .contains(_getLocalizedKeywords(detectedLanguage, 'problem'))) {
        return responses['problem'] ?? _getDefaultResponse(detectedLanguage);
      }

      // Service center responses
      if (lowerInput.contains(
          _getLocalizedKeywords(detectedLanguage, 'service_center'),)) {
        return responses['service_center'] ??
            _getDefaultResponse(detectedLanguage);
      }

      // Thank you responses
      if (lowerInput
          .contains(_getLocalizedKeywords(detectedLanguage, 'thanks'))) {
        return responses['thanks'] ?? _getDefaultResponse(detectedLanguage);
      }

      // Default response
      return responses['default'] ?? _getDefaultResponse(detectedLanguage);
    } catch (e) {
      _logger.e('Failed to get localized response: $e');
      return _getDefaultResponse(detectedLanguage);
    }
  }

  /// Get available languages with native names
  List<LanguageOption> getAvailableLanguages() {
    return [
      const LanguageOption(
        code: 'en-US',
        name: 'English',
        nativeName: 'English',
        flag: '🇺🇸',
      ),
      const LanguageOption(
        code: 'es-ES',
        name: 'Spanish',
        nativeName: 'Español',
        flag: '🇪🇸',
      ),
      const LanguageOption(
        code: 'fr-FR',
        name: 'French',
        nativeName: 'Français',
        flag: '🇫🇷',
      ),
      const LanguageOption(
        code: 'de-DE',
        name: 'German',
        nativeName: 'Deutsch',
        flag: '🇩🇪',
      ),
      const LanguageOption(
        code: 'it-IT',
        name: 'Italian',
        nativeName: 'Italiano',
        flag: '🇮🇹',
      ),
      const LanguageOption(
        code: 'pt-BR',
        name: 'Portuguese',
        nativeName: 'Português',
        flag: '🇧🇷',
      ),
      const LanguageOption(
        code: 'zh-CN',
        name: 'Chinese',
        nativeName: '中文',
        flag: '🇨🇳',
      ),
      const LanguageOption(
        code: 'ja-JP',
        name: 'Japanese',
        nativeName: '日本語',
        flag: '🇯🇵',
      ),
      const LanguageOption(
        code: 'ko-KR',
        name: 'Korean',
        nativeName: '한국어',
        flag: '🇰🇷',
      ),
    ];
  }

  /// Toggle auto-detect language
  void setAutoDetectLanguage(bool enabled) {
    _autoDetectLanguage = enabled;
    _logger.i('Auto-detect language: $enabled');
    notifyListeners();
  }

  /// Get localized error messages
  String getLocalizedErrorMessage(String errorKey, [String? languageCode]) {
    final lang = languageCode ?? _currentLanguage;
    final errorMessages = _getErrorMessages(lang);
    return errorMessages[errorKey] ??
        errorMessages['default'] ??
        'An error occurred';
  }

  // Private helper methods

  Future<void> _loadLanguagePreference() async {
    // In a real implementation, load from SharedPreferences
    // For now, use system locale or default
    _currentLanguage = 'en-US';
    _currentLocale = const Locale('en', 'US');
  }

  Future<void> _saveLanguagePreference(String languageCode) async {
    // In a real implementation, save to SharedPreferences
    _logger.i('Saving language preference: $languageCode');
  }

  Locale? _parseLanguageCode(String languageCode) {
    try {
      final parts = languageCode.split('-');
      if (parts.length >= 2) {
        return Locale(parts[0], parts[1]);
      } else if (parts.length == 1) {
        return Locale(parts[0]);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _containsSpanishWords(String text) {
    const spanishWords = [
      'hola',
      'gracias',
      'por favor',
      'sí',
      'no',
      'cómo',
      'qué',
      'dónde',
      'cuándo',
      'vehículo',
      'coche',
      'auto',
      'mantenimiento',
      'combustible',
      'salud',
      'estado',
      'problema',
      'ayuda',
      'servicio',
    ];
    return spanishWords.any((word) => text.contains(word));
  }

  bool _containsFrenchWords(String text) {
    const frenchWords = [
      'bonjour',
      'merci',
      'sil vous plaît',
      'oui',
      'non',
      'comment',
      'quoi',
      'où',
      'quand',
      'véhicule',
      'voiture',
      'entretien',
      'carburant',
      'santé',
      'état',
      'problème',
      'aide',
      'service',
    ];
    return frenchWords.any((word) => text.contains(word));
  }

  bool _containsGermanWords(String text) {
    const germanWords = [
      'hallo',
      'danke',
      'bitte',
      'ja',
      'nein',
      'wie',
      'was',
      'wo',
      'wann',
      'fahrzeug',
      'auto',
      'wartung',
      'kraftstoff',
      'gesundheit',
      'zustand',
      'problem',
      'hilfe',
      'service',
    ];
    return germanWords.any((word) => text.contains(word));
  }

  bool _containsItalianWords(String text) {
    const italianWords = [
      'ciao',
      'grazie',
      'prego',
      'sì',
      'no',
      'come',
      'cosa',
      'dove',
      'quando',
      'veicolo',
      'auto',
      'manutenzione',
      'carburante',
      'salute',
      'stato',
      'problema',
      'aiuto',
      'servizio',
    ];
    return italianWords.any((word) => text.contains(word));
  }

  bool _containsPortugueseWords(String text) {
    const portugueseWords = [
      'olá',
      'obrigado',
      'por favor',
      'sim',
      'não',
      'como',
      'que',
      'onde',
      'quando',
      'veículo',
      'carro',
      'manutenção',
      'combustível',
      'saúde',
      'estado',
      'problema',
      'ajuda',
      'serviço',
    ];
    return portugueseWords.any((word) => text.contains(word));
  }

  bool _containsChineseCharacters(String text) {
    // Check for Chinese characters (simplified)
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
  }

  bool _containsJapaneseCharacters(String text) {
    // Check for Hiragana and Katakana
    return RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(text);
  }

  bool _containsKoreanCharacters(String text) {
    // Check for Hangul
    return RegExp(r'[\uac00-\ud7af]').hasMatch(text);
  }

  String _getLocalizedKeywords(String languageCode, String category) {
    final keywords = _getKeywordMappings(languageCode);
    return keywords[category] ?? '';
  }

  Map<String, String> _getKeywordMappings(String languageCode) {
    switch (languageCode) {
      case 'es-ES':
        return {
          'health': 'salud|estado|diagnóstico|condición',
          'maintenance': 'mantenimiento|servicio|reparación',
          'fuel': 'combustible|gasolina|eficiencia|consumo',
          'greeting': 'hola|buenos días|buenas tardes',
          'problem': 'problema|issue|fallo|error',
          'service_center': 'centro de servicio|taller|mecánico',
          'thanks': 'gracias|muchas gracias',
        };
      case 'fr-FR':
        return {
          'health': 'santé|état|diagnostic|condition',
          'maintenance': 'entretien|service|réparation',
          'fuel': 'carburant|essence|efficacité|consommation',
          'greeting': 'bonjour|bonsoir|salut',
          'problem': 'problème|panne|erreur',
          'service_center': 'centre de service|garage|mécanicien',
          'thanks': 'merci|merci beaucoup',
        };
      case 'de-DE':
        return {
          'health': 'gesundheit|zustand|diagnose|bedingung',
          'maintenance': 'wartung|service|reparatur',
          'fuel': 'kraftstoff|benzin|effizienz|verbrauch',
          'greeting': 'hallo|guten tag|guten abend',
          'problem': 'problem|fehler|störung',
          'service_center': 'servicezentrum|werkstatt|mechaniker',
          'thanks': 'danke|vielen dank',
        };
      default:
        return {
          'health': 'health|status|diagnostic|condition',
          'maintenance': 'maintenance|service|repair',
          'fuel': 'fuel|gas|efficiency|consumption',
          'greeting': 'hello|hi|good morning|good evening',
          'problem': 'problem|issue|trouble|error',
          'service_center': 'service center|garage|mechanic',
          'thanks': 'thank|thanks|thank you',
        };
    }
  }

  Map<String, String> _getLocalizedResponses(String languageCode) {
    switch (languageCode) {
      case 'es-ES':
        return {
          'greeting':
              '¡Hola! Soy tu asistente de vehículos con IA. ¿Cómo puedo ayudarte hoy?',
          'health':
              'El estado de tu vehículo se ve bien. Motor: 95%, Batería: 87%, Frenos: 94%. Próximo mantenimiento en 2,500 millas.',
          'maintenance':
              'Basado en el kilometraje de tu vehículo, necesitas un cambio de aceite en 2,500 millas y rotación de llantas en 1,200 millas.',
          'fuel':
              'Tu eficiencia actual de combustible es 32.5 MPG, ¡está por encima del promedio! Aquí tienes algunos consejos para mejorarla.',
          'problem':
              'Estoy aquí para ayudarte a solucionar problemas del vehículo. ¿Puedes describir qué está pasando?',
          'service_center':
              'Encontré 5 centros de servicio cerca de ti. El más cercano es AutoCare Plus, a 2.3 millas con calificación de 4.8 estrellas.',
          'thanks':
              '¡De nada! Siempre estoy aquí para ayudarte con las necesidades de tu vehículo.',
          'default':
              'Entiendo que preguntas sobre tu vehículo. Puedo ayudarte con revisiones de salud, programación de mantenimiento y más.',
        };
      case 'fr-FR':
        return {
          'greeting':
              'Bonjour ! Je suis votre assistant véhicule IA. Comment puis-je vous aider aujourd\'hui ?',
          'health':
              'La santé de votre véhicule semble bonne. Moteur : 95%, Batterie : 87%, Freins : 94%. Prochain entretien dans 2 500 miles.',
          'maintenance':
              'Basé sur le kilométrage de votre véhicule, vous devez faire une vidange dans 2 500 miles et une rotation des pneus dans 1 200 miles.',
          'fuel':
              'Votre efficacité énergétique actuelle est de 32,5 MPG, c\'est au-dessus de la moyenne ! Voici quelques conseils pour l\'améliorer.',
          'problem':
              'Je suis là pour vous aider à résoudre les problèmes de véhicule. Pouvez-vous décrire ce qui se passe ?',
          'service_center':
              'J\'ai trouvé 5 centres de service près de vous. Le plus proche est AutoCare Plus, à 2,3 miles avec une note de 4,8 étoiles.',
          'thanks':
              'De rien ! Je suis toujours là pour vous aider avec les besoins de votre véhicule.',
          'default':
              'Je comprends que vous posez des questions sur votre véhicule. Je peux vous aider avec les vérifications de santé, la programmation d\'entretien et plus.',
        };
      case 'de-DE':
        return {
          'greeting':
              'Hallo! Ich bin Ihr KI-Fahrzeugassistent. Wie kann ich Ihnen heute helfen?',
          'health':
              'Die Gesundheit Ihres Fahrzeugs sieht gut aus. Motor: 95%, Batterie: 87%, Bremsen: 94%. Nächste Wartung in 2.500 Meilen.',
          'maintenance':
              'Basierend auf der Laufleistung Ihres Fahrzeugs benötigen Sie einen Ölwechsel in 2.500 Meilen und eine Reifenrotation in 1.200 Meilen.',
          'fuel':
              'Ihre aktuelle Kraftstoffeffizienz beträgt 32,5 MPG, das ist überdurchschnittlich! Hier sind einige Tipps zur Verbesserung.',
          'problem':
              'Ich bin hier, um Ihnen bei Fahrzeugproblemen zu helfen. Können Sie beschreiben, was passiert?',
          'service_center':
              'Ich habe 5 Servicezentren in Ihrer Nähe gefunden. Das nächste ist AutoCare Plus, 2,3 Meilen entfernt mit 4,8 Sternen.',
          'thanks':
              'Gern geschehen! Ich bin immer da, um Ihnen bei Ihren Fahrzeugbedürfnissen zu helfen.',
          'default':
              'Ich verstehe, dass Sie Fragen zu Ihrem Fahrzeug haben. Ich kann bei Gesundheitschecks, Wartungsplanung und mehr helfen.',
        };
      default:
        return {
          'greeting':
              'Hello! I\'m your AI vehicle assistant. How can I help you today?',
          'health':
              'Your vehicle health looks good! Engine: 95%, Battery: 87%, Brakes: 94%. Next maintenance due in 2,500 miles.',
          'maintenance':
              'Based on your vehicle\'s mileage, you\'re due for an oil change in 2,500 miles and tire rotation in 1,200 miles.',
          'fuel':
              'Your current fuel efficiency is 32.5 MPG, which is above average! Here are some tips to improve it further.',
          'problem':
              'I\'m here to help troubleshoot vehicle issues. Can you describe what\'s happening?',
          'service_center':
              'I found 5 service centers near you. The closest is AutoCare Plus, 2.3 miles away with a 4.8-star rating.',
          'thanks':
              'You\'re welcome! I\'m always here to help with your vehicle needs.',
          'default':
              'I understand you\'re asking about your vehicle. I can help with health checks, maintenance scheduling, and more.',
        };
    }
  }

  String _getDefaultResponse(String languageCode) {
    switch (languageCode) {
      case 'es-ES':
        return 'Lo siento, no pude entender completamente tu solicitud. ¿Puedes intentar de nuevo?';
      case 'fr-FR':
        return 'Désolé, je n\'ai pas pu comprendre complètement votre demande. Pouvez-vous réessayer ?';
      case 'de-DE':
        return 'Entschuldigung, ich konnte Ihre Anfrage nicht vollständig verstehen. Können Sie es erneut versuchen?';
      default:
        return 'I\'m sorry, I couldn\'t fully understand your request. Can you try again?';
    }
  }

  Map<String, String> _getErrorMessages(String languageCode) {
    switch (languageCode) {
      case 'es-ES':
        return {
          'network_error':
              'Error de conexión. Verifica tu conexión a internet.',
          'voice_error': 'Error de voz. Verifica los permisos del micrófono.',
          'ai_error': 'Error del asistente IA. Inténtalo de nuevo más tarde.',
          'default': 'Ocurrió un error. Inténtalo de nuevo.',
        };
      case 'fr-FR':
        return {
          'network_error':
              'Erreur de connexion. Vérifiez votre connexion internet.',
          'voice_error':
              'Erreur vocale. Vérifiez les permissions du microphone.',
          'ai_error': 'Erreur de l\'assistant IA. Réessayez plus tard.',
          'default': 'Une erreur s\'est produite. Réessayez.',
        };
      case 'de-DE':
        return {
          'network_error':
              'Verbindungsfehler. Überprüfen Sie Ihre Internetverbindung.',
          'voice_error':
              'Sprachfehler. Überprüfen Sie die Mikrofonberechtigungen.',
          'ai_error': 'KI-Assistentenfehler. Versuchen Sie es später erneut.',
          'default': 'Ein Fehler ist aufgetreten. Versuchen Sie es erneut.',
        };
      default:
        return {
          'network_error': 'Connection error. Check your internet connection.',
          'voice_error': 'Voice error. Check microphone permissions.',
          'ai_error': 'AI assistant error. Try again later.',
          'default': 'An error occurred. Please try again.',
        };
    }
  }
}

/// Language Option Model
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  @override
  String toString() => '$flag $nativeName ($name)';
}

