// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: $enumDecodeNullable(_$MessageTypeEnumMap, json['type']) ??
          MessageType.text,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'isUser': instance.isUser,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$MessageTypeEnumMap[instance.type]!,
      'metadata': instance.metadata,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.voice: 'voice',
  MessageType.image: 'image',
  MessageType.vehicleData: 'vehicleData',
  MessageType.recommendation: 'recommendation',
  MessageType.alert: 'alert',
};

AIResponse _$AIResponseFromJson(Map<String, dynamic> json) => AIResponse(
      id: json['id'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AIResponseToJson(AIResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'confidence': instance.confidence,
      'suggestions': instance.suggestions,
      'metadata': instance.metadata,
    };

VehicleContext _$VehicleContextFromJson(Map<String, dynamic> json) =>
    VehicleContext(
      vehicleId: json['vehicleId'] as String,
      vehicleMake: json['vehicleMake'] as String,
      vehicleModel: json['vehicleModel'] as String,
      vehicleYear: (json['vehicleYear'] as num).toInt(),
      healthScore: (json['healthScore'] as num).toDouble(),
      odometer: (json['odometer'] as num).toInt(),
      lastServiceDate: json['lastServiceDate'] == null
          ? null
          : DateTime.parse(json['lastServiceDate'] as String),
      recentAlerts: (json['recentAlerts'] as List<dynamic>)
          .map((e) => VehicleAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
      telemetryData: json['telemetryData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$VehicleContextToJson(VehicleContext instance) =>
    <String, dynamic>{
      'vehicleId': instance.vehicleId,
      'vehicleMake': instance.vehicleMake,
      'vehicleModel': instance.vehicleModel,
      'vehicleYear': instance.vehicleYear,
      'healthScore': instance.healthScore,
      'odometer': instance.odometer,
      'lastServiceDate': instance.lastServiceDate?.toIso8601String(),
      'recentAlerts': instance.recentAlerts,
      'telemetryData': instance.telemetryData,
    };

VehicleAlert _$VehicleAlertFromJson(Map<String, dynamic> json) => VehicleAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: $enumDecode(_$AlertSeverityEnumMap, json['severity']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isAcknowledged: json['isAcknowledged'] as bool? ?? false,
    );

Map<String, dynamic> _$VehicleAlertToJson(VehicleAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'severity': _$AlertSeverityEnumMap[instance.severity]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'isAcknowledged': instance.isAcknowledged,
    };

const _$AlertSeverityEnumMap = {
  AlertSeverity.low: 'low',
  AlertSeverity.medium: 'medium',
  AlertSeverity.high: 'high',
  AlertSeverity.critical: 'critical',
};

Recommendation _$RecommendationFromJson(Map<String, dynamic> json) =>
    Recommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: $enumDecode(_$RecommendationPriorityEnumMap, json['priority']),
      category: $enumDecode(_$RecommendationCategoryEnumMap, json['category']),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      serviceCenter: json['serviceCenter'] as String?,
    );

Map<String, dynamic> _$RecommendationToJson(Recommendation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'priority': _$RecommendationPriorityEnumMap[instance.priority]!,
      'category': _$RecommendationCategoryEnumMap[instance.category]!,
      'dueDate': instance.dueDate?.toIso8601String(),
      'estimatedCost': instance.estimatedCost,
      'serviceCenter': instance.serviceCenter,
    };

const _$RecommendationPriorityEnumMap = {
  RecommendationPriority.low: 'low',
  RecommendationPriority.medium: 'medium',
  RecommendationPriority.high: 'high',
  RecommendationPriority.urgent: 'urgent',
};

const _$RecommendationCategoryEnumMap = {
  RecommendationCategory.maintenance: 'maintenance',
  RecommendationCategory.repair: 'repair',
  RecommendationCategory.upgrade: 'upgrade',
  RecommendationCategory.safety: 'safety',
  RecommendationCategory.performance: 'performance',
  RecommendationCategory.fuel: 'fuel',
};

ChatConversation _$ChatConversationFromJson(Map<String, dynamic> json) =>
    ChatConversation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      vehicleId: json['vehicleId'] as String?,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      title: json['title'] as String?,
    );

Map<String, dynamic> _$ChatConversationToJson(ChatConversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'vehicleId': instance.vehicleId,
      'messages': instance.messages,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'title': instance.title,
    };

