import 'package:json_annotation/json_annotation.dart';

part 'maintenance_prediction.g.dart';

@JsonSerializable()
class MaintenancePrediction {
  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final String component;
  @JsonKey(name: 'failure_probability')
  final double failureProbability;
  @JsonKey(name: 'confidence_score')
  final double confidenceScore;
  @JsonKey(name: 'recommended_action')
  final String recommendedAction;
  @JsonKey(name: 'timeframe_days')
  final int timeframeDays;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String status;

  MaintenancePrediction({
    required this.id,
    required this.vehicleId,
    required this.component,
    required this.failureProbability,
    required this.confidenceScore,
    required this.recommendedAction,
    required this.timeframeDays,
    required this.createdAt,
    this.status = 'pending',
  });

  factory MaintenancePrediction.fromJson(Map<String, dynamic> json) =>
      _$MaintenancePredictionFromJson(json);
  Map<String, dynamic> toJson() => _$MaintenancePredictionToJson(this);

  MaintenancePrediction copyWith({
    String? id,
    String? vehicleId,
    String? component,
    double? failureProbability,
    double? confidenceScore,
    String? recommendedAction,
    int? timeframeDays,
    DateTime? createdAt,
    String? status,
  }) {
    return MaintenancePrediction(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      component: component ?? this.component,
      failureProbability: failureProbability ?? this.failureProbability,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      timeframeDays: timeframeDays ?? this.timeframeDays,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  /// Get priority level based on failure probability
  PredictionPriority get priority {
    if (failureProbability >= 0.8) return PredictionPriority.critical;
    if (failureProbability >= 0.6) return PredictionPriority.high;
    if (failureProbability >= 0.4) return PredictionPriority.medium;
    return PredictionPriority.low;
  }

  /// Get urgency based on timeframe
  PredictionUrgency get urgency {
    if (timeframeDays <= 7) return PredictionUrgency.immediate;
    if (timeframeDays <= 30) return PredictionUrgency.soon;
    if (timeframeDays <= 90) return PredictionUrgency.moderate;
    return PredictionUrgency.low;
  }

  /// Check if prediction requires immediate attention
  bool get requiresImmediateAttention =>
      priority == PredictionPriority.critical ||
      urgency == PredictionUrgency.immediate;

  /// Get estimated failure date
  DateTime get estimatedFailureDate =>
      createdAt.add(Duration(days: timeframeDays));

  /// Check if prediction is still valid (not too old)
  bool get isValid {
    final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreated <= 30; // Predictions valid for 30 days
  }

  @override
  String toString() {
    return 'MaintenancePrediction(id: $id, component: $component, failureProbability: $failureProbability, timeframeDays: $timeframeDays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaintenancePrediction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum PredictionPriority { low, medium, high, critical }

enum PredictionUrgency { low, moderate, soon, immediate }

