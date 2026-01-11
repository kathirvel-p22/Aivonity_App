import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/analytics.dart';
import '../config/api_config.dart';

class AnalyticsService {
  final Dio _dio;
  final BehaviorSubject<List<PerformanceMetrics>> _metricsController =
      BehaviorSubject<List<PerformanceMetrics>>();
  final BehaviorSubject<List<KPIMetric>> _kpiController =
      BehaviorSubject<List<KPIMetric>>();

  AnalyticsService(this._dio);

  Stream<List<PerformanceMetrics>> get metricsStream =>
      _metricsController.stream;
  Stream<List<KPIMetric>> get kpiStream => _kpiController.stream;

  Future<PerformanceMetrics> getPerformanceMetrics(
    String vehicleId,
    TimePeriod period,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/analytics/performance/$vehicleId',
        queryParameters: {'period': period.name},
      );

      return PerformanceMetrics.fromJson(response.data);
    } catch (e) {
      // Return mock data for development
      return _generateMockPerformanceMetrics(vehicleId);
    }
  }

  Future<TrendAnalysis> getTrendAnalysis(
    String vehicleId,
    TimePeriod period,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/analytics/trends/$vehicleId',
        queryParameters: {'period': period.name},
      );

      return TrendAnalysis.fromJson(response.data);
    } catch (e) {
      // Return mock data for development
      return _generateMockTrendAnalysis(vehicleId, period);
    }
  }

  Future<List<KPIMetric>> getKPIMetrics(String vehicleId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/analytics/kpi/$vehicleId',
      );

      final kpis = (response.data as List)
          .map((json) => KPIMetric.fromJson(json))
          .toList();

      _kpiController.add(kpis);
      return kpis;
    } catch (e) {
      // Return mock data for development
      final mockKpis = _generateMockKPIMetrics(vehicleId);
      _kpiController.add(mockKpis);
      return mockKpis;
    }
  }

  Future<ChartData> getChartData(
    String vehicleId,
    ChartType chartType,
    TimePeriod period,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/analytics/charts/$vehicleId',
        queryParameters: {'type': chartType.name, 'period': period.name},
      );

      return ChartData.fromJson(response.data);
    } catch (e) {
      // Return mock data for development
      return _generateMockChartData(chartType, period);
    }
  }

  Future<List<PerformanceMetrics>> getHistoricalMetrics(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/analytics/historical/$vehicleId',
        queryParameters: {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
      );

      final metrics = (response.data as List)
          .map((json) => PerformanceMetrics.fromJson(json))
          .toList();

      _metricsController.add(metrics);
      return metrics;
    } catch (e) {
      // Return mock data for development
      final mockMetrics = _generateMockHistoricalMetrics(
        vehicleId,
        startDate,
        endDate,
      );
      _metricsController.add(mockMetrics);
      return mockMetrics;
    }
  }

  Future<Map<String, dynamic>> comparePerformance(
    String vehicleId,
    TimePeriod currentPeriod,
    TimePeriod previousPeriod,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/analytics/compare/$vehicleId',
        queryParameters: {
          'current': currentPeriod.name,
          'previous': previousPeriod.name,
        },
      );

      return response.data;
    } catch (e) {
      // Return mock comparison data
      return _generateMockComparison();
    }
  }

  // Mock data generation methods for development
  PerformanceMetrics _generateMockPerformanceMetrics(String vehicleId) {
    final random = Random();
    return PerformanceMetrics(
      vehicleId: vehicleId,
      timestamp: DateTime.now(),
      fuelEfficiency: 25.0 + random.nextDouble() * 10,
      averageSpeed: 45.0 + random.nextDouble() * 20,
      totalDistance: 1000 + random.nextInt(5000),
      engineHealth: 0.8 + random.nextDouble() * 0.2,
      batteryHealth: 0.85 + random.nextDouble() * 0.15,
      alertCount: random.nextInt(5),
      maintenanceScore: 0.7 + random.nextDouble() * 0.3,
    );
  }

  TrendAnalysis _generateMockTrendAnalysis(
    String vehicleId,
    TimePeriod period,
  ) {
    final random = Random();
    final now = DateTime.now();
    final dataPoints = List.generate(30, (index) {
      return DataPoint(
        timestamp: now.subtract(Duration(days: 29 - index)),
        value: 20 + random.nextDouble() * 15 + sin(index * 0.2) * 5,
      );
    });

    return TrendAnalysis(
      vehicleId: vehicleId,
      period: period,
      fuelEfficiencyTrend: dataPoints,
      maintenanceCostTrend: dataPoints
          .map(
            (dp) => DataPoint(
              timestamp: dp.timestamp,
              value: dp.value * 0.8 + random.nextDouble() * 10,
            ),
          )
          .toList(),
      performanceTrend: dataPoints
          .map(
            (dp) => DataPoint(
              timestamp: dp.timestamp,
              value: dp.value * 1.2 + random.nextDouble() * 5,
            ),
          )
          .toList(),
      overallTrend: TrendDirection.values[random.nextInt(3)],
      trendConfidence: 0.7 + random.nextDouble() * 0.3,
    );
  }

  List<KPIMetric> _generateMockKPIMetrics(String vehicleId) {
    return [
      KPIMetric(
        id: 'fuel_efficiency',
        name: 'Fuel Efficiency',
        currentValue: 28.5,
        previousValue: 26.2,
        unit: 'MPG',
        trend: KPITrend.improving,
        changePercentage: 8.8,
        description: 'Average fuel consumption efficiency',
        type: MetricType.efficiency,
      ),
      KPIMetric(
        id: 'engine_health',
        name: 'Engine Health',
        currentValue: 92.0,
        previousValue: 89.5,
        unit: '%',
        trend: KPITrend.improving,
        changePercentage: 2.8,
        description: 'Overall engine condition score',
        type: MetricType.performance,
      ),
      KPIMetric(
        id: 'maintenance_cost',
        name: 'Maintenance Cost',
        currentValue: 245.0,
        previousValue: 312.0,
        unit: '\$',
        trend: KPITrend.improving,
        changePercentage: -21.5,
        description: 'Monthly maintenance expenses',
        type: MetricType.cost,
      ),
      KPIMetric(
        id: 'alert_frequency',
        name: 'Alert Frequency',
        currentValue: 2.0,
        previousValue: 5.0,
        unit: 'alerts/week',
        trend: KPITrend.improving,
        changePercentage: -60.0,
        description: 'Average number of alerts per week',
        type: MetricType.maintenance,
      ),
    ];
  }

  ChartData _generateMockChartData(ChartType chartType, TimePeriod period) {
    final random = Random();
    final now = DateTime.now();

    final dataPoints = List.generate(20, (index) {
      return DataPoint(
        timestamp: now.subtract(Duration(days: 19 - index)),
        value: 20 + random.nextDouble() * 30 + sin(index * 0.3) * 10,
      );
    });

    return ChartData(
      title: 'Performance Trends',
      type: chartType,
      series: [
        DataSeries(
          name: 'Fuel Efficiency',
          data: dataPoints,
          color: '#2196F3',
          type: SeriesType.line,
        ),
        DataSeries(
          name: 'Engine Performance',
          data: dataPoints
              .map(
                (dp) => DataPoint(
                  timestamp: dp.timestamp,
                  value: dp.value * 0.9 + random.nextDouble() * 5,
                ),
              )
              .toList(),
          color: '#4CAF50',
          type: SeriesType.line,
        ),
      ],
      configuration: const ChartConfiguration(
        showGrid: true,
        showLegend: true,
        enableInteraction: true,
        xAxisLabel: 'Date',
        yAxisLabel: 'Value',
      ),
    );
  }

  List<PerformanceMetrics> _generateMockHistoricalMetrics(
    String vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final random = Random();
    final days = endDate.difference(startDate).inDays;

    return List.generate(days, (index) {
      final date = startDate.add(Duration(days: index));
      return PerformanceMetrics(
        vehicleId: vehicleId,
        timestamp: date,
        fuelEfficiency: 25.0 + random.nextDouble() * 10,
        averageSpeed: 45.0 + random.nextDouble() * 20,
        totalDistance: 50 + random.nextInt(200),
        engineHealth: 0.8 + random.nextDouble() * 0.2,
        batteryHealth: 0.85 + random.nextDouble() * 0.15,
        alertCount: random.nextInt(3),
        maintenanceScore: 0.7 + random.nextDouble() * 0.3,
      );
    });
  }

  Map<String, dynamic> _generateMockComparison() {
    return {
      'fuelEfficiencyChange': 8.5,
      'performanceChange': 12.3,
      'maintenanceCostChange': -15.2,
      'overallImprovement': 5.2,
      'summary': 'Vehicle performance has improved significantly this period',
    };
  }

  void dispose() {
    _metricsController.close();
    _kpiController.close();
  }
}

