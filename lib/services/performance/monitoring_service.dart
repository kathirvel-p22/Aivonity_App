import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive monitoring and observability service
class MonitoringService {
  static const String _metricsPrefix = 'monitoring_metrics_';
  static const String _alertsPrefix = 'monitoring_alerts_';

  SharedPreferences? _prefs;
  Timer? _metricsTimer;

  final StreamController<SystemMetrics> _metricsController =
      StreamController<SystemMetrics>.broadcast();
  final StreamController<MonitoringAlert> _alertsController =
      StreamController<MonitoringAlert>.broadcast();

  final List<SystemMetrics> _metricsHistory = [];
  final List<MonitoringAlert> _activeAlerts = [];
  final List<LogEntry> _recentLogs = [];

  /// Streams for monitoring data
  Stream<SystemMetrics> get metricsStream => _metricsController.stream;
  Stream<MonitoringAlert> get alertsStream => _alertsController.stream;

  /// Initialize the monitoring service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _startMetricsCollection();

    print('📊 Monitoring service initialized');
  }

  /// Collect and emit system metrics
  Future<void> collectMetrics() async {
    try {
      final metrics = SystemMetrics(
        timestamp: DateTime.now(),
        cpuUsage: await _getCpuUsage(),
        memoryUsage: await _getMemoryUsage(),
        diskUsage: await _getDiskUsage(),
        networkLatency: await _getNetworkLatency(),
        activeConnections: await _getActiveConnections(),
        requestsPerMinute: await _getRequestsPerMinute(),
        errorRate: await _getErrorRate(),
        responseTime: await _getAverageResponseTime(),
        throughput: await _getThroughput(),
      );

      // Store metrics
      _metricsHistory.add(metrics);

      // Keep only last 1000 metrics
      if (_metricsHistory.length > 1000) {
        _metricsHistory.removeAt(0);
      }

      // Emit metrics
      _metricsController.add(metrics);

      // Check for alerts
      _checkAlertConditions(metrics);
    } catch (e) {
      print('❌ Error collecting metrics: $e');
    }
  }

  /// Log an event with structured data
  void logEvent(
    String message,
    LogLevel level, {
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    final logEntry = LogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      category: category ?? 'general',
      metadata: metadata ?? {},
    );

    _recentLogs.add(logEntry);

    // Keep only last 1000 logs
    if (_recentLogs.length > 1000) {
      _recentLogs.removeAt(0);
    }

    print('📝 ${level.name.toUpperCase()}: $message');
  }

  /// Get real-time dashboard data
  Future<MonitoringDashboard> getDashboardData() async {
    final currentMetrics = _metricsHistory.isNotEmpty
        ? _metricsHistory.last
        : null;
    final recentAlerts = _activeAlerts
        .where(
          (alert) =>
              DateTime.now().difference(alert.timestamp) <= Duration(hours: 24),
        )
        .toList();

    return MonitoringDashboard(
      currentMetrics: currentMetrics,
      activeAlerts: recentAlerts,
      systemHealth: _calculateSystemHealth(),
      uptime: Duration(hours: 24),
      totalRequests: 10000,
      errorCount: 50,
      averageResponseTime: currentMetrics?.responseTime ?? Duration.zero,
      throughput: currentMetrics?.throughput ?? 0.0,
    );
  }

  // Private helper methods

  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      await collectMetrics();
    });
  }

  void _checkAlertConditions(SystemMetrics metrics) {
    // Check CPU usage
    if (metrics.cpuUsage > 80.0) {
      _createAlert(
        'High CPU Usage',
        'CPU usage is ${metrics.cpuUsage.toStringAsFixed(1)}%',
        AlertSeverity.warning,
      );
    }

    // Check memory usage
    if (metrics.memoryUsage > 85.0) {
      _createAlert(
        'High Memory Usage',
        'Memory usage is ${metrics.memoryUsage.toStringAsFixed(1)}%',
        AlertSeverity.warning,
      );
    }

    // Check response time
    if (metrics.responseTime.inMilliseconds > 2000) {
      _createAlert(
        'Slow Response Time',
        'Response time is ${metrics.responseTime.inMilliseconds}ms',
        AlertSeverity.medium,
      );
    }
  }

  void _createAlert(String title, String description, AlertSeverity severity) {
    final alert = MonitoringAlert(
      id: _generateAlertId(),
      title: title,
      description: description,
      severity: severity,
      timestamp: DateTime.now(),
      isResolved: false,
    );

    _activeAlerts.add(alert);
    _alertsController.add(alert);

    print('🚨 Alert: $title - $description');
  }

  SystemHealthStatus _calculateSystemHealth() {
    if (_metricsHistory.isEmpty) return SystemHealthStatus.unknown;

    final latest = _metricsHistory.last;

    if (latest.cpuUsage > 90 || latest.memoryUsage > 95) {
      return SystemHealthStatus.critical;
    } else if (latest.cpuUsage > 80 || latest.memoryUsage > 85) {
      return SystemHealthStatus.warning;
    } else {
      return SystemHealthStatus.healthy;
    }
  }

  // Placeholder methods for system metrics
  Future<double> _getCpuUsage() async => 45.0 + Random().nextDouble() * 20;
  Future<double> _getMemoryUsage() async => 60.0 + Random().nextDouble() * 15;
  Future<double> _getDiskUsage() async => 70.0 + Random().nextDouble() * 10;
  Future<Duration> _getNetworkLatency() async =>
      Duration(milliseconds: 50 + Random().nextInt(100));
  Future<int> _getActiveConnections() async => 10 + Random().nextInt(20);
  Future<int> _getRequestsPerMinute() async => 100 + Random().nextInt(50);
  Future<int> _getErrorRate() async => Random().nextInt(3);
  Future<Duration> _getAverageResponseTime() async =>
      Duration(milliseconds: 200 + Random().nextInt(300));
  Future<double> _getThroughput() async => 1000.0 + Random().nextDouble() * 500;

  String _generateLogId() => 'log_${DateTime.now().millisecondsSinceEpoch}';
  String _generateAlertId() => 'alert_${DateTime.now().millisecondsSinceEpoch}';

  /// Dispose resources
  void dispose() {
    _metricsTimer?.cancel();
    _metricsController.close();
    _alertsController.close();
  }
}

/// System metrics data
class SystemMetrics {
  final DateTime timestamp;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final Duration networkLatency;
  final int activeConnections;
  final int requestsPerMinute;
  final int errorRate;
  final Duration responseTime;
  final double throughput;

  SystemMetrics({
    required this.timestamp,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkLatency,
    required this.activeConnections,
    required this.requestsPerMinute,
    required this.errorRate,
    required this.responseTime,
    required this.throughput,
  });
}

/// Monitoring alert
class MonitoringAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isResolved;

  MonitoringAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.isResolved,
  });
}

/// Log entry
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String category;
  final Map<String, dynamic> metadata;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    required this.category,
    required this.metadata,
  });
}

/// Monitoring dashboard data
class MonitoringDashboard {
  final SystemMetrics? currentMetrics;
  final List<MonitoringAlert> activeAlerts;
  final SystemHealthStatus systemHealth;
  final Duration uptime;
  final int totalRequests;
  final int errorCount;
  final Duration averageResponseTime;
  final double throughput;

  MonitoringDashboard({
    required this.currentMetrics,
    required this.activeAlerts,
    required this.systemHealth,
    required this.uptime,
    required this.totalRequests,
    required this.errorCount,
    required this.averageResponseTime,
    required this.throughput,
  });
}

/// Alert severity levels
enum AlertSeverity { low, medium, warning, high, critical }

/// Log levels
enum LogLevel { debug, info, warning, error, critical }

/// System health status
enum SystemHealthStatus { healthy, warning, critical, unknown }

