import 'package:json_annotation/json_annotation.dart';
import 'analytics.dart' show TimePeriod;

part 'predictive_analytics.g.dart';

@JsonSerializable()
class MaintenancePrediction {
  final String vehicleId;
  final String componentId;
  final String componentName;
  final DateTime predictedFailureDate;
  final double confidenceScore;
  final MaintenancePriority priority;
  final List<String> symptoms;
  final double estimatedCost;
  final int daysUntilMaintenance;
  final String recommendedAction;

  const MaintenancePrediction({
    required this.vehicleId,
    required this.componentId,
    required this.componentName,
    required this.predictedFailureDate,
    required this.confidenceScore,
    required this.priority,
    required this.symptoms,
    required this.estimatedCost,
    required this.daysUntilMaintenance,
    required this.recommendedAction,
  });

  factory MaintenancePrediction.fromJson(Map<String, dynamic> json) =>
      _$MaintenancePredictionFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenancePredictionToJson(this);
}

@JsonSerializable()
class PredictionModel {
  final String modelId;
  final String modelName;
  final ModelType type;
  final double accuracy;
  final DateTime lastTrained;
  final List<String> features;
  final Map<String, double> featureImportance;
  final ModelStatus status;

  const PredictionModel({
    required this.modelId,
    required this.modelName,
    required this.type,
    required this.accuracy,
    required this.lastTrained,
    required this.features,
    required this.featureImportance,
    required this.status,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) =>
      _$PredictionModelFromJson(json);

  Map<String, dynamic> toJson() => _$PredictionModelToJson(this);
}

@JsonSerializable()
class ConfidenceInterval {
  final double lowerBound;
  final double upperBound;
  final double meanValue;
  final double standardDeviation;
  final double confidenceLevel;

  const ConfidenceInterval({
    required this.lowerBound,
    required this.upperBound,
    required this.meanValue,
    required this.standardDeviation,
    required this.confidenceLevel,
  });

  factory ConfidenceInterval.fromJson(Map<String, dynamic> json) =>
      _$ConfidenceIntervalFromJson(json);

  Map<String, dynamic> toJson() => _$ConfidenceIntervalToJson(this);
}

@JsonSerializable()
class PredictionAccuracy {
  final String modelId;
  final double overallAccuracy;
  final double precision;
  final double recall;
  final double f1Score;
  final Map<String, double> classAccuracy;
  final DateTime evaluationDate;

  const PredictionAccuracy({
    required this.modelId,
    required this.overallAccuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.classAccuracy,
    required this.evaluationDate,
  });

  factory PredictionAccuracy.fromJson(Map<String, dynamic> json) =>
      _$PredictionAccuracyFromJson(json);

  Map<String, dynamic> toJson() => _$PredictionAccuracyToJson(this);
}

@JsonSerializable()
class MaintenanceSchedule {
  final String vehicleId;
  final List<ScheduledMaintenance> scheduledItems;
  final DateTime generatedDate;
  final TimePeriod period;
  final double totalEstimatedCost;

  const MaintenanceSchedule({
    required this.vehicleId,
    required this.scheduledItems,
    required this.generatedDate,
    required this.period,
    required this.totalEstimatedCost,
  });

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceScheduleToJson(this);
}

@JsonSerializable()
class ScheduledMaintenance {
  final String id;
  final String componentName;
  final DateTime scheduledDate;
  final MaintenancePriority priority;
  final double estimatedCost;
  final int estimatedDuration; // in minutes
  final String description;
  final List<String> requiredParts;
  final bool isPreventive;

  const ScheduledMaintenance({
    required this.id,
    required this.componentName,
    required this.scheduledDate,
    required this.priority,
    required this.estimatedCost,
    required this.estimatedDuration,
    required this.description,
    required this.requiredParts,
    required this.isPreventive,
  });

  factory ScheduledMaintenance.fromJson(Map<String, dynamic> json) =>
      _$ScheduledMaintenanceFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduledMaintenanceToJson(this);
}

@JsonSerializable()
class PredictiveInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final double impact;
  final List<String> recommendations;
  final DateTime createdDate;
  final Map<String, dynamic> metadata;

  const PredictiveInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.impact,
    required this.recommendations,
    required this.createdDate,
    required this.metadata,
  });

  factory PredictiveInsight.fromJson(Map<String, dynamic> json) =>
      _$PredictiveInsightFromJson(json);

  Map<String, dynamic> toJson() => _$PredictiveInsightToJson(this);
}

enum MaintenancePriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

enum ModelType {
  @JsonValue('regression')
  regression,
  @JsonValue('classification')
  classification,
  @JsonValue('time_series')
  timeSeries,
  @JsonValue('ensemble')
  ensemble,
}

enum ModelStatus {
  @JsonValue('training')
  training,
  @JsonValue('active')
  active,
  @JsonValue('deprecated')
  deprecated,
  @JsonValue('error')
  error,
}

enum InsightType {
  @JsonValue('cost_optimization')
  costOptimization,
  @JsonValue('performance_improvement')
  performanceImprovement,
  @JsonValue('risk_mitigation')
  riskMitigation,
  @JsonValue('efficiency_enhancement')
  efficiencyEnhancement,
}

// TimePeriod is already defined in analytics.dart, so we'll import it from there

