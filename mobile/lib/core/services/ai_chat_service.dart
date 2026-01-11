import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/chat_models.dart';
import '../config/app_config.dart';

/// AI Chat Service for intelligent vehicle assistance
class AIChatService {
  final Dio _dio;
  final Logger _logger;

  AIChatService({
    required Dio dio,
    required Logger logger,
  })  : _dio = dio,
        _logger = logger;

  /// Initialize the service
  Future<void> initialize() async {
    _logger.i('AIChatService initialized');
  }

  static AIChatService? _instance;
  static AIChatService get instance {
    _instance ??= AIChatService(dio: Dio(), logger: Logger());
    return _instance!;
  }

  /// Send a message to the AI and get a response
  Future<AIResponse> sendMessage({
    required String userId,
    required String message,
    VehicleContext? vehicleContext,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      _logger.i('Sending message to AI: $message');

      // Build context-aware prompt
      final prompt = _buildContextualPrompt(
        message: message,
        vehicleContext: vehicleContext,
        conversationHistory: conversationHistory,
      );

      // Call OpenAI API
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.openAIApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4',
          'messages': prompt,
          'max_tokens': 1000,
          'temperature': 0.7,
          'presence_penalty': 0.1,
          'frequency_penalty': 0.1,
        },
      );

      final aiResponse = AIResponse.fromJson(response.data!);

      _logger.i('AI response received successfully');
      return aiResponse;
    } catch (e) {
      _logger.e('Error sending message to AI: $e');

      // Return fallback response
      return AIResponse(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        message: _getFallbackResponse(message),
        timestamp: DateTime.now(),
        confidence: 0.5,
        suggestions: [],
      );
    }
  }

  /// Build contextual prompt with vehicle information
  List<Map<String, String>> _buildContextualPrompt({
    required String message,
    VehicleContext? vehicleContext,
    List<ChatMessage>? conversationHistory,
  }) {
    final messages = <Map<String, String>>[];

    // System prompt with vehicle context
    messages.add({
      'role': 'system',
      'content': _buildSystemPrompt(vehicleContext),
    });

    // Add conversation history (last 5 messages for context)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final recentHistory = conversationHistory.take(5).toList();
      for (final historyMessage in recentHistory) {
        messages.add({
          'role': historyMessage.isUser ? 'user' : 'assistant',
          'content': historyMessage.content,
        });
      }
    }

    // Add current user message
    messages.add({
      'role': 'user',
      'content': message,
    });

    return messages;
  }

  /// Build system prompt with vehicle context
  String _buildSystemPrompt(VehicleContext? vehicleContext) {
    const basePrompt = '''
You are AIVONITY, an intelligent vehicle assistant AI. You help vehicle owners with:
- Vehicle health monitoring and diagnostics
- Maintenance recommendations and scheduling
- Troubleshooting vehicle issues
- Explaining vehicle systems and components
- Providing safety and driving tips

Always be helpful, accurate, and safety-focused. If you're unsure about something, recommend consulting a professional mechanic.
''';

    if (vehicleContext == null) {
      return basePrompt;
    }

    final contextPrompt = '''
$basePrompt

Current Vehicle Context:
- Vehicle: ${vehicleContext.vehicleMake} ${vehicleContext.vehicleModel} ${vehicleContext.vehicleYear}
- Health Score: ${(vehicleContext.healthScore * 100).toInt()}%
- Odometer: ${vehicleContext.odometer} miles
- Last Service: ${vehicleContext.lastServiceDate?.toString() ?? 'Unknown'}

Recent Alerts:
${vehicleContext.recentAlerts.map((alert) => '- ${alert.title}: ${alert.description}').join('\n')}

Use this context to provide personalized recommendations and advice.
''';

    return contextPrompt;
  }

  /// Get fallback response when AI service is unavailable
  String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('health') ||
        lowerMessage.contains('diagnostic')) {
      return "I'm currently unable to connect to my AI service, but I can see your vehicle's health data in the dashboard. Please check the main screen for current diagnostics and alerts.";
    }

    if (lowerMessage.contains('maintenance') ||
        lowerMessage.contains('service')) {
      return "I'm having trouble connecting to my AI service right now. For maintenance questions, please check your vehicle's maintenance schedule in the app or consult your owner's manual.";
    }

    if (lowerMessage.contains('problem') || lowerMessage.contains('issue')) {
      return "I'm currently offline, but if you're experiencing a vehicle issue, please check for any active alerts in your dashboard. For urgent problems, contact a professional mechanic.";
    }

    return "I'm temporarily unable to connect to my AI service. Please try again in a moment, or check the app's dashboard for vehicle information.";
  }

  /// Get conversation history for a user
  Future<List<ChatMessage>> getConversationHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      // This would typically fetch from a backend API
      // For now, return empty list as we'll implement local storage
      return [];
    } catch (e) {
      _logger.e('Error fetching conversation history: $e');
      return [];
    }
  }

  /// Save chat message to history
  Future<void> saveChatMessage(ChatMessage message) async {
    try {
      // This would typically save to backend API
      // For now, we'll implement local storage later
      _logger.d('Saving chat message: ${message.content}');
    } catch (e) {
      _logger.e('Error saving chat message: $e');
    }
  }

  /// Get personalized recommendations based on vehicle data
  Future<List<Recommendation>> getPersonalizedRecommendations({
    required String userId,
    required VehicleContext vehicleContext,
  }) async {
    try {
      final prompt = '''
Based on this vehicle data, provide 3-5 specific maintenance or care recommendations:

Vehicle: ${vehicleContext.vehicleMake} ${vehicleContext.vehicleModel} ${vehicleContext.vehicleYear}
Health Score: ${(vehicleContext.healthScore * 100).toInt()}%
Odometer: ${vehicleContext.odometer} miles
Recent Alerts: ${vehicleContext.recentAlerts.map((a) => a.title).join(', ')}

Provide actionable recommendations in JSON format.
''';

      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.openAIApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a vehicle maintenance expert. Provide recommendations in JSON format.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 500,
          'temperature': 0.3,
        },
      );

      // Parse recommendations from AI response
      return _parseRecommendations(
        response.data!['choices'][0]['message']['content'] as String,
      );
    } catch (e) {
      _logger.e('Error getting recommendations: $e');
      return _getDefaultRecommendations(vehicleContext);
    }
  }

  /// Parse AI recommendations response
  List<Recommendation> _parseRecommendations(String aiResponse) {
    try {
      // Try to parse JSON response
      final jsonData = jsonDecode(aiResponse);
      return (jsonData['recommendations'] as List)
          .map((item) => Recommendation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to text parsing
      return [
        Recommendation(
          id: 'ai_rec_1',
          title: 'AI Recommendation',
          description: aiResponse,
          priority: RecommendationPriority.medium,
          category: RecommendationCategory.maintenance,
        ),
      ];
    }
  }

  /// Get default recommendations when AI is unavailable
  List<Recommendation> _getDefaultRecommendations(
    VehicleContext vehicleContext,
  ) {
    final recommendations = <Recommendation>[];

    // Health score based recommendations
    if (vehicleContext.healthScore < 0.7) {
      recommendations.add(
        const Recommendation(
          id: 'health_check',
          title: 'Schedule Health Check',
          description:
              'Your vehicle health score is below optimal. Consider scheduling a diagnostic check.',
          priority: RecommendationPriority.high,
          category: RecommendationCategory.maintenance,
        ),
      );
    }

    // Mileage based recommendations
    if (vehicleContext.odometer > 0 && vehicleContext.odometer % 5000 < 500) {
      recommendations.add(
        const Recommendation(
          id: 'oil_change',
          title: 'Oil Change Due',
          description: 'Based on your mileage, an oil change may be due soon.',
          priority: RecommendationPriority.medium,
          category: RecommendationCategory.maintenance,
        ),
      );
    }

    return recommendations;
  }
}

/// Provider for AI Chat Service
final aiChatServiceProvider = Provider<AIChatService>((ref) {
  final dio = Dio();
  final logger = Logger();

  return AIChatService(
    dio: dio,
    logger: logger,
  );
});

