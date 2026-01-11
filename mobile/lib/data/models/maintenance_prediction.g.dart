// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_prediction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenancePrediction _$MaintenancePredictionFromJson(
        Map<String, dynamic> json) =>
    MaintenancePrediction(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      component: json['component'] as String,
      failureProbability: (json['failure_probability'] as num).toDouble(),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      recommendedAction: json['recommended_action'] as String,
      timeframeDays: (json['timeframe_days'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$MaintenancePredictionToJson(
        MaintenancePrediction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'component': instance.component,
      'failure_probability': instance.failureProbability,
      'confidence_score': instance.confidenceScore,
      'recommended_action': instance.recommendedAction,
      'timeframe_days': instance.timeframeDays,
      'created_at': instance.createdAt.toIso8601String(),
      'status': instance.status,
    };

