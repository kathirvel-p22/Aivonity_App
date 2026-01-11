import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../models/rca_report.dart';

/// Analytics data model
class AnalyticsData {
  final List<RCAReport> rcaReports;
  final Map<String, dynamic> maintenanceData;
  final Map<String, dynamic> trendData;
  final List<String> recommendations;
  final int totalIssues;
  final int resolvedIssues;
  final double avgResolutionTime;

  const AnalyticsData({
    required this.rcaReports,
    required this.maintenanceData,
    required this.trendData,
    required this.recommendations,
    required this.totalIssues,
    required this.resolvedIssues,
    required this.avgResolutionTime,
  });

  AnalyticsData copyWith({
    List<RCAReport>? rcaReports,
    Map<String, dynamic>? maintenanceData,
    Map<String, dynamic>? trendData,
    List<String>? recommendations,
    int? totalIssues,
    int? resolvedIssues,
    double? avgResolutionTime,
  }) {
    return AnalyticsData(
      rcaReports: rcaReports ?? this.rcaReports,
      maintenanceData: maintenanceData ?? this.maintenanceData,
      trendData: trendData ?? this.trendData,
      recommendations: recommendations ?? this.recommendations,
      totalIssues: totalIssues ?? this.totalIssues,
      resolvedIssues: resolvedIssues ?? this.resolvedIssues,
      avgResolutionTime: avgResolutionTime ?? this.avgResolutionTime,
    );
  }
}

/// AIVONITY Analytics Provider
/// Manages analytics data and RCA reports
class AnalyticsNotifier extends StateNotifier<AsyncValue<AnalyticsData>>
    with LoggingMixin {
  AnalyticsNotifier() : super(const AsyncValue.loading());

  Future<void> loadRCAReports({
    String? vehicleId,
    String timeRange = '30D',
  }) async {
    try {
      state = const AsyncValue.loading();

      // In a real app, this would call the API
      // For now, we'll generate mock data
      final mockData = _generateMockAnalyticsData(timeRange);

      state = AsyncValue.data(mockData);
      logInfo('Loaded analytics data for time range: $timeRange');
    } catch (error, stackTrace) {
      logError('Failed to load RCA reports', error);
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> filterByCategory(String category) async {
    try {
      final currentData = state.value;
      if (currentData == null) return;

      List<RCAReport> filteredReports;
      if (category == 'All') {
        filteredReports = currentData.rcaReports;
      } else {
        filteredReports = currentData.rcaReports
            .where((report) => report.category == category)
            .toList();
      }

      final filteredData = AnalyticsData(
        rcaReports: filteredReports,
        maintenanceData: currentData.maintenanceData,
        trendData: currentData.trendData,
        recommendations: currentData.recommendations,
        totalIssues: filteredReports.length,
        resolvedIssues:
            filteredReports.where((r) => r.status == RCAStatus.resolved).length,
        avgResolutionTime: currentData.avgResolutionTime,
      );

      state = AsyncValue.data(filteredData);
      logInfo('Filtered reports by category: $category');
    } catch (error, stackTrace) {
      logError('Failed to filter by category', error);
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> exportReports() async {
    try {
      // Mock export functionality
      await Future.delayed(const Duration(seconds: 2));
      logInfo('Reports exported successfully');
    } catch (error) {
      logError('Failed to export reports', error);
      rethrow;
    }
  }

  Future<void> shareReports() async {
    try {
      // Mock share functionality
      await Future.delayed(const Duration(seconds: 1));
      logInfo('Reports shared successfully');
    } catch (error) {
      logError('Failed to share reports', error);
      rethrow;
    }
  }

  AnalyticsData _generateMockAnalyticsData(String timeRange) {
    final mockReports = [
      RCAReport(
        id: '1',
        title: 'Engine Temperature Alert',
        description: 'Recurring engine overheating issues detected',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 2)),
        status: RCAStatus.resolved,
        severity: RCASeverity.high,
        category: 'Engine',
        vehicleId: 'vehicle_1',
        symptoms: [
          'Engine temperature above normal range',
          'Coolant level dropping',
          'Steam from engine bay',
        ],
        rootCauses: [
          'Faulty thermostat',
          'Coolant leak in radiator',
          'Blocked cooling system',
        ],
        recommendations: [
          'Replace thermostat',
          'Repair radiator leak',
          'Flush cooling system',
        ],
        correctiveActions: [
          'Thermostat replaced',
          'Radiator repaired',
          'Cooling system flushed',
        ],
      ),
      RCAReport(
        id: '2',
        title: 'Brake Performance Issue',
        description: 'Decreased braking efficiency observed',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        status: RCAStatus.inProgress,
        severity: RCASeverity.medium,
        category: 'Brakes',
        vehicleId: 'vehicle_1',
        symptoms: [
          'Longer stopping distances',
          'Brake pedal feels soft',
          'Grinding noise when braking',
        ],
        rootCauses: [
          'Worn brake pads',
          'Low brake fluid',
          'Warped brake rotors',
        ],
        recommendations: [
          'Replace brake pads',
          'Top up brake fluid',
          'Resurface or replace rotors',
        ],
        correctiveActions: ['Brake pads ordered', 'Brake fluid topped up'],
      ),
      RCAReport(
        id: '3',
        title: 'Electrical System Malfunction',
        description:
            'Intermittent electrical issues affecting multiple systems',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        status: RCAStatus.open,
        severity: RCASeverity.critical,
        category: 'Electrical',
        vehicleId: 'vehicle_1',
        symptoms: [
          'Dashboard lights flickering',
          'Radio cutting out',
          'Headlights dimming',
        ],
        rootCauses: [
          'Loose battery connections',
          'Failing alternator',
          'Corroded wiring harness',
        ],
        recommendations: [
          'Tighten battery connections',
          'Test and replace alternator if needed',
          'Inspect and clean wiring harness',
        ],
        correctiveActions: [],
      ),
    ];

    final maintenanceData = {
      'monthlyMaintenance': [
        {'month': 'Jan', 'count': 3},
        {'month': 'Feb', 'count': 5},
        {'month': 'Mar', 'count': 2},
        {'month': 'Apr', 'count': 7},
        {'month': 'May', 'count': 4},
        {'month': 'Jun', 'count': 6},
      ],
      'categoryBreakdown': [
        {'category': 'Engine', 'percentage': 35},
        {'category': 'Brakes', 'percentage': 25},
        {'category': 'Electrical', 'percentage': 20},
        {'category': 'Transmission', 'percentage': 15},
        {'category': 'Other', 'percentage': 5},
      ],
    };

    final trendData = {
      'issueFrequency': [
        {'week': 'W1', 'issues': 2},
        {'week': 'W2', 'issues': 4},
        {'week': 'W3', 'issues': 1},
        {'week': 'W4', 'issues': 3},
      ],
      'resolutionTime': [
        {'category': 'Engine', 'avgHours': 24},
        {'category': 'Brakes', 'avgHours': 8},
        {'category': 'Electrical', 'avgHours': 16},
        {'category': 'Transmission', 'avgHours': 32},
      ],
    };

    final recommendations = [
      'Schedule regular coolant system inspections every 6 months',
      'Monitor brake pad wear more frequently during high-usage periods',
      'Implement preventive electrical system checks quarterly',
      'Consider upgrading to higher-quality replacement parts',
      'Establish predictive maintenance schedule based on usage patterns',
    ];

    return AnalyticsData(
      rcaReports: mockReports,
      maintenanceData: maintenanceData,
      trendData: trendData,
      recommendations: recommendations,
      totalIssues: mockReports.length,
      resolvedIssues:
          mockReports.where((r) => r.status == RCAStatus.resolved).length,
      avgResolutionTime: 16.5,
    );
  }
}

/// Analytics Provider
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AsyncValue<AnalyticsData>>(
  (ref) => AnalyticsNotifier(),
);

