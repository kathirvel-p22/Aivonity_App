// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PerformanceMetrics _$PerformanceMetricsFromJson(Map<String, dynamic> json) =>
    PerformanceMetrics(
      vehicleId: json['vehicleId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fuelEfficiency: (json['fuelEfficiency'] as num).toDouble(),
      averageSpeed: (json['averageSpeed'] as num).toDouble(),
      totalDistance: (json['totalDistance'] as num).toInt(),
      engineHealth: (json['engineHealth'] as num).toDouble(),
      batteryHealth: (json['batteryHealth'] as num).toDouble(),
      alertCount: (json['alertCount'] as num).toInt(),
      maintenanceScore: (json['maintenanceScore'] as num).toDouble(),
    );

Map<String, dynamic> _$PerformanceMetricsToJson(PerformanceMetrics instance) =>
    <String, dynamic>{
      'vehicleId': instance.vehicleId,
      'timestamp': instance.timestamp.toIso8601String(),
      'fuelEfficiency': instance.fuelEfficiency,
      'averageSpeed': instance.averageSpeed,
      'totalDistance': instance.totalDistance,
      'engineHealth': instance.engineHealth,
      'batteryHealth': instance.batteryHealth,
      'alertCount': instance.alertCount,
      'maintenanceScore': instance.maintenanceScore,
    };

TrendAnalysis _$TrendAnalysisFromJson(Map<String, dynamic> json) =>
    TrendAnalysis(
      vehicleId: json['vehicleId'] as String,
      period: $enumDecode(_$TimePeriodEnumMap, json['period']),
      fuelEfficiencyTrend: (json['fuelEfficiencyTrend'] as List<dynamic>)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      maintenanceCostTrend: (json['maintenanceCostTrend'] as List<dynamic>)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      performanceTrend: (json['performanceTrend'] as List<dynamic>)
          .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      overallTrend: $enumDecode(_$TrendDirectionEnumMap, json['overallTrend']),
      trendConfidence: (json['trendConfidence'] as num).toDouble(),
    );

Map<String, dynamic> _$TrendAnalysisToJson(TrendAnalysis instance) =>
    <String, dynamic>{
      'vehicleId': instance.vehicleId,
      'period': _$TimePeriodEnumMap[instance.period]!,
      'fuelEfficiencyTrend': instance.fuelEfficiencyTrend,
      'maintenanceCostTrend': instance.maintenanceCostTrend,
      'performanceTrend': instance.performanceTrend,
      'overallTrend': _$TrendDirectionEnumMap[instance.overallTrend]!,
      'trendConfidence': instance.trendConfidence,
    };

const _$TimePeriodEnumMap = {
  TimePeriod.day: 'day',
  TimePeriod.week: 'week',
  TimePeriod.month: 'month',
  TimePeriod.quarter: 'quarter',
  TimePeriod.year: 'year',
};

const _$TrendDirectionEnumMap = {
  TrendDirection.up: 'up',
  TrendDirection.down: 'down',
  TrendDirection.stable: 'stable',
};

DataPoint _$DataPointFromJson(Map<String, dynamic> json) => DataPoint(
  timestamp: DateTime.parse(json['timestamp'] as String),
  value: (json['value'] as num).toDouble(),
  label: json['label'] as String?,
);

Map<String, dynamic> _$DataPointToJson(DataPoint instance) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
  'value': instance.value,
  'label': instance.label,
};

KPIMetric _$KPIMetricFromJson(Map<String, dynamic> json) => KPIMetric(
  id: json['id'] as String,
  name: json['name'] as String,
  currentValue: (json['currentValue'] as num).toDouble(),
  previousValue: (json['previousValue'] as num).toDouble(),
  unit: json['unit'] as String,
  trend: $enumDecode(_$KPITrendEnumMap, json['trend']),
  changePercentage: (json['changePercentage'] as num).toDouble(),
  description: json['description'] as String,
  type: $enumDecode(_$MetricTypeEnumMap, json['type']),
);

Map<String, dynamic> _$KPIMetricToJson(KPIMetric instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'currentValue': instance.currentValue,
  'previousValue': instance.previousValue,
  'unit': instance.unit,
  'trend': _$KPITrendEnumMap[instance.trend]!,
  'changePercentage': instance.changePercentage,
  'description': instance.description,
  'type': _$MetricTypeEnumMap[instance.type]!,
};

const _$KPITrendEnumMap = {
  KPITrend.improving: 'improving',
  KPITrend.declining: 'declining',
  KPITrend.stable: 'stable',
};

const _$MetricTypeEnumMap = {
  MetricType.performance: 'performance',
  MetricType.efficiency: 'efficiency',
  MetricType.maintenance: 'maintenance',
  MetricType.cost: 'cost',
};

ChartData _$ChartDataFromJson(Map<String, dynamic> json) => ChartData(
  title: json['title'] as String,
  type: $enumDecode(_$ChartTypeEnumMap, json['type']),
  series: (json['series'] as List<dynamic>)
      .map((e) => DataSeries.fromJson(e as Map<String, dynamic>))
      .toList(),
  configuration: ChartConfiguration.fromJson(
    json['configuration'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ChartDataToJson(ChartData instance) => <String, dynamic>{
  'title': instance.title,
  'type': _$ChartTypeEnumMap[instance.type]!,
  'series': instance.series,
  'configuration': instance.configuration,
};

const _$ChartTypeEnumMap = {
  ChartType.line: 'line',
  ChartType.bar: 'bar',
  ChartType.pie: 'pie',
  ChartType.area: 'area',
  ChartType.scatter: 'scatter',
};

DataSeries _$DataSeriesFromJson(Map<String, dynamic> json) => DataSeries(
  name: json['name'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  color: json['color'] as String,
  type: $enumDecode(_$SeriesTypeEnumMap, json['type']),
);

Map<String, dynamic> _$DataSeriesToJson(DataSeries instance) =>
    <String, dynamic>{
      'name': instance.name,
      'data': instance.data,
      'color': instance.color,
      'type': _$SeriesTypeEnumMap[instance.type]!,
    };

const _$SeriesTypeEnumMap = {
  SeriesType.line: 'line',
  SeriesType.bar: 'bar',
  SeriesType.area: 'area',
};

ChartConfiguration _$ChartConfigurationFromJson(Map<String, dynamic> json) =>
    ChartConfiguration(
      showGrid: json['showGrid'] as bool,
      showLegend: json['showLegend'] as bool,
      enableInteraction: json['enableInteraction'] as bool,
      xAxisLabel: json['xAxisLabel'] as String,
      yAxisLabel: json['yAxisLabel'] as String,
      minY: (json['minY'] as num?)?.toDouble(),
      maxY: (json['maxY'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ChartConfigurationToJson(ChartConfiguration instance) =>
    <String, dynamic>{
      'showGrid': instance.showGrid,
      'showLegend': instance.showLegend,
      'enableInteraction': instance.enableInteraction,
      'xAxisLabel': instance.xAxisLabel,
      'yAxisLabel': instance.yAxisLabel,
      'minY': instance.minY,
      'maxY': instance.maxY,
    };

