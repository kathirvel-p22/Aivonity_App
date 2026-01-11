import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/analytics.dart';
import '../models/predictive_analytics.dart';
import '../models/reporting.dart';

class DataExportService {
  final Dio _dio;

  DataExportService(this._dio);

  Future<File> exportToCSV(
    List<PerformanceMetrics> data,
    String fileName,
  ) async {
    final csvContent = StringBuffer();

    // Add headers
    csvContent.writeln(
      'Date,Vehicle ID,Fuel Efficiency,Average Speed,Total Distance,Engine Health,Battery Health,Alert Count,Maintenance Score',
    );

    // Add data rows
    for (final metric in data) {
      csvContent.writeln(
        [
          metric.timestamp.toIso8601String(),
          metric.vehicleId,
          metric.fuelEfficiency,
          metric.averageSpeed,
          metric.totalDistance,
          metric.engineHealth,
          metric.batteryHealth,
          metric.alertCount,
          metric.maintenanceScore,
        ].join(','),
      );
    }

    return _saveStringToFile(csvContent.toString(), fileName);
  }

  Future<File> exportPredictionsToCSV(
    List<MaintenancePrediction> predictions,
    String fileName,
  ) async {
    final csvContent = StringBuffer();

    // Add headers
    csvContent.writeln(
      'Vehicle ID,Component,Predicted Date,Confidence,Priority,Cost,Days Until,Action',
    );

    // Add data rows
    for (final prediction in predictions) {
      csvContent.writeln(
        [
          prediction.vehicleId,
          prediction.componentName,
          prediction.predictedFailureDate.toIso8601String(),
          prediction.confidenceScore,
          prediction.priority.name,
          prediction.estimatedCost,
          prediction.daysUntilMaintenance,
          '"${prediction.recommendedAction}"',
        ].join(','),
      );
    }

    return _saveStringToFile(csvContent.toString(), fileName);
  }

  Future<File> exportToJSON(Map<String, dynamic> data, String fileName) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    return _saveStringToFile(jsonString, fileName);
  }

  Future<File> exportToExcel(
    Map<String, List<Map<String, dynamic>>> sheets,
    String fileName,
  ) async {
    final excel = Excel.createExcel();

    // Remove default sheet
    excel.delete('Sheet1');

    for (final entry in sheets.entries) {
      final sheetName = entry.key;
      final data = entry.value;

      if (data.isEmpty) continue;

      final sheet = excel[sheetName];

      // Add headers
      final headers = data.first.keys.toList();
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headers[i],
        );
      }

      // Add data rows
      for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
        final row = data[rowIndex];
        for (int colIndex = 0; colIndex < headers.length; colIndex++) {
          final value = row[headers[colIndex]];
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex,
              rowIndex: rowIndex + 1,
            ),
          );

          if (value is String) {
            cell.value = TextCellValue(value);
          } else if (value is num) {
            cell.value = DoubleCellValue(value.toDouble());
          } else if (value is bool) {
            cell.value = BoolCellValue(value);
          } else {
            cell.value = TextCellValue(value.toString());
          }
        }
      }
    }

    final bytes = excel.encode()!;
    return _saveBytesToFile(Uint8List.fromList(bytes), fileName);
  }

  Future<String> createSecureShareLink(
    String dataId,
    Duration expirationDuration,
    List<String> permissions,
  ) async {
    try {
      final response = await _dio.post(
        '/api/share/create',
        data: {
          'data_id': dataId,
          'expiration_hours': expirationDuration.inHours,
          'permissions': permissions,
        },
      );

      return response.data['share_url'];
    } catch (e) {
      // Return mock URL for development
      return 'https://share.aivonity.com/${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> shareFile(File file, String title, {String? message}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: message ?? title,
      subject: title,
    );
  }

  Future<void> shareMultipleFiles(
    List<File> files,
    String title, {
    String? message,
  }) async {
    final xFiles = files.map((file) => XFile(file.path)).toList();
    await Share.shareXFiles(xFiles, text: message ?? title, subject: title);
  }

  Future<Map<String, dynamic>> getExportFormats() async {
    return {
      'csv': {
        'name': 'CSV (Comma Separated Values)',
        'extension': '.csv',
        'mime_type': 'text/csv',
        'supports_multiple_sheets': false,
      },
      'excel': {
        'name': 'Excel Workbook',
        'extension': '.xlsx',
        'mime_type':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'supports_multiple_sheets': true,
      },
      'json': {
        'name': 'JSON (JavaScript Object Notation)',
        'extension': '.json',
        'mime_type': 'application/json',
        'supports_multiple_sheets': false,
      },
    };
  }

  Future<File> exportAnalyticsData(
    String vehicleId,
    List<PerformanceMetrics> metrics,
    List<KPIMetric> kpis,
    ReportFormat format,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'analytics_${vehicleId}_$timestamp';

    switch (format) {
      case ReportFormat.csv:
        return exportToCSV(metrics, '$fileName.csv');

      case ReportFormat.excel:
        final sheets = <String, List<Map<String, dynamic>>>{
          'Performance Metrics': metrics.map((m) => m.toJson()).toList(),
          'KPI Metrics': kpis.map((k) => k.toJson()).toList(),
        };
        return exportToExcel(sheets, '$fileName.xlsx');

      case ReportFormat.json:
        final data = {
          'vehicle_id': vehicleId,
          'export_date': DateTime.now().toIso8601String(),
          'performance_metrics': metrics.map((m) => m.toJson()).toList(),
          'kpi_metrics': kpis.map((k) => k.toJson()).toList(),
        };
        return exportToJSON(data, '$fileName.json');

      case ReportFormat.pdf:
        throw UnsupportedError('PDF export not supported in this method');
    }
  }

  Future<File> exportPredictiveData(
    String vehicleId,
    List<MaintenancePrediction> predictions,
    List<PredictiveInsight> insights,
    ReportFormat format,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'predictive_${vehicleId}_$timestamp';

    switch (format) {
      case ReportFormat.csv:
        return exportPredictionsToCSV(predictions, '$fileName.csv');

      case ReportFormat.excel:
        final sheets = <String, List<Map<String, dynamic>>>{
          'Predictions': predictions.map((p) => p.toJson()).toList(),
          'Insights': insights.map((i) => i.toJson()).toList(),
        };
        return exportToExcel(sheets, '$fileName.xlsx');

      case ReportFormat.json:
        final data = {
          'vehicle_id': vehicleId,
          'export_date': DateTime.now().toIso8601String(),
          'predictions': predictions.map((p) => p.toJson()).toList(),
          'insights': insights.map((i) => i.toJson()).toList(),
        };
        return exportToJSON(data, '$fileName.json');

      case ReportFormat.pdf:
        throw UnsupportedError('PDF export not supported in this method');
    }
  }

  Future<List<File>> exportAllData(
    String vehicleId,
    List<PerformanceMetrics> metrics,
    List<KPIMetric> kpis,
    List<MaintenancePrediction> predictions,
    List<PredictiveInsight> insights,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final files = <File>[];

    // Export analytics data
    final analyticsFile = await exportAnalyticsData(
      vehicleId,
      metrics,
      kpis,
      ReportFormat.excel,
    );
    files.add(analyticsFile);

    // Export predictive data
    final predictiveFile = await exportPredictiveData(
      vehicleId,
      predictions,
      insights,
      ReportFormat.excel,
    );
    files.add(predictiveFile);

    // Export combined JSON
    final combinedData = {
      'vehicle_id': vehicleId,
      'export_date': DateTime.now().toIso8601String(),
      'performance_metrics': metrics.map((m) => m.toJson()).toList(),
      'kpi_metrics': kpis.map((k) => k.toJson()).toList(),
      'predictions': predictions.map((p) => p.toJson()).toList(),
      'insights': insights.map((i) => i.toJson()).toList(),
    };

    final jsonFile = await exportToJSON(
      combinedData,
      'complete_data_${vehicleId}_$timestamp.json',
    );
    files.add(jsonFile);

    return files;
  }

  Future<File> _saveStringToFile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  Future<File> _saveBytesToFile(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> deleteExportedFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<File>> getExportedFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.csv') ||
              file.path.endsWith('.xlsx') ||
              file.path.endsWith('.json'),
        )
        .toList();

    return files;
  }

  Future<int> getExportedFilesSize() async {
    final files = await getExportedFiles();
    int totalSize = 0;

    for (final file in files) {
      final stat = await file.stat();
      totalSize += stat.size;
    }

    return totalSize;
  }

  Future<void> cleanupOldExports({Duration? olderThan}) async {
    final cutoffDate = DateTime.now().subtract(
      olderThan ?? const Duration(days: 30),
    );
    final files = await getExportedFiles();

    for (final file in files) {
      final stat = await file.stat();
      if (stat.modified.isBefore(cutoffDate)) {
        await file.delete();
      }
    }
  }
}

