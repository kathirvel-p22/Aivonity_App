import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/predictive_analytics.dart';
import '../models/analytics.dart' show PerformanceMetrics, TimePeriod;
import '../config/api_config.dart';

class PredictiveAnalyticsService {
  final Dio _dio;
  final BehaviorSubject<List<MaintenancePrediction>> _predictionsController =
      BehaviorSubject<List<MaintenancePrediction>>();
  final BehaviorSubject<List<PredictiveInsight>> _insightsController =
      BehaviorSubject<List<PredictiveInsight>>();

  PredictiveAnalyticsService(this._dio);

  Stream<List<MaintenancePrediction>> get predictionsStream =>
      _predictionsController.stream;
  Stream<List<PredictiveInsight>> get insightsStream =>
      _insightsController.stream;

  Future<List<MaintenancePrediction>> getMaintenancePredictions(
    String vehicleId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/predictive/maintenance/$vehicleId',
      );

      final predictions = (response.data as List)
          .map((json) => MaintenancePrediction.fromJson(json))
          .toList();

      _predictionsController.add(predictions);
      return predictions;
    } catch (e) {
      // Return mock data for development
      final mockPredictions = _generateMockMaintenancePredictions(vehicleId);
      _predictionsController.add(mockPredictions);
      return mockPredictions;
    }
  }

  Future<MaintenanceSchedule> generateMaintenanceSchedule(
    String vehicleId,
    TimePeriod period,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/predictive/schedule/$vehicleId',
        data: {'period': period.name},
      );

      return MaintenanceSchedule.fromJson(response.data);
    } catch (e) {
      // Return mock data for development
      return _generateMockMaintenanceSchedule(vehicleId, period);
    }
  }

  Future<List<PredictionModel>> getAvailableModels() async {
    try {
      final response = await _dio.get('${ApiConfig.baseUrl}/predictive/models');

      return (response.data as List)
          .map((json) => PredictionModel.fromJson(json))
          .toList();
    } catch (e) {
      // Return mock data for development
      return _generateMockPredictionModels();
    }
  }

  Future<PredictionAccuracy> getModelAccuracy(String modelId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/predictive/models/$modelId/accuracy',
      );

      return PredictionAccuracy.fromJson(response.data);
    } catch (e) {
      // Return mock data for development
      return _generateMockPredictionAccuracy(modelId);
    }
  }

  Future<ConfidenceInterval> getPredictionConfidence(
    String vehicleId,
    String componentId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/predictive/confidence/$vehicleId/$componentId',
      );

      return ConfidenceInterval.fromJson(response.data);
    } catch (e) {
      // Return mock data for development
      return _generateMockConfidenceInterval();
    }
  }

  Future<List<PredictiveInsight>> generateInsights(
    String vehicleId,
    List<PerformanceMetrics> historicalData,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/predictive/insights/$vehicleId',
        data: {
          'historical_data': historicalData.map((m) => m.toJson()).toList(),
        },
      );

      final insights = (response.data as List)
          .map((json) => PredictiveInsight.fromJson(json))
          .toList();

      _insightsController.add(insights);
      return insights;
    } catch (e) {
      // Return mock data for development
      final mockInsights = _generateMockPredictiveInsights(vehicleId);
      _insightsController.add(mockInsights);
      return mockInsights;
    }
  }

  Future<Map<String, dynamic>> runPredictionModel(
    String modelId,
    Map<String, dynamic> inputData,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/predictive/models/$modelId/predict',
        data: inputData,
      );

      return response.data;
    } catch (e) {
      // Return mock prediction result
      return _generateMockPredictionResult();
    }
  }

  Future<double> calculateRiskScore(
    String vehicleId,
    String componentId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/predictive/risk/$vehicleId/$componentId',
      );

      return response.data['risk_score'].toDouble();
    } catch (e) {
      // Return mock risk score
      final random = Random();
      return random.nextDouble() * 100;
    }
  }

  // Mock data generation methods for development
  List<MaintenancePrediction> _generateMockMaintenancePredictions(
    String vehicleId,
  ) {
    final random = Random();
    final components = [
      'Engine Oil',
      'Brake Pads',
      'Air Filter',
      'Battery',
      'Transmission Fluid',
      'Spark Plugs',
      'Coolant System',
      'Tire Rotation',
    ];

    return List.generate(5, (index) {
      final component = components[random.nextInt(components.length)];
      final daysUntil = 7 + random.nextInt(180);

      return MaintenancePrediction(
        vehicleId: vehicleId,
        componentId: 'comp_${index + 1}',
        componentName: component,
        predictedFailureDate: DateTime.now().add(Duration(days: daysUntil)),
        confidenceScore: 0.7 + random.nextDouble() * 0.3,
        priority: MaintenancePriority.values[random.nextInt(4)],
        symptoms: _generateSymptoms(component),
        estimatedCost: 50.0 + random.nextDouble() * 500,
        daysUntilMaintenance: daysUntil,
        recommendedAction: _generateRecommendedAction(component),
      );
    });
  }

  List<String> _generateSymptoms(String component) {
    final symptomMap = {
      'Engine Oil': ['Dark oil color', 'Engine noise', 'Oil level low'],
      'Brake Pads': ['Squeaking noise', 'Reduced braking', 'Vibration'],
      'Air Filter': [
        'Reduced acceleration',
        'Poor fuel economy',
        'Engine misfires',
      ],
      'Battery': ['Slow engine crank', 'Dim lights', 'Dashboard warning'],
      'Transmission Fluid': ['Rough shifting', 'Slipping gears', 'Fluid leaks'],
      'Spark Plugs': ['Engine misfires', 'Poor acceleration', 'Rough idle'],
      'Coolant System': [
        'Engine overheating',
        'Coolant leaks',
        'Temperature warning',
      ],
      'Tire Rotation': ['Uneven wear', 'Vibration', 'Reduced traction'],
    };

    return symptomMap[component] ?? ['General wear', 'Performance degradation'];
  }

  String _generateRecommendedAction(String component) {
    final actionMap = {
      'Engine Oil': 'Schedule oil change within 2 weeks',
      'Brake Pads': 'Inspect and replace brake pads immediately',
      'Air Filter': 'Replace air filter at next service',
      'Battery': 'Test battery and replace if necessary',
      'Transmission Fluid': 'Check transmission fluid level and condition',
      'Spark Plugs': 'Replace spark plugs during next tune-up',
      'Coolant System': 'Inspect cooling system for leaks',
      'Tire Rotation': 'Rotate tires and check alignment',
    };

    return actionMap[component] ?? 'Schedule inspection';
  }

  MaintenanceSchedule _generateMockMaintenanceSchedule(
    String vehicleId,
    TimePeriod period,
  ) {
    final random = Random();
    final now = DateTime.now();
    final periodDays = _getPeriodDays(period);

    final scheduledItems = List.generate(3 + random.nextInt(5), (index) {
      final daysFromNow = random.nextInt(periodDays);

      return ScheduledMaintenance(
        id: 'sched_${index + 1}',
        componentName: [
          'Engine Oil',
          'Brake Inspection',
          'Tire Rotation',
          'Air Filter',
        ][random.nextInt(4)],
        scheduledDate: now.add(Duration(days: daysFromNow)),
        priority: MaintenancePriority.values[random.nextInt(4)],
        estimatedCost: 50.0 + random.nextDouble() * 300,
        estimatedDuration: 30 + random.nextInt(120),
        description: 'Scheduled maintenance based on predictive analysis',
        requiredParts: ['Filter', 'Oil', 'Gasket'],
        isPreventive: random.nextBool(),
      );
    });

    return MaintenanceSchedule(
      vehicleId: vehicleId,
      scheduledItems: scheduledItems,
      generatedDate: now,
      period: period,
      totalEstimatedCost: scheduledItems.fold(
        0.0,
        (sum, item) => sum + item.estimatedCost,
      ),
    );
  }

  List<PredictionModel> _generateMockPredictionModels() {
    final random = Random();
    return [
      PredictionModel(
        modelId: 'model_engine_health',
        modelName: 'Engine Health Predictor',
        type: ModelType.regression,
        accuracy: 0.85 + random.nextDouble() * 0.1,
        lastTrained: DateTime.now().subtract(
          Duration(days: random.nextInt(30)),
        ),
        features: ['oil_pressure', 'temperature', 'vibration', 'mileage'],
        featureImportance: {
          'oil_pressure': 0.35,
          'temperature': 0.28,
          'vibration': 0.22,
          'mileage': 0.15,
        },
        status: ModelStatus.active,
      ),
      PredictionModel(
        modelId: 'model_brake_wear',
        modelName: 'Brake Wear Classifier',
        type: ModelType.classification,
        accuracy: 0.92 + random.nextDouble() * 0.05,
        lastTrained: DateTime.now().subtract(
          Duration(days: random.nextInt(15)),
        ),
        features: ['brake_pressure', 'pad_thickness', 'usage_pattern'],
        featureImportance: {
          'brake_pressure': 0.45,
          'pad_thickness': 0.35,
          'usage_pattern': 0.20,
        },
        status: ModelStatus.active,
      ),
    ];
  }

  PredictionAccuracy _generateMockPredictionAccuracy(String modelId) {
    final random = Random();

    return PredictionAccuracy(
      modelId: modelId,
      overallAccuracy: 0.85 + random.nextDouble() * 0.1,
      precision: 0.82 + random.nextDouble() * 0.15,
      recall: 0.88 + random.nextDouble() * 0.1,
      f1Score: 0.85 + random.nextDouble() * 0.1,
      classAccuracy: {'low_risk': 0.95, 'medium_risk': 0.87, 'high_risk': 0.82},
      evaluationDate: DateTime.now().subtract(
        Duration(days: random.nextInt(7)),
      ),
    );
  }

  ConfidenceInterval _generateMockConfidenceInterval() {
    final random = Random();
    final mean = 50 + random.nextDouble() * 100;
    final std = 5 + random.nextDouble() * 15;

    return ConfidenceInterval(
      lowerBound: mean - (1.96 * std),
      upperBound: mean + (1.96 * std),
      meanValue: mean,
      standardDeviation: std,
      confidenceLevel: 0.95,
    );
  }

  List<PredictiveInsight> _generateMockPredictiveInsights(String vehicleId) {
    final random = Random();

    return [
      PredictiveInsight(
        id: 'insight_1',
        title: 'Fuel Efficiency Optimization',
        description:
            'Based on driving patterns, adjusting maintenance schedule could improve fuel efficiency by 8%',
        type: InsightType.efficiencyEnhancement,
        impact: 0.8,
        recommendations: [
          'Schedule engine tune-up',
          'Check tire pressure weekly',
          'Replace air filter',
        ],
        createdDate: DateTime.now(),
        metadata: {'potential_savings': 150.0, 'confidence': 0.85},
      ),
      PredictiveInsight(
        id: 'insight_2',
        title: 'Brake System Risk',
        description:
            'Brake pad wear pattern indicates potential failure within 30 days',
        type: InsightType.riskMitigation,
        impact: 0.95,
        recommendations: [
          'Immediate brake inspection',
          'Replace brake pads',
          'Check brake fluid',
        ],
        createdDate: DateTime.now(),
        metadata: {'risk_level': 'high', 'days_until_failure': 28},
      ),
    ];
  }

  Map<String, dynamic> _generateMockPredictionResult() {
    final random = Random();

    return {
      'prediction': random.nextDouble() * 100,
      'confidence': 0.7 + random.nextDouble() * 0.3,
      'risk_factors': ['high_mileage', 'aggressive_driving'],
      'recommendations': ['Regular maintenance', 'Monitor closely'],
    };
  }

  int _getPeriodDays(TimePeriod period) {
    switch (period) {
      case TimePeriod.week:
        return 7;
      case TimePeriod.month:
        return 30;
      case TimePeriod.quarter:
        return 90;
      case TimePeriod.year:
        return 365;
      case TimePeriod.day:
        return 1;
    }
  }

  void dispose() {
    _predictionsController.close();
    _insightsController.close();
  }
}

