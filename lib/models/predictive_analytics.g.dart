// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'predictive_analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenancePrediction _$MaintenancePredictionFromJson(
  Map<String, dynamic> json,
) => MaintenancePrediction(
  vehicleId: json['vehicleId'] as String,
  componentId: json['componentId'] as String,
  componentName: json['componentName'] as String,
  predictedFailureDate: DateTime.parse(json['predictedFailureDate'] as String),
  confidenceScore: (json['confidenceScore'] as num).toDouble(),
  priority: $enumDecode(_$MaintenancePriorityEnumMap, json['priority']),
  symptoms: (json['symptoms'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  estimatedCost: (json['estimatedCost'] as num).toDouble(),
  daysUntilMaintenance: (json['daysUntilMaintenance'] as num).toInt(),
  recommendedAction: json['recommendedAction'] as String,
);

Map<String, dynamic> _$MaintenancePredictionToJson(
  MaintenancePrediction instance,
) => <String, dynamic>{
  'vehicleId': instance.vehicleId,
  'componentId': instance.componentId,
  'componentName': instance.componentName,
  'predictedFailureDate': instance.predictedFailureDate.toIso8601String(),
  'confidenceScore': instance.confidenceScore,
  'priority': _$MaintenancePriorityEnumMap[instance.priority]!,
  'symptoms': instance.symptoms,
  'estimatedCost': instance.estimatedCost,
  'daysUntilMaintenance': instance.daysUntilMaintenance,
  'recommendedAction': instance.recommendedAction,
};

const _$MaintenancePriorityEnumMap = {
  MaintenancePriority.low: 'low',
  MaintenancePriority.medium: 'medium',
  MaintenancePriority.high: 'high',
  MaintenancePriority.critical: 'critical',
};

PredictionModel _$PredictionModelFromJson(Map<String, dynamic> json) =>
    PredictionModel(
      modelId: json['modelId'] as String,
      modelName: json['modelName'] as String,
      type: $enumDecode(_$ModelTypeEnumMap, json['type']),
      accuracy: (json['accuracy'] as num).toDouble(),
      lastTrained: DateTime.parse(json['lastTrained'] as String),
      features: (json['features'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      featureImportance: (json['featureImportance'] as Map<String, dynamic>)
          .map((k, e) => MapEntry(k, (e as num).toDouble())),
      status: $enumDecode(_$ModelStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$PredictionModelToJson(PredictionModel instance) =>
    <String, dynamic>{
      'modelId': instance.modelId,
      'modelName': instance.modelName,
      'type': _$ModelTypeEnumMap[instance.type]!,
      'accuracy': instance.accuracy,
      'lastTrained': instance.lastTrained.toIso8601String(),
      'features': instance.features,
      'featureImportance': instance.featureImportance,
      'status': _$ModelStatusEnumMap[instance.status]!,
    };

const _$ModelTypeEnumMap = {
  ModelType.regression: 'regression',
  ModelType.classification: 'classification',
  ModelType.timeSeries: 'time_series',
  ModelType.ensemble: 'ensemble',
};

const _$ModelStatusEnumMap = {
  ModelStatus.training: 'training',
  ModelStatus.active: 'active',
  ModelStatus.deprecated: 'deprecated',
  ModelStatus.error: 'error',
};

ConfidenceInterval _$ConfidenceIntervalFromJson(Map<String, dynamic> json) =>
    ConfidenceInterval(
      lowerBound: (json['lowerBound'] as num).toDouble(),
      upperBound: (json['upperBound'] as num).toDouble(),
      meanValue: (json['meanValue'] as num).toDouble(),
      standardDeviation: (json['standardDeviation'] as num).toDouble(),
      confidenceLevel: (json['confidenceLevel'] as num).toDouble(),
    );

Map<String, dynamic> _$ConfidenceIntervalToJson(ConfidenceInterval instance) =>
    <String, dynamic>{
      'lowerBound': instance.lowerBound,
      'upperBound': instance.upperBound,
      'meanValue': instance.meanValue,
      'standardDeviation': instance.standardDeviation,
      'confidenceLevel': instance.confidenceLevel,
    };

PredictionAccuracy _$PredictionAccuracyFromJson(Map<String, dynamic> json) =>
    PredictionAccuracy(
      modelId: json['modelId'] as String,
      overallAccuracy: (json['overallAccuracy'] as num).toDouble(),
      precision: (json['precision'] as num).toDouble(),
      recall: (json['recall'] as num).toDouble(),
      f1Score: (json['f1Score'] as num).toDouble(),
      classAccuracy: (json['classAccuracy'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      evaluationDate: DateTime.parse(json['evaluationDate'] as String),
    );

Map<String, dynamic> _$PredictionAccuracyToJson(PredictionAccuracy instance) =>
    <String, dynamic>{
      'modelId': instance.modelId,
      'overallAccuracy': instance.overallAccuracy,
      'precision': instance.precision,
      'recall': instance.recall,
      'f1Score': instance.f1Score,
      'classAccuracy': instance.classAccuracy,
      'evaluationDate': instance.evaluationDate.toIso8601String(),
    };

MaintenanceSchedule _$MaintenanceScheduleFromJson(Map<String, dynamic> json) =>
    MaintenanceSchedule(
      vehicleId: json['vehicleId'] as String,
      scheduledItems: (json['scheduledItems'] as List<dynamic>)
          .map((e) => ScheduledMaintenance.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedDate: DateTime.parse(json['generatedDate'] as String),
      period: $enumDecode(_$TimePeriodEnumMap, json['period']),
      totalEstimatedCost: (json['totalEstimatedCost'] as num).toDouble(),
    );

Map<String, dynamic> _$MaintenanceScheduleToJson(
  MaintenanceSchedule instance,
) => <String, dynamic>{
  'vehicleId': instance.vehicleId,
  'scheduledItems': instance.scheduledItems,
  'generatedDate': instance.generatedDate.toIso8601String(),
  'period': _$TimePeriodEnumMap[instance.period]!,
  'totalEstimatedCost': instance.totalEstimatedCost,
};

const _$TimePeriodEnumMap = {
  TimePeriod.day: 'day',
  TimePeriod.week: 'week',
  TimePeriod.month: 'month',
  TimePeriod.quarter: 'quarter',
  TimePeriod.year: 'year',
};

ScheduledMaintenance _$ScheduledMaintenanceFromJson(
  Map<String, dynamic> json,
) => ScheduledMaintenance(
  id: json['id'] as String,
  componentName: json['componentName'] as String,
  scheduledDate: DateTime.parse(json['scheduledDate'] as String),
  priority: $enumDecode(_$MaintenancePriorityEnumMap, json['priority']),
  estimatedCost: (json['estimatedCost'] as num).toDouble(),
  estimatedDuration: (json['estimatedDuration'] as num).toInt(),
  description: json['description'] as String,
  requiredParts: (json['requiredParts'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  isPreventive: json['isPreventive'] as bool,
);

Map<String, dynamic> _$ScheduledMaintenanceToJson(
  ScheduledMaintenance instance,
) => <String, dynamic>{
  'id': instance.id,
  'componentName': instance.componentName,
  'scheduledDate': instance.scheduledDate.toIso8601String(),
  'priority': _$MaintenancePriorityEnumMap[instance.priority]!,
  'estimatedCost': instance.estimatedCost,
  'estimatedDuration': instance.estimatedDuration,
  'description': instance.description,
  'requiredParts': instance.requiredParts,
  'isPreventive': instance.isPreventive,
};

PredictiveInsight _$PredictiveInsightFromJson(Map<String, dynamic> json) =>
    PredictiveInsight(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$InsightTypeEnumMap, json['type']),
      impact: (json['impact'] as num).toDouble(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdDate: DateTime.parse(json['createdDate'] as String),
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$PredictiveInsightToJson(PredictiveInsight instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$InsightTypeEnumMap[instance.type]!,
      'impact': instance.impact,
      'recommendations': instance.recommendations,
      'createdDate': instance.createdDate.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$InsightTypeEnumMap = {
  InsightType.costOptimization: 'cost_optimization',
  InsightType.performanceImprovement: 'performance_improvement',
  InsightType.riskMitigation: 'risk_mitigation',
  InsightType.efficiencyEnhancement: 'efficiency_enhancement',
};

