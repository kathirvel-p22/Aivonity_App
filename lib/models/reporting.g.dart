// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reporting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$ReportTypeEnumMap, json['type']),
  generatedDate: DateTime.parse(json['generatedDate'] as String),
  vehicleId: json['vehicleId'] as String,
  data: ReportData.fromJson(json['data'] as Map<String, dynamic>),
  configuration: ReportConfiguration.fromJson(
    json['configuration'] as Map<String, dynamic>,
  ),
  status: $enumDecode(_$ReportStatusEnumMap, json['status']),
);

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'type': _$ReportTypeEnumMap[instance.type]!,
  'generatedDate': instance.generatedDate.toIso8601String(),
  'vehicleId': instance.vehicleId,
  'data': instance.data,
  'configuration': instance.configuration,
  'status': _$ReportStatusEnumMap[instance.status]!,
};

const _$ReportTypeEnumMap = {
  ReportType.performance: 'performance',
  ReportType.maintenance: 'maintenance',
  ReportType.analytics: 'analytics',
  ReportType.comprehensive: 'comprehensive',
  ReportType.custom: 'custom',
};

const _$ReportStatusEnumMap = {
  ReportStatus.generating: 'generating',
  ReportStatus.completed: 'completed',
  ReportStatus.failed: 'failed',
  ReportStatus.scheduled: 'scheduled',
};

ReportData _$ReportDataFromJson(Map<String, dynamic> json) => ReportData(
  performanceMetrics: (json['performanceMetrics'] as List<dynamic>?)
      ?.map((e) => PerformanceMetrics.fromJson(e as Map<String, dynamic>))
      .toList(),
  kpiMetrics: (json['kpiMetrics'] as List<dynamic>?)
      ?.map((e) => KPIMetric.fromJson(e as Map<String, dynamic>))
      .toList(),
  predictions: (json['predictions'] as List<dynamic>?)
      ?.map((e) => MaintenancePrediction.fromJson(e as Map<String, dynamic>))
      .toList(),
  charts: (json['charts'] as List<dynamic>?)
      ?.map((e) => ChartData.fromJson(e as Map<String, dynamic>))
      .toList(),
  customData: json['customData'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ReportDataToJson(ReportData instance) =>
    <String, dynamic>{
      'performanceMetrics': instance.performanceMetrics,
      'kpiMetrics': instance.kpiMetrics,
      'predictions': instance.predictions,
      'charts': instance.charts,
      'customData': instance.customData,
    };

ReportConfiguration _$ReportConfigurationFromJson(Map<String, dynamic> json) =>
    ReportConfiguration(
      includeCharts: json['includeCharts'] as bool,
      includeMetrics: json['includeMetrics'] as bool,
      includePredictions: json['includePredictions'] as bool,
      period: $enumDecode(_$TimePeriodEnumMap, json['period']),
      sections: (json['sections'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      format: $enumDecode(_$ReportFormatEnumMap, json['format']),
      customSettings: json['customSettings'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ReportConfigurationToJson(
  ReportConfiguration instance,
) => <String, dynamic>{
  'includeCharts': instance.includeCharts,
  'includeMetrics': instance.includeMetrics,
  'includePredictions': instance.includePredictions,
  'period': _$TimePeriodEnumMap[instance.period]!,
  'sections': instance.sections,
  'format': _$ReportFormatEnumMap[instance.format]!,
  'customSettings': instance.customSettings,
};

const _$TimePeriodEnumMap = {
  TimePeriod.day: 'day',
  TimePeriod.week: 'week',
  TimePeriod.month: 'month',
  TimePeriod.quarter: 'quarter',
  TimePeriod.year: 'year',
};

const _$ReportFormatEnumMap = {
  ReportFormat.pdf: 'pdf',
  ReportFormat.excel: 'excel',
  ReportFormat.csv: 'csv',
  ReportFormat.json: 'json',
};

ReportTemplate _$ReportTemplateFromJson(Map<String, dynamic> json) =>
    ReportTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$ReportTypeEnumMap, json['type']),
      sections: (json['sections'] as List<dynamic>)
          .map((e) => ReportSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultConfiguration:
          json['defaultConfiguration'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ReportTemplateToJson(ReportTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$ReportTypeEnumMap[instance.type]!,
      'sections': instance.sections,
      'defaultConfiguration': instance.defaultConfiguration,
    };

ReportSection _$ReportSectionFromJson(Map<String, dynamic> json) =>
    ReportSection(
      id: json['id'] as String,
      title: json['title'] as String,
      type: $enumDecode(_$SectionTypeEnumMap, json['type']),
      configuration: json['configuration'] as Map<String, dynamic>,
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$ReportSectionToJson(ReportSection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': _$SectionTypeEnumMap[instance.type]!,
      'configuration': instance.configuration,
      'order': instance.order,
    };

const _$SectionTypeEnumMap = {
  SectionType.summary: 'summary',
  SectionType.chart: 'chart',
  SectionType.table: 'table',
  SectionType.metrics: 'metrics',
  SectionType.predictions: 'predictions',
  SectionType.text: 'text',
};

ReportSchedule _$ReportScheduleFromJson(Map<String, dynamic> json) =>
    ReportSchedule(
      id: json['id'] as String,
      reportTemplateId: json['reportTemplateId'] as String,
      vehicleId: json['vehicleId'] as String,
      frequency: $enumDecode(_$ScheduleFrequencyEnumMap, json['frequency']),
      nextRun: DateTime.parse(json['nextRun'] as String),
      recipients: (json['recipients'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isActive: json['isActive'] as bool,
      configuration: json['configuration'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ReportScheduleToJson(ReportSchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportTemplateId': instance.reportTemplateId,
      'vehicleId': instance.vehicleId,
      'frequency': _$ScheduleFrequencyEnumMap[instance.frequency]!,
      'nextRun': instance.nextRun.toIso8601String(),
      'recipients': instance.recipients,
      'isActive': instance.isActive,
      'configuration': instance.configuration,
    };

const _$ScheduleFrequencyEnumMap = {
  ScheduleFrequency.daily: 'daily',
  ScheduleFrequency.weekly: 'weekly',
  ScheduleFrequency.monthly: 'monthly',
  ScheduleFrequency.quarterly: 'quarterly',
};

SharedReport _$SharedReportFromJson(Map<String, dynamic> json) => SharedReport(
  id: json['id'] as String,
  reportId: json['reportId'] as String,
  shareUrl: json['shareUrl'] as String,
  expirationDate: DateTime.parse(json['expirationDate'] as String),
  permissions: (json['permissions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  requiresPassword: json['requiresPassword'] as bool,
  accessCount: (json['accessCount'] as num).toInt(),
  createdDate: DateTime.parse(json['createdDate'] as String),
);

Map<String, dynamic> _$SharedReportToJson(SharedReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportId': instance.reportId,
      'shareUrl': instance.shareUrl,
      'expirationDate': instance.expirationDate.toIso8601String(),
      'permissions': instance.permissions,
      'requiresPassword': instance.requiresPassword,
      'accessCount': instance.accessCount,
      'createdDate': instance.createdDate.toIso8601String(),
    };

