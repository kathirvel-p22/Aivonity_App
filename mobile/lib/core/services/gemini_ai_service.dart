import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fallback_ai_service.dart';

/// Gemini AI Service for advanced AI chat and voice interactions
class GeminiAIService {
  static GeminiAIService? _instance;
  static GeminiAIService get instance => _instance ??= GeminiAIService._();

  GeminiAIService._();

  final Dio _dio = Dio();
  final Logger _logger = Logger();

  // Gemini API Configuration - Updated for current API
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  // API Key - should be configured via environment or secure storage
  static String? _apiKey;

  // Conversation history and state
  final List<ChatMessage> _conversationHistory = [];
  String _currentLanguage = 'en';

  // Conversation state tracking
  final Map<String, dynamic> _conversationState = {
    'current_topic': null,
    'user_preferences': {},
    'ongoing_tasks': [],
    'mentioned_locations': [],
    'vehicle_focus': null,
  };

  // Voice AI settings
  bool _voiceEnabled = true;
  double _voiceSpeed = 1.0;
  String _voiceGender = 'female';

  // Getters
  List<ChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);
  String get currentLanguage => _currentLanguage;
  bool get voiceEnabled => _voiceEnabled;

  /// Initialize the Gemini AI service
  Future<void> initialize() async {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Load API key from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key');

    // Don't set a default API key - user must configure their own
    // This ensures real Gemini API functionality instead of fallback
    if (_apiKey == null || _apiKey!.isEmpty) {
      _apiKey = null; // Force user to configure valid key
    }

    _logger.i(
      'Gemini AI Service initialized with API key: ${_apiKey?.substring(0, 10)}...',
    );
  }

  /// Configure the API key
  static Future<void> configureApiKey(String apiKey) async {
    _apiKey = apiKey.trim();

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKey!);

    instance._logger
        .i('API key configured and saved: ${_apiKey?.substring(0, 10)}...');
  }

  /// Get API key status (for debugging)
  static String? getApiKeyStatus() {
    if (_apiKey == null) return 'null';
    if (_apiKey!.isEmpty) return 'empty';
    return 'configured (${_apiKey!.substring(0, 10)}...)';
  }

  /// Test API key validity
  Future<bool> testApiKey() async {
    try {
      _logger.i('Testing API key validity...');
      final response = await _dio.post(
        '/models/gemini-1.5-flash:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Hello, this is a test message. Please respond with "API key is working".',
                }
              ],
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 50,
          },
        },
      );

      final responseData = response.data;
      final candidates = responseData['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        _logger.i('API key test successful');
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('API key test failed: $e');
      return false;
    }
  }

  /// Send a text message to Gemini AI
  Future<AIResponse> sendMessage(
    String message, {
    String? language,
    Map<String, dynamic>? context,
    bool includeVehicleData = true,
  }) async {
    // Set language for this conversation
    final conversationLanguage = language ?? _currentLanguage;

    try {
      // Check if API key is configured
      _logger.i('Checking API key status: ${getApiKeyStatus()}');
      if (_apiKey == null || _apiKey!.isEmpty) {
        _logger.w('API key not configured, returning setup message');
        return AIResponse(
          message:
              '🚀 Welcome to AIVONITY AI Chat!\n\nI\'m your intelligent conversational AI assistant, powered by Google Gemini. I can chat about any topic - from general conversation to vehicle assistance.\n\nTo get started:\n1. Visit https://makersuite.google.com/app/apikey\n2. Create a free Gemini API key\n3. Tap the 🔑 key icon above to enter your key\n\nThen we can have natural conversations about anything you want! 💬',
          language: conversationLanguage,
          confidence: 0.0,
          error: 'API key not configured',
        );
      }

      _logger.i(
        'Sending message to Gemini AI: ${message.substring(0, min(50, message.length))}...',
      );

      // Prepare context with vehicle data if requested
      final vehicleContext = includeVehicleData ? _getVehicleContext() : {};
      final fullContext = {...vehicleContext, ...?context};

      // Build conversation history for context
      final conversationContext = _buildConversationContext();

      // Create the prompt with context
      final prompt = _buildPrompt(
        message,
        conversationLanguage,
        fullContext.cast<String, dynamic>(),
        conversationContext,
      );

      _logger.i(
        'Built prompt: ${prompt.substring(0, min(100, prompt.length))}...',
      );

      // Make API request to current Gemini API - simplified for testing
      final requestData = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              }
            ],
          }
        ],
        'generationConfig': {
          'temperature':
              0.3, // Lower temperature for more consistent, factual responses
          'maxOutputTokens': 1024,
          'topP': 0.8,
          'topK': 40,
        },
      };

      _logger.i(
        'Making API request to: ${_dio.options.baseUrl}/models/gemini-1.5-flash:generateContent?key=${_apiKey?.substring(0, 10)}...',
      );
      _logger.d('Request data: $requestData');

      final response = await _dio.post(
        '/models/gemini-1.5-flash:generateContent?key=$_apiKey',
        data: requestData,
      );

      _logger.i('Received response with status: ${response.statusCode}');
      _logger.d('Response data: ${response.data}');

      // Parse response
      final responseData = response.data;
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No response from Gemini AI');
      }

      final content = candidates[0]['content'] as Map?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Invalid response format from Gemini AI');
      }

      final aiMessage = parts[0]['text'] as String;

      // Update conversation state before adding messages
      _updateConversationState(message, aiMessage);

      // Add to conversation history
      _conversationHistory.add(
        ChatMessage(
          role: MessageRole.user,
          content: message,
          timestamp: DateTime.now(),
          language: conversationLanguage,
        ),
      );

      _conversationHistory.add(
        ChatMessage(
          role: MessageRole.assistant,
          content: aiMessage,
          timestamp: DateTime.now(),
          language: conversationLanguage,
        ),
      );

      // Keep only last 20 messages to avoid token limits
      if (_conversationHistory.length > 20) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 20);
      }

      _logger.i('Received response from Gemini AI');

      return AIResponse(
        message: aiMessage,
        language: conversationLanguage,
        confidence: 0.9, // Gemini doesn't provide confidence scores
        tokensUsed:
            (responseData['usageMetadata']?['totalTokenCount'] as int?) ?? 0,
        suggestions: _extractSuggestions(aiMessage),
      );
    } catch (e) {
      _logger.e('Error communicating with Gemini AI: $e');
      _logger
          .e('API Key configured: ${_apiKey != null && _apiKey!.isNotEmpty}');
      _logger.e('API Key length: ${_apiKey?.length}');
      _logger.e('Base URL: $_baseUrl');

      if (e is DioException) {
        _logger.e('Dio Error Type: ${e.type}');
        _logger.e('Dio Error Message: ${e.message}');
        _logger.e('HTTP Status Code: ${e.response?.statusCode}');
        _logger.e('Response Data: ${e.response?.data}');
        _logger.e('Request URL: ${e.requestOptions.uri}');
        _logger.e('Request Method: ${e.requestOptions.method}');
        _logger.e('Request Headers: ${e.requestOptions.headers}');

        // Check for specific API errors
        if (e.response?.statusCode == 400) {
          _logger.e('Bad Request - Check API key and request format');
        } else if (e.response?.statusCode == 403) {
          _logger.e(
            'Forbidden - API key may be invalid or not have proper permissions',
          );
        } else if (e.response?.statusCode == 404) {
          _logger.e('Not Found - API endpoint may be incorrect');
        } else if (e.response?.statusCode == 429) {
          _logger.e('Rate Limited - Too many requests');
        }
      }

      // Try fallback AI service for basic responses
      _logger.i('API failed, trying fallback AI service...');
      try {
        final fallbackResponse = FallbackAIService.instance.getFallbackResponse(
          message,
          language: conversationLanguage,
        );

        // Add to conversation history
        _conversationHistory.add(
          ChatMessage(
            role: MessageRole.user,
            content: message,
            timestamp: DateTime.now(),
            language: conversationLanguage,
          ),
        );

        _conversationHistory.add(
          ChatMessage(
            role: MessageRole.assistant,
            content: fallbackResponse,
            timestamp: DateTime.now(),
            language: conversationLanguage,
          ),
        );

        // Keep only last 20 messages to avoid token limits
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 20);
        }

        _logger.i('Fallback AI response provided successfully');

        return AIResponse(
          message: fallbackResponse,
          language: conversationLanguage,
          confidence: 0.7, // Lower confidence for fallback responses
          suggestions: _extractSuggestions(fallbackResponse),
          error: 'Using fallback AI service (API unavailable)',
        );
      } catch (fallbackError) {
        _logger.e('Fallback AI service also failed: $fallbackError');

        // Return a more specific error message
        String errorMessage =
            'I apologize, but I\'m having trouble processing your request right now. ';
        if (e is DioException && e.response?.statusCode == 403) {
          errorMessage +=
              'It seems there might be an issue with the API key configuration.';
        } else if (e is DioException && e.response?.statusCode == 400) {
          errorMessage +=
              'There appears to be an issue with the request format.';
        } else {
          errorMessage += 'Please try again.';
        }

        return AIResponse(
          message: errorMessage,
          language: _currentLanguage,
          confidence: 0.0,
          error: e.toString(),
        );
      }
    }
  }

  /// Send a voice message to Gemini AI with speech-to-text
  Future<AIResponse> sendVoiceMessage(
    String transcribedText, {
    String? detectedLanguage,
    Map<String, dynamic>? audioMetadata,
  }) async {
    try {
      // Add voice context to the message
      final voiceContext = {
        'input_method': 'voice',
        'detected_language': detectedLanguage ?? _currentLanguage,
        'audio_metadata': audioMetadata,
      };

      return await sendMessage(
        transcribedText,
        language: detectedLanguage,
        context: voiceContext,
      );
    } catch (e) {
      _logger.e('Error processing voice message: $e');
      return AIResponse(
        message:
            'I\'m sorry, I couldn\'t process your voice message. Please try again.',
        language: _currentLanguage,
        confidence: 0.0,
        error: e.toString(),
      );
    }
  }

  /// Translate text using Gemini AI
  Future<String> translateText(
    String text,
    String targetLanguage, {
    String? sourceLanguage,
  }) async {
    try {
      final prompt = '''
Translate the following text to $targetLanguage.
${sourceLanguage != null ? 'The source language is $sourceLanguage.' : ''}
Provide only the translation, no additional text.

Text: "$text"
''';

      final response = await _dio.post(
        '/models/gemini-1.5-flash:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                }
              ],
            }
          ],
          'generationConfig': {
            'temperature': 0.1, // Low temperature for accurate translation
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

      return text; // Return original text if translation fails
    } catch (e) {
      _logger.e('Error translating text: $e');
      // Return original text for fallback
      return text;
    }
  }

  /// Analyze sentiment of text using Gemini AI
  Future<SentimentAnalysis> analyzeSentiment(String text) async {
    try {
      final prompt = '''
Analyze the sentiment of the following text. Respond with only a JSON object containing:
- sentiment: "positive", "negative", or "neutral"
- confidence: a number between 0 and 1
- emotions: array of detected emotions (if any)

Text: "$text"
''';

      final response = await _dio.post(
        '/models/gemini-1.5-flash:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                }
              ],
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 256,
          },
        },
      );

      final responseData = response.data;
      final candidates = responseData['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final jsonStr = parts[0]['text'] as String;
          try {
            final jsonData = jsonDecode(jsonStr);
            return SentimentAnalysis(
              sentiment: (jsonData['sentiment'] as String?) ?? 'neutral',
              confidence: (jsonData['confidence'] as num?)?.toDouble() ?? 0.5,
              emotions:
                  List<String>.from((jsonData['emotions'] as List?) ?? []),
            );
          } catch (e) {
            _logger.w('Failed to parse sentiment analysis JSON: $e');
          }
        }
      }

      // Fallback sentiment analysis
      return _fallbackSentimentAnalysis(text);
    } catch (e) {
      _logger.e('Error analyzing sentiment: $e');
      // Fallback sentiment analysis
      return _fallbackSentimentAnalysis(text);
    }
  }

  /// Fallback sentiment analysis using simple keyword matching
  SentimentAnalysis _fallbackSentimentAnalysis(String text) {
    final lowerText = text.toLowerCase();

    // Simple keyword-based sentiment analysis
    final positiveWords = [
      'good',
      'great',
      'excellent',
      'amazing',
      'love',
      'happy',
      'satisfied',
      'perfect',
      'awesome',
    ];
    final negativeWords = [
      'bad',
      'terrible',
      'awful',
      'hate',
      'angry',
      'disappointed',
      'poor',
      'worst',
      'horrible',
    ];

    final int positiveCount =
        positiveWords.where((word) => lowerText.contains(word)).length;
    final int negativeCount =
        negativeWords.where((word) => lowerText.contains(word)).length;

    String sentiment;
    double confidence;

    if (positiveCount > negativeCount) {
      sentiment = 'positive';
      confidence = 0.7;
    } else if (negativeCount > positiveCount) {
      sentiment = 'negative';
      confidence = 0.7;
    } else {
      sentiment = 'neutral';
      confidence = 0.5;
    }

    return SentimentAnalysis(
      sentiment: sentiment,
      confidence: confidence,
      emotions: [],
    );
  }

  /// Generate AI suggestions for better interaction based on conversation context
  Future<List<String>> generateSuggestions(String currentContext) async {
    try {
      final currentTopic = _conversationState['current_topic'] ?? 'general';
      final userPreferences = _conversationState['user_preferences'] ?? {};
      final mentionedLocations =
          _conversationState['mentioned_locations'] ?? [];

      final prompt = '''
Based on the current conversation context and topic, suggest 3-5 relevant follow-up questions or topics that would continue this natural conversation. Consider the user's interests and the current topic.

Current Topic: $currentTopic
User Preferences: ${jsonEncode(userPreferences)}
Mentioned Locations: ${jsonEncode(mentionedLocations)}
Conversation Context: "$currentContext"

Suggest natural follow-up questions or conversation starters that would flow naturally from this discussion. Make them engaging and conversational, not robotic commands.

Respond with only a JSON array of strings, no additional text.
''';

      final response = await _dio.post(
        '/models/gemini-1.5-flash:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                }
              ],
            }
          ],
          'generationConfig': {
            'temperature': 0.9, // Higher creativity for suggestions
            'maxOutputTokens': 256,
          },
        },
      );

      final responseData = response.data;
      final candidates = responseData['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final jsonStr = parts[0]['text'] as String;
          try {
            final suggestions =
                List<String>.from((jsonDecode(jsonStr) as List?) ?? []);
            return suggestions.take(5).toList();
          } catch (e) {
            _logger.w('Failed to parse suggestions JSON: $e');
          }
        }
      }

      return _getDefaultSuggestions();
    } catch (e) {
      _logger.e('Error generating suggestions: $e');
      return _getDefaultSuggestions();
    }
  }

  /// Set the current language for conversations
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    _logger.i('Language set to: $languageCode');
  }

  /// Configure voice AI settings
  void configureVoice({
    bool? enabled,
    double? speed,
    String? gender,
  }) {
    if (enabled != null) _voiceEnabled = enabled;
    if (speed != null) _voiceSpeed = speed.clamp(0.5, 2.0);
    if (gender != null) _voiceGender = gender;

    _logger.i(
      'Voice settings updated: enabled=$_voiceEnabled, speed=$_voiceSpeed, gender=$_voiceGender',
    );
  }

  /// Validate and correct AI response for consistency and accuracy
  String _validateAndCorrectResponse(String response, String userMessage) {
    // Check for common hallucination patterns
    final lowerResponse = response.toLowerCase();
    final lowerUserMessage = userMessage.toLowerCase();

    // If user asked about navigation but response doesn't mention it, add clarification
    if ((lowerUserMessage.contains('navigate') ||
            lowerUserMessage.contains('route') ||
            lowerUserMessage.contains('directions') ||
            lowerUserMessage.contains('traffic')) &&
        !lowerResponse.contains('google maps') &&
        !lowerResponse.contains('navigation') &&
        !lowerResponse.contains('route')) {
      return '$response\n\nI can help you with navigation! Would you like me to open Google Maps with directions or check current traffic conditions?';
    }

    // If response mentions features not available, correct it
    if (lowerResponse.contains('i can show you') ||
        lowerResponse.contains('i\'ll display') ||
        lowerResponse.contains('here\'s the map')) {
      return response
          .replaceAll('i can show you', 'I can open Google Maps for you to see')
          .replaceAll('i\'ll display', 'I can open Google Maps for you to see')
          .replaceAll(
            'here\'s the map',
            'I can open Google Maps for you to see',
          );
    }

    // Ensure response acknowledges conversation context
    if (_conversationHistory.isNotEmpty &&
        !lowerResponse.contains('previously') &&
        !lowerResponse.contains('earlier') &&
        !lowerResponse.contains('before')) {
      // Add context acknowledgment for follow-up questions
      if (lowerUserMessage.contains('what') ||
          lowerUserMessage.contains('how') ||
          lowerUserMessage.contains('where') ||
          lowerUserMessage.contains('when')) {
        return 'Based on our previous conversation, $response';
      }
    }

    return response;
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
    _conversationState.clear();
    _conversationState.addAll({
      'current_topic': null,
      'user_preferences': {},
      'ongoing_tasks': [],
      'mentioned_locations': [],
      'vehicle_focus': null,
    });
    _logger.i('Conversation history and state cleared');
  }

  /// Update conversation state based on user message and AI response
  void _updateConversationState(String userMessage, String aiResponse) {
    final lowerUserMessage = userMessage.toLowerCase();
    final lowerAiResponse = aiResponse.toLowerCase();

    // Track current topic - expanded to cover any conversation topic
    if (lowerUserMessage.contains('navigation') ||
        lowerUserMessage.contains('route') ||
        lowerUserMessage.contains('directions') ||
        lowerUserMessage.contains('traffic') ||
        lowerUserMessage.contains('drive') ||
        lowerUserMessage.contains('travel')) {
      _conversationState['current_topic'] = 'navigation';
    } else if (lowerUserMessage.contains('maintenance') ||
        lowerUserMessage.contains('service') ||
        lowerUserMessage.contains('repair') ||
        lowerUserMessage.contains('car') ||
        lowerUserMessage.contains('vehicle') ||
        lowerUserMessage.contains('auto')) {
      _conversationState['current_topic'] = 'automotive';
    } else if (lowerUserMessage.contains('fuel') ||
        lowerUserMessage.contains('gas') ||
        lowerUserMessage.contains('efficiency') ||
        lowerUserMessage.contains('mileage')) {
      _conversationState['current_topic'] = 'fuel_efficiency';
    } else if (lowerUserMessage.contains('weather') ||
        lowerUserMessage.contains('temperature') ||
        lowerUserMessage.contains('forecast')) {
      _conversationState['current_topic'] = 'weather';
    } else if (lowerUserMessage.contains('food') ||
        lowerUserMessage.contains('restaurant') ||
        lowerUserMessage.contains('eat') ||
        lowerUserMessage.contains('cook')) {
      _conversationState['current_topic'] = 'food';
    } else if (lowerUserMessage.contains('movie') ||
        lowerUserMessage.contains('film') ||
        lowerUserMessage.contains('watch') ||
        lowerUserMessage.contains('entertainment')) {
      _conversationState['current_topic'] = 'entertainment';
    } else if (lowerUserMessage.contains('help') ||
        lowerUserMessage.contains('how') ||
        lowerUserMessage.contains('what') ||
        lowerUserMessage.contains('why')) {
      _conversationState['current_topic'] = 'general_help';
    } else {
      // For any other topic, try to infer from context
      _conversationState['current_topic'] = 'general_conversation';
    }

    // Track mentioned locations (expanded patterns)
    final locationPatterns = [
      RegExp(
        r'\b(?:to|from|at|near|in|around|nearby)\s+([A-Za-z\s,]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'\b([A-Za-z\s,]+(?:city|town|state|country|place))\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in locationPatterns) {
      final matches = pattern.allMatches(userMessage);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final location = match.group(1)?.trim();
          if (location != null &&
              location.length > 2 &&
              !location.contains('the ') &&
              !location.contains(' a ')) {
            final locations =
                _conversationState['mentioned_locations'] as List? ?? [];
            if (!locations.contains(location)) {
              locations.add(location);
              _conversationState['mentioned_locations'] = locations;
            }
          }
        }
      }
    }

    // Track user interests and preferences from conversation
    if (lowerUserMessage.contains('i like') ||
        lowerUserMessage.contains('i love') ||
        lowerUserMessage.contains('i prefer')) {
      final preferences = _conversationState['user_preferences'] as Map? ?? {};
      // Extract preferences (simplified)
      if (lowerUserMessage.contains('music')) preferences['music'] = true;
      if (lowerUserMessage.contains('sports')) preferences['sports'] = true;
      if (lowerUserMessage.contains('food')) preferences['food'] = true;
      if (lowerUserMessage.contains('travel')) preferences['travel'] = true;
      _conversationState['user_preferences'] = preferences;
    }

    // Track ongoing tasks and actions
    if (lowerAiResponse.contains('opening') ||
        lowerAiResponse.contains('showing') ||
        lowerAiResponse.contains('navigating') ||
        lowerAiResponse.contains('searching') ||
        lowerAiResponse.contains('finding')) {
      final tasks = _conversationState['ongoing_tasks'] as List? ?? [];
      if (lowerAiResponse.contains('navigation') ||
          lowerAiResponse.contains('route')) {
        if (!tasks.contains('navigation_active')) {
          tasks.add('navigation_active');
        }
      }
      if (lowerAiResponse.contains('traffic')) {
        if (!tasks.contains('traffic_check')) tasks.add('traffic_check');
      }
      if (lowerAiResponse.contains('searching') ||
          lowerAiResponse.contains('finding')) {
        if (!tasks.contains('search_active')) tasks.add('search_active');
      }
      _conversationState['ongoing_tasks'] = tasks;
    }
  }

  /// Get supported languages
  List<String> getSupportedLanguages() {
    return [
      'en',
      'es',
      'fr',
      'de',
      'it',
      'pt',
      'ru',
      'ja',
      'ko',
      'zh',
      'ar',
      'hi',
      'bn',
      'ur',
      'fa',
      'tr',
      'pl',
      'nl',
      'sv',
      'da',
      'no',
      'fi',
      'cs',
      'sk',
      'hu',
      'ro',
      'bg',
      'hr',
      'sl',
      'et',
      'lv',
      'lt',
      'mt',
      'ga',
      'cy',
      'eu',
      'is',
      'fo',
      'kl',
    ];
  }

  // Private helper methods
  String _buildPrompt(
    String message,
    String language,
    Map<String, dynamic> context,
    String conversationContext,
  ) {
    final languageInstruction =
        language != 'en' ? 'Respond in $language. ' : '';

    return '''
You are AIVONITY, an advanced AI assistant powered by Google Gemini. You are a helpful, intelligent conversational AI similar to ChatGPT or Gemini, capable of discussing any topic while having specialized expertise in vehicle telematics, navigation, and automotive assistance.

${languageInstruction}You are having a natural, continuous conversation with the user. Be friendly, helpful, and engaging. Reference previous messages when relevant and maintain conversation flow. You can discuss ANY topic the user wants - from general knowledge, current events, entertainment, advice, to vehicle-specific topics.

CORE PRINCIPLES:
- CONVERSATIONAL: Respond naturally like a human conversation, not a robotic assistant
- KNOWLEDGEABLE: Draw from vast knowledge on any topic
- HELPFUL: Provide useful information and assistance
- CONSISTENT: Reference and maintain information from previous messages
- HONEST: Admit when you don't know something
- ENGAGING: Keep conversations interesting and follow up appropriately

SPECIALIZED CAPABILITIES (when relevant):
- Real-time GPS navigation and route planning
- Live traffic updates and congestion analysis
- Vehicle maintenance and diagnostics
- Fuel efficiency optimization
- Emergency assistance and roadside help
- Google Maps integration for visual guidance

Vehicle Context: ${context.isNotEmpty ? jsonEncode(context) : 'General conversation - no specific vehicle focus'}

Current Location: ${context['current_location'] ?? 'Location available when needed'}

Conversation State: ${jsonEncode(_conversationState)}

Recent Conversation History:
$conversationContext

Current User Message: $message

RESPONSE GUIDELINES:
1. CONVERSE NATURALLY: Respond as if chatting with a friend - be engaging and conversational
2. BE COMPREHENSIVE: Answer any question or discuss any topic the user brings up
3. MAINTAIN CONTEXT: Reference previous parts of the conversation when relevant
4. USE EXPERTISE: When vehicle/navigation topics come up, provide specialized knowledge
5. BE ACTIONABLE: For navigation/vehicle queries, offer to open Google Maps or provide specific help
6. KEEP IT INTERESTING: Ask follow-up questions or provide additional relevant information

For vehicle/navigation topics, you can offer to:
- Open Google Maps for live traffic, directions, or location search
- Provide vehicle maintenance advice
- Give fuel efficiency tips
- Help with emergency situations

Remember: You're a general-purpose AI assistant with vehicle expertise. Have natural conversations about any topic while being ready to help with automotive needs when they arise.
''';
  }

  Map<String, dynamic> _getVehicleContext() {
    // This would normally get real vehicle data from services
    return {
      'vehicle_type': 'Tesla Model 3',
      'year': '2023',
      'mileage': '15420',
      'fuel_efficiency': '28.5 MPG',
      'last_service': '2024-01-15',
      'next_service_due': '2024-07-15',
      'health_score': '92%',
      'active_alerts': ['Oil change due in 500 miles'],
    };
  }

  String _buildConversationContext() {
    if (_conversationHistory.isEmpty) return 'No previous conversation.';

    final recentMessages =
        _conversationHistory.take(12); // Last 6 exchanges for better continuity
    final contextParts = <String>[];

    for (final message in recentMessages) {
      final role = message.role == MessageRole.user ? 'User' : 'Assistant';
      // Truncate long messages to avoid token limits
      final content = message.content.length > 200
          ? '${message.content.substring(0, 200)}...'
          : message.content;
      contextParts.add('$role: $content');
    }

    return contextParts.join('\n');
  }

  List<String> _extractSuggestions(String aiMessage) {
    // Simple extraction - in a real implementation, this could be more sophisticated
    final suggestions = <String>[];

    if (aiMessage.contains('maintenance') || aiMessage.contains('service')) {
      suggestions.add('Schedule maintenance');
      suggestions.add('Check service history');
    }

    if (aiMessage.contains('fuel') || aiMessage.contains('efficiency')) {
      suggestions.add('Show fuel efficiency');
      suggestions.add('Fuel saving tips');
    }

    if (aiMessage.contains('navigation') || aiMessage.contains('route')) {
      suggestions.add('Plan a route');
      suggestions.add('Find nearby services');
    }

    // Add some general suggestions
    if (suggestions.length < 3) {
      suggestions.addAll(
        [
          'Check vehicle health',
          'View analytics',
          'Emergency contacts',
        ].where((s) => !suggestions.contains(s)).take(3 - suggestions.length),
      );
    }

    return suggestions.take(3).toList();
  }

  List<String> _getDefaultSuggestions() {
    final currentTopic = _conversationState['current_topic'] ?? 'general';

    // Return topic-specific suggestions
    switch (currentTopic) {
      case 'navigation':
        return [
          'What\'s the traffic like right now?',
          'Find a good restaurant nearby',
          'How long will it take to get there?',
          'Are there any detours I should know about?',
        ];
      case 'automotive':
        return [
          'How\'s my vehicle doing?',
          'Any maintenance reminders?',
          'Tips for better fuel efficiency?',
          'What\'s the best route for my car?',
        ];
      case 'weather':
        return [
          'Will it rain today?',
          'What\'s the forecast for tomorrow?',
          'Should I bring an umbrella?',
          'What\'s the temperature like?',
        ];
      case 'food':
        return [
          'What are you in the mood for?',
          'Any good restaurants nearby?',
          'Want me to find a recipe?',
          'What\'s your favorite cuisine?',
        ];
      case 'entertainment':
        return [
          'What movies are you watching?',
          'Any good shows you recommend?',
          'What\'s new on streaming?',
          'Want to hear about current events?',
        ];
      default:
        return [
          'Tell me about yourself',
          'What\'s on your mind today?',
          'Need help with navigation?',
          'Want to chat about anything?',
          'How can I assist you?',
        ];
    }
  }

  int min(int a, int b) => a < b ? a : b;
}

// Data Models
enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final String language;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    required this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'language': language,
    };
  }
}

class AIResponse {
  final String message;
  final String language;
  final double confidence;
  final int tokensUsed;
  final List<String> suggestions;
  final String? error;

  const AIResponse({
    required this.message,
    required this.language,
    required this.confidence,
    this.tokensUsed = 0,
    this.suggestions = const [],
    this.error,
  });

  bool get hasError => error != null;
}

class SentimentAnalysis {
  final String sentiment;
  final double confidence;
  final List<String> emotions;

  const SentimentAnalysis({
    required this.sentiment,
    required this.confidence,
    required this.emotions,
  });
}

