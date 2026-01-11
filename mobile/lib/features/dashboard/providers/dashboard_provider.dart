import 'package:flutter/foundation.dart';

/// AIVONITY Dashboard Provider
/// Manages dashboard data and vehicle information using basic Flutter state management
class DashboardProvider extends ChangeNotifier {
  DashboardData _dashboardData = DashboardData.initial();
  bool _isLoading = false;
  String? _error;

  // Getters
  DashboardData get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboardData() async {
    try {
      _setLoading(true);
      _clearError();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate mock dashboard data
      _dashboardData = _generateMockDashboardData();

      debugPrint('Dashboard data loaded successfully');
      notifyListeners();
    } catch (error) {
      _setError('Failed to load dashboard data: ${error.toString()}');
      debugPrint('Failed to load dashboard data: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshData() async {
    await loadDashboardData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  DashboardData _generateMockDashboardData() {
    return DashboardData(
      vehicles: [
        const VehicleInfo(
          id: '1',
          name: 'Tesla Model 3',
          year: '2023',
          healthScore: 0.92,
          mileage: 15420,
          status: 'Excellent',
        ),
        const VehicleInfo(
          id: '2',
          name: 'BMW X5',
          year: '2022',
          healthScore: 0.78,
          mileage: 28150,
          status: 'Good',
        ),
      ],
      alerts: [
        HealthAlert(
          id: '1',
          title: 'Oil Change Due',
          description: 'Your vehicle is due for an oil change in 500 miles',
          severity: AlertSeverity.medium,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        HealthAlert(
          id: '2',
          title: 'Tire Pressure Low',
          description: 'Front left tire pressure is below recommended level',
          severity: AlertSeverity.high,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
      performanceData: const PerformanceData(
        fuelEfficiency: 32.5,
        engineHealth: 0.95,
        batteryStatus: 0.87,
      ),
    );
  }
}

/// Dashboard Data Model
class DashboardData {
  final List<VehicleInfo> vehicles;
  final List<HealthAlert> alerts;
  final PerformanceData performanceData;

  const DashboardData({
    required this.vehicles,
    required this.alerts,
    required this.performanceData,
  });

  factory DashboardData.initial() {
    return const DashboardData(
      vehicles: [],
      alerts: [],
      performanceData: PerformanceData(
        fuelEfficiency: 0,
        engineHealth: 0,
        batteryStatus: 0,
      ),
    );
  }
}

/// Vehicle Information Model
class VehicleInfo {
  final String id;
  final String name;
  final String year;
  final double healthScore;
  final int mileage;
  final String status;

  const VehicleInfo({
    required this.id,
    required this.name,
    required this.year,
    required this.healthScore,
    required this.mileage,
    required this.status,
  });
}

/// Health Alert Model
class HealthAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;

  const HealthAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
  });
}

/// Alert Severity Enum
enum AlertSeverity { low, medium, high, critical }

/// Performance Data Model
class PerformanceData {
  final double fuelEfficiency;
  final double engineHealth;
  final double batteryStatus;

  const PerformanceData({
    required this.fuelEfficiency,
    required this.engineHealth,
    required this.batteryStatus,
  });
}

