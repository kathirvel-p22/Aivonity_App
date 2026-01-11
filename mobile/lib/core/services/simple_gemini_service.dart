import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Simplified Gemini AI Service for basic AI chat functionality
class SimpleGeminiService {
  static SimpleGeminiService? _instance;
  static SimpleGeminiService get instance =>
      _instance ??= SimpleGeminiService._();

  SimpleGeminiService._();

  final Dio _dio = Dio();
  final Logger _logger = Logger();

  // Gemini API Configuration
  static String? _apiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  String _currentLanguage = 'en';

  /// Initialize the service
  Future<void> initialize() async {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Don't set a default API key - user must configure their own
    // This ensures real Gemini API functionality instead of fallback
    if (_apiKey == null || _apiKey!.isEmpty) {
      _apiKey = null; // Force user to configure valid key
    }

    _logger.i('Simple Gemini AI Service initialized');
  }

  /// Configure the API key
  static void configureApiKey(String apiKey) {
    _apiKey = apiKey.trim();
  }

  /// Get API key status (for debugging)
  static String? getApiKeyStatus() {
    if (_apiKey == null) return 'null';
    if (_apiKey!.isEmpty) return 'empty';
    return 'configured (${_apiKey!.substring(0, 10)}...)';
  }

  /// Send a message to Gemini AI
  Future<String> sendMessage(String message, {String? language}) async {
    try {
      final conversationLanguage = language ?? _currentLanguage;

      final prompt = '''
You are AIVONITY, an AI assistant for vehicle management. Help users with vehicle-related questions about maintenance, diagnostics, navigation, and fuel efficiency.

${conversationLanguage != 'en' ? 'Respond in $conversationLanguage.' : ''}

User: $message

Provide a helpful, concise response focused on vehicle topics.
''';

      final response = await _dio.post(
        '/models/gemini-1.5-flash:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 512,
          },
        },
      );

      final responseData = response.data;
      final candidates = responseData['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }

      return 'I apologize, but I\'m having trouble processing your request right now.';
    } catch (e) {
      _logger.e('Error with Gemini AI: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  /// Set language
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
  }

  /// Get supported languages (simplified list)
  List<String> getSupportedLanguages() {
    return ['en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh'];
  }
}

