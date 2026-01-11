import 'package:json_annotation/json_annotation.dart';
import 'analytics.dart';
import 'predictive_analytics.dart';

part 'reporting.g.dart';

@JsonSerializable()
class Report {
  final String id;
  final String title;
  final String description;
  final ReportType type;
  final DateTime generatedDate;
  final String vehicleId;
  final ReportData data;
  final ReportConfiguration configuration;
  final ReportStatus status;

  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.generatedDate,
    required this.vehicleId,
    required this.data,
    required this.configuration,
    required this.status,
  });

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);
  Map<String, dynamic> toJson() => _$ReportToJson(this);
}

@JsonSerializable()
class ReportData {
  final List<PerformanceMetrics>? performanceMetrics;
  final List<KPIMetric>? kpiMetrics;
  final List<MaintenancePrediction>? predictions;
  final List<ChartData>? charts;
  final Map<String, dynamic>? customData;

  const ReportData({
    this.performanceMetrics,
    this.kpiMetrics,
    this.predictions,
    this.charts,
    this.customData,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) =>
      _$ReportDataFromJson(json);
  Map<String, dynamic> toJson() => _$ReportDataToJson(this);
}

@JsonSerializable()
class ReportConfiguration {
  final bool includeCharts;
  final bool includeMetrics;
  final bool includePredictions;
  final TimePeriod period;
  final List<String> sections;
  final ReportFormat format;
  final Map<String, dynamic> customSettings;

  const ReportConfiguration({
    required this.includeCharts,
    required this.includeMetrics,
    required this.includePredictions,
    required this.period,
    required this.sections,
    required this.format,
    required this.customSettings,
  });

  factory ReportConfiguration.fromJson(Map<String, dynamic> json) =>
      _$ReportConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$ReportConfigurationToJson(this);
}

@JsonSerializable()
class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final ReportType type;
  final List<ReportSection> sections;
  final Map<String, dynamic> defaultConfiguration;

  const ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.sections,
    required this.defaultConfiguration,
  });

  factory ReportTemplate.fromJson(Map<String, dynamic> json) =>
      _$ReportTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$ReportTemplateToJson(this);
}

@JsonSerializable()
class ReportSection {
  final String id;
  final String title;
  final SectionType type;
  final Map<String, dynamic> configuration;
  final int order;

  const ReportSection({
    required this.id,
    required this.title,
    required this.type,
    required this.configuration,
    required this.order,
  });

  factory ReportSection.fromJson(Map<String, dynamic> json) =>
      _$ReportSectionFromJson(json);
  Map<String, dynamic> toJson() => _$ReportSectionToJson(this);
}

@JsonSerializable()
class ReportSchedule {
  final String id;
  final String reportTemplateId;
  final String vehicleId;
  final ScheduleFrequency frequency;
  final DateTime nextRun;
  final List<String> recipients;
  final bool isActive;
  final Map<String, dynamic> configuration;

  const ReportSchedule({
    required this.id,
    required this.reportTemplateId,
    required this.vehicleId,
    required this.frequency,
    required this.nextRun,
    required this.recipients,
    required this.isActive,
    required this.configuration,
  });

  factory ReportSchedule.fromJson(Map<String, dynamic> json) =>
      _$ReportScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$ReportScheduleToJson(this);
}

@JsonSerializable()
class SharedReport {
  final String id;
  final String reportId;
  final String shareUrl;
  final DateTime expirationDate;
  final List<String> permissions;
  final bool requiresPassword;
  final int accessCount;
  final DateTime createdDate;

  const SharedReport({
    required this.id,
    required this.reportId,
    required this.shareUrl,
    required this.expirationDate,
    required this.permissions,
    required this.requiresPassword,
    required this.accessCount,
    required this.createdDate,
  });

  factory SharedReport.fromJson(Map<String, dynamic> json) =>
      _$SharedReportFromJson(json);
  Map<String, dynamic> toJson() => _$SharedReportToJson(this);
}

enum ReportType {
  @JsonValue('performance')
  performance,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('analytics')
  analytics,
  @JsonValue('comprehensive')
  comprehensive,
  @JsonValue('custom')
  custom,
}

enum ReportFormat {
  @JsonValue('pdf')
  pdf,
  @JsonValue('excel')
  excel,
  @JsonValue('csv')
  csv,
  @JsonValue('json')
  json,
}

enum ReportStatus {
  @JsonValue('generating')
  generating,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('scheduled')
  scheduled,
}

enum SectionType {
  @JsonValue('summary')
  summary,
  @JsonValue('chart')
  chart,
  @JsonValue('table')
  table,
  @JsonValue('metrics')
  metrics,
  @JsonValue('predictions')
  predictions,
  @JsonValue('text')
  text,
}

enum ScheduleFrequency {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('monthly')
  monthly,
  @JsonValue('quarterly')
  quarterly,
}

