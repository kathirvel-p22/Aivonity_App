import 'package:json_annotation/json_annotation.dart';

part 'analytics.g.dart';

@JsonSerializable()
class PerformanceMetrics {
  final String vehicleId;
  final DateTime timestamp;
  final double fuelEfficiency;
  final double averageSpeed;
  final int totalDistance;
  final double engineHealth;
  final double batteryHealth;
  final int alertCount;
  final double maintenanceScore;

  const PerformanceMetrics({
    required this.vehicleId,
    required this.timestamp,
    required this.fuelEfficiency,
    required this.averageSpeed,
    required this.totalDistance,
    required this.engineHealth,
    required this.batteryHealth,
    required this.alertCount,
    required this.maintenanceScore,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$PerformanceMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceMetricsToJson(this);
}

@JsonSerializable()
class TrendAnalysis {
  final String vehicleId;
  final TimePeriod period;
  final List<DataPoint> fuelEfficiencyTrend;
  final List<DataPoint> maintenanceCostTrend;
  final List<DataPoint> performanceTrend;
  final TrendDirection overallTrend;
  final double trendConfidence;

  const TrendAnalysis({
    required this.vehicleId,
    required this.period,
    required this.fuelEfficiencyTrend,
    required this.maintenanceCostTrend,
    required this.performanceTrend,
    required this.overallTrend,
    required this.trendConfidence,
  });

  factory TrendAnalysis.fromJson(Map<String, dynamic> json) =>
      _$TrendAnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$TrendAnalysisToJson(this);
}

@JsonSerializable()
class DataPoint {
  final DateTime timestamp;
  final double value;
  final String? label;

  const DataPoint({required this.timestamp, required this.value, this.label});

  factory DataPoint.fromJson(Map<String, dynamic> json) =>
      _$DataPointFromJson(json);

  Map<String, dynamic> toJson() => _$DataPointToJson(this);
}

@JsonSerializable()
class KPIMetric {
  final String id;
  final String name;
  final double currentValue;
  final double previousValue;
  final String unit;
  final KPITrend trend;
  final double changePercentage;
  final String description;
  final MetricType type;

  const KPIMetric({
    required this.id,
    required this.name,
    required this.currentValue,
    required this.previousValue,
    required this.unit,
    required this.trend,
    required this.changePercentage,
    required this.description,
    required this.type,
  });

  factory KPIMetric.fromJson(Map<String, dynamic> json) =>
      _$KPIMetricFromJson(json);

  Map<String, dynamic> toJson() => _$KPIMetricToJson(this);
}

@JsonSerializable()
class ChartData {
  final String title;
  final ChartType type;
  final List<DataSeries> series;
  final ChartConfiguration configuration;

  const ChartData({
    required this.title,
    required this.type,
    required this.series,
    required this.configuration,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) =>
      _$ChartDataFromJson(json);

  Map<String, dynamic> toJson() => _$ChartDataToJson(this);
}

@JsonSerializable()
class DataSeries {
  final String name;
  final List<DataPoint> data;
  final String color;
  final SeriesType type;

  const DataSeries({
    required this.name,
    required this.data,
    required this.color,
    required this.type,
  });

  factory DataSeries.fromJson(Map<String, dynamic> json) =>
      _$DataSeriesFromJson(json);

  Map<String, dynamic> toJson() => _$DataSeriesToJson(this);
}

@JsonSerializable()
class ChartConfiguration {
  final bool showGrid;
  final bool showLegend;
  final bool enableInteraction;
  final String xAxisLabel;
  final String yAxisLabel;
  final double? minY;
  final double? maxY;

  const ChartConfiguration({
    required this.showGrid,
    required this.showLegend,
    required this.enableInteraction,
    required this.xAxisLabel,
    required this.yAxisLabel,
    this.minY,
    this.maxY,
  });

  factory ChartConfiguration.fromJson(Map<String, dynamic> json) =>
      _$ChartConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$ChartConfigurationToJson(this);
}

enum TimePeriod {
  @JsonValue('day')
  day,
  @JsonValue('week')
  week,
  @JsonValue('month')
  month,
  @JsonValue('quarter')
  quarter,
  @JsonValue('year')
  year,
}

enum TrendDirection {
  @JsonValue('up')
  up,
  @JsonValue('down')
  down,
  @JsonValue('stable')
  stable,
}

enum KPITrend {
  @JsonValue('improving')
  improving,
  @JsonValue('declining')
  declining,
  @JsonValue('stable')
  stable,
}

enum MetricType {
  @JsonValue('performance')
  performance,
  @JsonValue('efficiency')
  efficiency,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('cost')
  cost,
}

enum ChartType {
  @JsonValue('line')
  line,
  @JsonValue('bar')
  bar,
  @JsonValue('pie')
  pie,
  @JsonValue('area')
  area,
  @JsonValue('scatter')
  scatter,
}

enum SeriesType {
  @JsonValue('line')
  line,
  @JsonValue('bar')
  bar,
  @JsonValue('area')
  area,
}

