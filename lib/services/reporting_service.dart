import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rxdart/rxdart.dart';
import '../models/reporting.dart';
import '../models/analytics.dart';
import '../models/predictive_analytics.dart';
import '../config/api_config.dart';

class ReportingService {
  final Dio _dio;
  final BehaviorSubject<List<Report>> _reportsController =
      BehaviorSubject<List<Report>>();
  final BehaviorSubject<List<ReportSchedule>> _schedulesController =
      BehaviorSubject<List<ReportSchedule>>();

  ReportingService(this._dio);

  Stream<List<Report>> get reportsStream => _reportsController.stream;
  Stream<List<ReportSchedule>> get schedulesStream =>
      _schedulesController.stream;

  Future<Report> generateReport(
    String vehicleId,
    ReportType type,
    ReportConfiguration configuration,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/reports/generate',
        data: {
          'vehicle_id': vehicleId,
          'type': type.name,
          'configuration': configuration.toJson(),
        },
      );

      return Report.fromJson(response.data);
    } catch (e) {
      // Generate mock report for development
      return _generateMockReport(vehicleId, type, configuration);
    }
  }

  Future<Uint8List> generatePDFReport(
    String vehicleId,
    ReportData data,
    ReportConfiguration configuration,
  ) async {
    final pdf = pw.Document();

    // Add title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Vehicle Analytics Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Vehicle ID: $vehicleId'),
              pw.Text('Generated: ${DateTime.now().toString().split(' ')[0]}'),
              pw.Text('Period: ${configuration.period.name}'),
              pw.SizedBox(height: 40),
              if (configuration.includeMetrics &&
                  data.performanceMetrics != null)
                _buildPerformanceSection(data.performanceMetrics!),
              if (configuration.includePredictions && data.predictions != null)
                _buildPredictionsSection(data.predictions!),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateExcelReport(
    String vehicleId,
    ReportData data,
    ReportConfiguration configuration,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Report'];

    // Add headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      'Vehicle Analytics Report',
    );
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      'Vehicle ID: $vehicleId',
    );
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
      'Generated: ${DateTime.now().toString().split(' ')[0]}',
    );

    int currentRow = 5;

    // Add performance metrics
    if (configuration.includeMetrics && data.performanceMetrics != null) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Performance Metrics',
      );
      currentRow += 2;

      // Headers
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Date',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Fuel Efficiency',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Engine Health',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Battery Health',
      );
      currentRow++;

      // Data
      for (final metric in data.performanceMetrics!) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
            )
            .value = TextCellValue(
          metric.timestamp.toString().split(' ')[0],
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
            )
            .value = DoubleCellValue(
          metric.fuelEfficiency,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
            )
            .value = DoubleCellValue(
          metric.engineHealth,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
            )
            .value = DoubleCellValue(
          metric.batteryHealth,
        );
        currentRow++;
      }
    }

    // Add predictions
    if (configuration.includePredictions && data.predictions != null) {
      currentRow += 2;
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Maintenance Predictions',
      );
      currentRow += 2;

      // Headers
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Component',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Predicted Date',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Confidence',
      );
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
          )
          .value = TextCellValue(
        'Cost',
      );
      currentRow++;

      // Data
      for (final prediction in data.predictions!) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
            )
            .value = TextCellValue(
          prediction.componentName,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
            )
            .value = TextCellValue(
          prediction.predictedFailureDate.toString().split(' ')[0],
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
            )
            .value = DoubleCellValue(
          prediction.confidenceScore,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
            )
            .value = DoubleCellValue(
          prediction.estimatedCost,
        );
        currentRow++;
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  Future<File> saveReportToFile(Uint8List data, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(data);
    return file;
  }

  Future<void> shareReport(File file, String title) async {
    await Share.shareXFiles([XFile(file.path)], text: title);
  }

  Future<List<ReportTemplate>> getReportTemplates() async {
    try {
      final response = await _dio.get('${ApiConfig.baseUrl}/reports/templates');
      return (response.data as List)
          .map((json) => ReportTemplate.fromJson(json))
          .toList();
    } catch (e) {
      return _generateMockTemplates();
    }
  }

  Future<ReportSchedule> scheduleReport(
    String vehicleId,
    String templateId,
    ScheduleFrequency frequency,
    List<String> recipients,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/reports/schedule',
        data: {
          'vehicle_id': vehicleId,
          'template_id': templateId,
          'frequency': frequency.name,
          'recipients': recipients,
        },
      );

      return ReportSchedule.fromJson(response.data);
    } catch (e) {
      return _generateMockSchedule(
        vehicleId,
        templateId,
        frequency,
        recipients,
      );
    }
  }

  Future<SharedReport> shareReportSecurely(
    String reportId,
    Duration expirationDuration,
    List<String> permissions,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/reports/share',
        data: {
          'report_id': reportId,
          'expiration_hours': expirationDuration.inHours,
          'permissions': permissions,
        },
      );

      return SharedReport.fromJson(response.data);
    } catch (e) {
      return _generateMockSharedReport(
        reportId,
        expirationDuration,
        permissions,
      );
    }
  }

  Future<List<Report>> getReports(String vehicleId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/reports/$vehicleId',
      );
      final reports = (response.data as List)
          .map((json) => Report.fromJson(json))
          .toList();

      _reportsController.add(reports);
      return reports;
    } catch (e) {
      final mockReports = _generateMockReports(vehicleId);
      _reportsController.add(mockReports);
      return mockReports;
    }
  }

  // Mock data generation methods
  Report _generateMockReport(
    String vehicleId,
    ReportType type,
    ReportConfiguration configuration,
  ) {
    return Report(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      title: '${type.name.toUpperCase()} Report',
      description: 'Generated ${type.name} report for vehicle $vehicleId',
      type: type,
      generatedDate: DateTime.now(),
      vehicleId: vehicleId,
      data: ReportData(
        performanceMetrics: configuration.includeMetrics ? [] : null,
        kpiMetrics: configuration.includeMetrics ? [] : null,
        predictions: configuration.includePredictions ? [] : null,
        charts: configuration.includeCharts ? [] : null,
      ),
      configuration: configuration,
      status: ReportStatus.completed,
    );
  }

  List<ReportTemplate> _generateMockTemplates() {
    return [
      ReportTemplate(
        id: 'template_performance',
        name: 'Performance Report',
        description: 'Comprehensive vehicle performance analysis',
        type: ReportType.performance,
        sections: [
          ReportSection(
            id: 'summary',
            title: 'Executive Summary',
            type: SectionType.summary,
            configuration: {},
            order: 1,
          ),
          ReportSection(
            id: 'metrics',
            title: 'Performance Metrics',
            type: SectionType.metrics,
            configuration: {},
            order: 2,
          ),
        ],
        defaultConfiguration: {
          'include_charts': true,
          'include_metrics': true,
          'period': 'month',
        },
      ),
      ReportTemplate(
        id: 'template_maintenance',
        name: 'Maintenance Report',
        description: 'Predictive maintenance analysis and recommendations',
        type: ReportType.maintenance,
        sections: [
          ReportSection(
            id: 'predictions',
            title: 'Maintenance Predictions',
            type: SectionType.predictions,
            configuration: {},
            order: 1,
          ),
        ],
        defaultConfiguration: {
          'include_predictions': true,
          'period': 'quarter',
        },
      ),
    ];
  }

  ReportSchedule _generateMockSchedule(
    String vehicleId,
    String templateId,
    ScheduleFrequency frequency,
    List<String> recipients,
  ) {
    return ReportSchedule(
      id: 'schedule_${DateTime.now().millisecondsSinceEpoch}',
      reportTemplateId: templateId,
      vehicleId: vehicleId,
      frequency: frequency,
      nextRun: _calculateNextRun(frequency),
      recipients: recipients,
      isActive: true,
      configuration: {},
    );
  }

  SharedReport _generateMockSharedReport(
    String reportId,
    Duration expirationDuration,
    List<String> permissions,
  ) {
    return SharedReport(
      id: 'share_${DateTime.now().millisecondsSinceEpoch}',
      reportId: reportId,
      shareUrl:
          'https://reports.aivonity.com/shared/${DateTime.now().millisecondsSinceEpoch}',
      expirationDate: DateTime.now().add(expirationDuration),
      permissions: permissions,
      requiresPassword: false,
      accessCount: 0,
      createdDate: DateTime.now(),
    );
  }

  List<Report> _generateMockReports(String vehicleId) {
    return [
      Report(
        id: 'report_1',
        title: 'Monthly Performance Report',
        description: 'Performance analysis for the past month',
        type: ReportType.performance,
        generatedDate: DateTime.now().subtract(const Duration(days: 1)),
        vehicleId: vehicleId,
        data: const ReportData(),
        configuration: const ReportConfiguration(
          includeCharts: true,
          includeMetrics: true,
          includePredictions: false,
          period: TimePeriod.month,
          sections: ['summary', 'metrics'],
          format: ReportFormat.pdf,
          customSettings: {},
        ),
        status: ReportStatus.completed,
      ),
    ];
  }

  DateTime _calculateNextRun(ScheduleFrequency frequency) {
    final now = DateTime.now();
    switch (frequency) {
      case ScheduleFrequency.daily:
        return now.add(const Duration(days: 1));
      case ScheduleFrequency.weekly:
        return now.add(const Duration(days: 7));
      case ScheduleFrequency.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case ScheduleFrequency.quarterly:
        return DateTime(now.year, now.month + 3, now.day);
    }
  }

  pw.Widget _buildPerformanceSection(List<PerformanceMetrics> metrics) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, child: pw.Text('Performance Metrics')),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Fuel Efficiency',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Engine Health',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...metrics
                .take(10)
                .map(
                  (metric) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          metric.timestamp.toString().split(' ')[0],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${metric.fuelEfficiency.toStringAsFixed(1)} MPG',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '${(metric.engineHealth * 100).toStringAsFixed(0)}%',
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPredictionsSection(List<MaintenancePrediction> predictions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, child: pw.Text('Maintenance Predictions')),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Component',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Predicted Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Confidence',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...predictions.map(
              (prediction) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(prediction.componentName),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      prediction.predictedFailureDate.toString().split(' ')[0],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      '${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void dispose() {
    _reportsController.close();
    _schedulesController.close();
  }
}

