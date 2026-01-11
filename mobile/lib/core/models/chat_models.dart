import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

/// Chat message model
@JsonSerializable()
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  /// Create user message
  factory ChatMessage.user({
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      type: type,
      metadata: metadata,
    );
  }

  /// Create AI assistant message
  factory ChatMessage.assistant({
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      type: type,
      metadata: metadata,
    );
  }
}

/// Message types
enum MessageType {
  text,
  voice,
  image,
  vehicleData,
  recommendation,
  alert,
}

/// AI response model
@JsonSerializable()
class AIResponse {
  final String id;
  final String message;
  final DateTime timestamp;
  final double confidence;
  final List<String> suggestions;
  final Map<String, dynamic>? metadata;

  const AIResponse({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.confidence,
    required this.suggestions,
    this.metadata,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    // Handle OpenAI API response format
    if (json.containsKey('choices')) {
      final choices = json['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final choice = choices[0] as Map<String, dynamic>;
        final messageData = choice['message'] as Map<String, dynamic>;
        final message = messageData['content'] as String;

        return AIResponse(
          id: json['id'] as String? ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
          message: message,
          timestamp: DateTime.now(),
          confidence: 0.9, // Default confidence for OpenAI
          suggestions: [],
          metadata: json,
        );
      }
    }

    // Handle custom format
    return _$AIResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$AIResponseToJson(this);

  /// Convert to chat message
  ChatMessage toChatMessage() {
    return ChatMessage.assistant(
      content: message,
      metadata: {
        'confidence': confidence,
        'suggestions': suggestions,
        ...?metadata,
      },
    );
  }
}

/// Vehicle context for AI conversations
@JsonSerializable()
class VehicleContext {
  final String vehicleId;
  final String vehicleMake;
  final String vehicleModel;
  final int vehicleYear;
  final double healthScore;
  final int odometer;
  final DateTime? lastServiceDate;
  final List<VehicleAlert> recentAlerts;
  final Map<String, dynamic>? telemetryData;

  const VehicleContext({
    required this.vehicleId,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.healthScore,
    required this.odometer,
    this.lastServiceDate,
    required this.recentAlerts,
    this.telemetryData,
  });

  factory VehicleContext.fromJson(Map<String, dynamic> json) =>
      _$VehicleContextFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleContextToJson(this);
}

/// Vehicle alert model
@JsonSerializable()
class VehicleAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isAcknowledged;

  const VehicleAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.isAcknowledged = false,
  });

  factory VehicleAlert.fromJson(Map<String, dynamic> json) =>
      _$VehicleAlertFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleAlertToJson(this);
}

/// Alert severity levels
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// Recommendation model
@JsonSerializable()
class Recommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final RecommendationCategory category;
  final DateTime? dueDate;
  final double? estimatedCost;
  final String? serviceCenter;

  const Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    this.dueDate,
    this.estimatedCost,
    this.serviceCenter,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationToJson(this);
}

/// Recommendation priority levels
enum RecommendationPriority {
  low,
  medium,
  high,
  urgent,
}

/// Recommendation categories
enum RecommendationCategory {
  maintenance,
  repair,
  upgrade,
  safety,
  performance,
  fuel,
}

/// Chat conversation model
@JsonSerializable()
class ChatConversation {
  final String id;
  final String userId;
  final String? vehicleId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;

  const ChatConversation({
    required this.id,
    required this.userId,
    this.vehicleId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ChatConversationToJson(this);

  /// Add message to conversation
  ChatConversation addMessage(ChatMessage message) {
    return ChatConversation(
      id: id,
      userId: userId,
      vehicleId: vehicleId,
      messages: [...messages, message],
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      title: title,
    );
  }

  /// Get conversation title from first message
  String getDisplayTitle() {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }

    if (messages.isNotEmpty) {
      final firstMessage = messages.first.content;
      return firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage;
    }

    return 'New Conversation';
  }
}

