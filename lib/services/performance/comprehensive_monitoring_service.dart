import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive monitoring and observability service
class ComprehensiveMonitoringService {
  static const String _metricsPrefix = 'monitoring_metrics_';
  static const String _alertsPrefix = 'monitoring_alerts_';
  static const String _logsPrefix = 'monitoring_logs_';

  SharedPreferences? _prefs;
  Timer? _metricsTimer;
  Timer? _alertsTimer;

  final StreamController<SystemMetrics> _metricsController =
      StreamController<SystemMetrics>.broadcast();
  final StreamController<MonitoringAlert> _alertsController =
      StreamController<MonitoringAlert>.broadcast();
  final StreamController<LogEntry> _logsController =
      StreamController<LogEntry>.broadcast();

  final List<SystemMetrics> _metricsHistory = [];
  final List<MonitoringAlert> _activeAlerts = [];
  final List<LogEntry> _recentLogs = [];
  final Map<String, AlertRule> _alertRules = {};

  // Monitoring thresholds
  static const double _cpuThreshold = 80.0;
  static const double _memoryThreshold = 85.0;
  static const double _diskThreshold = 90.0;
  static const int _errorRateThreshold = 5; // errors per minute

  /// Streams for monitoring data
  Stream<SystemMetrics> get metricsStream => _metricsController.stream;
  Stream<MonitoringAlert> get alertsStream => _alertsController.stream;
  Stream<LogEntry> get logsStream => _logsController.stream;

  /// Initialize the comprehensive monitoring service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAlertRules();
    _setupDefaultAlertRules();
    _startMetricsCollection();
    _startAlertMonitoring();

    debugPrint('📊 Comprehensive monitoring service initialized');
  }

  /// Dispose resources
  void dispose() {
    _metricsTimer?.cancel();
    _alertsTimer?.cancel();
    _metricsController.close();
    _alertsController.close();
    _logsController.close();
  }

  /// Start collecting system metrics
  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await collectMetrics();
    });
  }

  /// Start monitoring for alert conditions
  void _startAlertMonitoring() {
    _alertsTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _checkAlertConditions();
    });
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

      // Save to persistent storage
      await _saveMetrics(metrics);
    } catch (e) {
      debugPrint('❌ Error collecting metrics: $e');
    }
  }

  /// Log an event with structured data
  void logEvent({
    required String message,
    required LogLevel level,
    String? category,
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
  }) {
    final logEntry = LogEntry(
      id: _generateLogId(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      category: category ?? 'general',
      metadata: metadata ?? {},
      userId: userId,
      sessionId: sessionId,
    );

    _recentLogs.add(logEntry);

    // Keep only last 10000 logs
    if (_recentLogs.length > 10000) {
      _recentLogs.removeAt(0);
    }

    // Emit log entry
    _logsController.add(logEntry);

    // Save to persistent storage
    _saveLogEntry(logEntry);

    // Check for alert conditions
    _checkLogAlerts(logEntry);
  }

  /// Create a custom alert rule
  void createAlertRule(AlertRule rule) {
    _alertRules[rule.id] = rule;
    _saveAlertRule(rule);
    debugPrint('🚨 Created alert rule: ${rule.name}');
  }

  /// Get real-time dashboard data
  Future<MonitoringDashboard> getDashboard() async {
    final currentMetrics = _metricsHistory.isNotEmpty
        ? _metricsHistory.last
        : null;
    final recentAlerts = _activeAlerts
        .where(
          (alert) =>
              DateTime.now().difference(alert.timestamp) <=
              const Duration(hours: 24),
        )
        .toList();

    return MonitoringDashboard(
      currentMetrics: currentMetrics,
      activeAlerts: recentAlerts,
      systemHealth: _calculateSystemHealth(),
      uptime: await _getSystemUptime(),
      totalRequests: await _getTotalRequests(),
      errorCount: await _getErrorCount(),
      averageResponseTime: currentMetrics?.responseTime ?? Duration.zero,
      throughput: currentMetrics?.throughput ?? 0.0,
    );
  }

  /// Generate a monitoring report
  Future<MonitoringReport> generateReport({Duration? period}) async {
    final reportPeriod = period ?? const Duration(hours: 24);
    final cutoffTime = DateTime.now().subtract(reportPeriod);

    final relevantMetrics = _metricsHistory
        .where((metrics) => metrics.timestamp.isAfter(cutoffTime))
        .toList();

    final relevantLogs = _recentLogs
        .where((log) => log.timestamp.isAfter(cutoffTime))
        .toList();

    final relevantAlerts = _activeAlerts
        .where((alert) => alert.timestamp.isAfter(cutoffTime))
        .toList();

    return MonitoringReport(
      period: reportPeriod,
      generatedAt: DateTime.now(),
      metricsCount: relevantMetrics.length,
      logsCount: relevantLogs.length,
      alertsCount: relevantAlerts.length,
      averageCpuUsage: _calculateAverageCpu(relevantMetrics),
      averageMemoryUsage: _calculateAverageMemory(relevantMetrics),
      peakCpuUsage: _calculatePeakCpu(relevantMetrics),
      peakMemoryUsage: _calculatePeakMemory(relevantMetrics),
      totalErrors: _countErrorLogs(relevantLogs),
      systemAvailability: _calculateAvailability(relevantMetrics),
      recommendations: _generateRecommendations(relevantMetrics, relevantLogs),
    );
  }

  /// Get performance trends
  Future<PerformanceTrends> getTrends({Duration? trendPeriod}) async {
    final period = trendPeriod ?? const Duration(hours: 6);
    final cutoffTime = DateTime.now().subtract(period);

    final relevantMetrics = _metricsHistory
        .where((metrics) => metrics.timestamp.isAfter(cutoffTime))
        .toList();

    if (relevantMetrics.isEmpty) {
      return PerformanceTrends.empty();
    }

    return PerformanceTrends(
      cpuTrend: _calculateTrend(
        relevantMetrics.map((m) => m.cpuUsage).toList(),
      ),
      memoryTrend: _calculateTrend(
        relevantMetrics.map((m) => m.memoryUsage).toList(),
      ),
      responseTrend: _calculateTrend(
        relevantMetrics
            .map((m) => m.responseTime.inMilliseconds.toDouble())
            .toList(),
      ),
      throughputTrend: _calculateTrend(
        relevantMetrics.map((m) => m.throughput).toList(),
      ),
      errorRateTrend: _calculateTrend(
        relevantMetrics.map((m) => m.errorRate.toDouble()).toList(),
      ),
    );
  }

  /// Search logs with filters
  List<LogEntry> searchLogs({
    String? query,
    LogLevel? level,
    String? category,
    DateTime? startTime,
    DateTime? endTime,
    int limit = 100,
  }) {
    var filteredLogs = _recentLogs.where((log) {
      if (query != null &&
          !log.message.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      if (level != null && log.level != level) {
        return false;
      }
      if (category != null && log.category != category) {
        return false;
      }
      if (startTime != null && log.timestamp.isBefore(startTime)) {
        return false;
      }
      if (endTime != null && log.timestamp.isAfter(endTime)) {
        return false;
      }
      return true;
    }).toList();

    // Sort by timestamp (newest first)
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filteredLogs.take(limit).toList();
  }

  // Private helper methods

  void _setupDefaultAlertRules() {
    // High CPU usage alert
    createAlertRule(
      AlertRule(
        id: 'high_cpu',
        name: 'High CPU Usage',
        description: 'CPU usage is above 80%',
        condition: AlertCondition(
          type: AlertConditionType.cpuUsage,
          threshold: _cpuThreshold,
        ),
        severity: AlertSeverity.warning,
        enabled: true,
      ),
    );

    // High memory usage alert
    createAlertRule(
      AlertRule(
        id: 'high_memory',
        name: 'High Memory Usage',
        description: 'Memory usage is above 85%',
        condition: AlertCondition(
          type: AlertConditionType.memoryUsage,
          threshold: _memoryThreshold,
        ),
        severity: AlertSeverity.warning,
        enabled: true,
      ),
    );

    // Slow response time alert
    createAlertRule(
      AlertRule(
        id: 'slow_response',
        name: 'Slow Response Time',
        description: 'Average response time is above 2 seconds',
        condition: AlertCondition(
          type: AlertConditionType.responseTime,
          threshold: 2000,
        ),
        severity: AlertSeverity.medium,
        enabled: true,
      ),
    );
  }

  Future<void> _checkAlertConditions() async {
    if (_metricsHistory.isEmpty) return;

    final currentMetrics = _metricsHistory.last;

    for (final rule in _alertRules.values) {
      if (!rule.enabled) continue;

      final shouldAlert = _evaluateAlertRule(rule, currentMetrics);

      if (shouldAlert && !_isAlertActive(rule.id)) {
        final alert = MonitoringAlert(
          id: _generateAlertId(),
          ruleId: rule.id,
          title: rule.name,
          description: rule.description,
          severity: rule.severity,
          timestamp: DateTime.now(),
          metrics: currentMetrics,
          isResolved: false,
        );

        _activeAlerts.add(alert);
        _alertsController.add(alert);
        await _saveAlert(alert);

        debugPrint('🚨 Alert triggered: ${rule.name}');
      }
    }
  }

  bool _evaluateAlertRule(AlertRule rule, SystemMetrics metrics) {
    switch (rule.condition.type) {
      case AlertConditionType.cpuUsage:
        return metrics.cpuUsage > rule.condition.threshold;
      case AlertConditionType.memoryUsage:
        return metrics.memoryUsage > rule.condition.threshold;
      case AlertConditionType.diskUsage:
        return metrics.diskUsage > rule.condition.threshold;
      case AlertConditionType.errorRate:
        return metrics.errorRate > rule.condition.threshold;
      case AlertConditionType.responseTime:
        return metrics.responseTime.inMilliseconds > rule.condition.threshold;
    }
  }

  bool _isAlertActive(String ruleId) {
    return _activeAlerts.any(
      (alert) => alert.ruleId == ruleId && !alert.isResolved,
    );
  }

  void _checkLogAlerts(LogEntry logEntry) {
    if (logEntry.level == LogLevel.error ||
        logEntry.level == LogLevel.critical) {
      final recentErrors = _recentLogs
          .where(
            (log) =>
                (log.level == LogLevel.error ||
                    log.level == LogLevel.critical) &&
                DateTime.now().difference(log.timestamp) <
                    const Duration(minutes: 1),
          )
          .length;

      if (recentErrors >= _errorRateThreshold) {
        final alert = MonitoringAlert(
          id: _generateAlertId(),
          ruleId: 'error_rate',
          title: 'High Error Rate',
          description:
              'Error rate exceeded threshold: $recentErrors errors in the last minute',
          severity: AlertSeverity.high,
          timestamp: DateTime.now(),
          metrics: null,
          isResolved: false,
        );

        _activeAlerts.add(alert);
        _alertsController.add(alert);
      }
    }
  }

  // Calculation helpers

  double _calculateAverageCpu(List<SystemMetrics> metrics) {
    if (metrics.isEmpty) return 0.0;
    return metrics.map((m) => m.cpuUsage).reduce((a, b) => a + b) /
        metrics.length;
  }

  double _calculateAverageMemory(List<SystemMetrics> metrics) {
    if (metrics.isEmpty) return 0.0;
    return metrics.map((m) => m.memoryUsage).reduce((a, b) => a + b) /
        metrics.length;
  }

  double _calculatePeakCpu(List<SystemMetrics> metrics) {
    if (metrics.isEmpty) return 0.0;
    return metrics.map((m) => m.cpuUsage).reduce((a, b) => a > b ? a : b);
  }

  double _calculatePeakMemory(List<SystemMetrics> metrics) {
    if (metrics.isEmpty) return 0.0;
    return metrics.map((m) => m.memoryUsage).reduce((a, b) => a > b ? a : b);
  }

  int _countErrorLogs(List<LogEntry> logs) {
    return logs
        .where(
          (log) =>
              log.level == LogLevel.error || log.level == LogLevel.critical,
        )
        .length;
  }

  double _calculateAvailability(List<SystemMetrics> metrics) {
    if (metrics.isEmpty) return 100.0;
    final healthyMetrics = metrics
        .where((m) => m.cpuUsage < 95 && m.memoryUsage < 95)
        .length;
    return (healthyMetrics / metrics.length) * 100;
  }

  TrendDirection _calculateTrend(List<double> values) {
    if (values.length < 2) return TrendDirection.stable;

    final first = values.first;
    final last = values.last;
    final change = ((last - first) / first) * 100;

    if (change > 10) return TrendDirection.increasing;
    if (change < -10) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  List<String> _generateRecommendations(
    List<SystemMetrics> metrics,
    List<LogEntry> logs,
  ) {
    final recommendations = <String>[];

    if (_calculateAverageCpu(metrics) > 70) {
      recommendations.add('Consider optimizing CPU-intensive operations');
    }
    if (_calculateAverageMemory(metrics) > 80) {
      recommendations.add(
        'Review memory usage and implement caching strategies',
      );
    }

    final errorCount = _countErrorLogs(logs);
    if (errorCount > 10) {
      recommendations.add(
        'Investigate recurring errors ($errorCount errors detected)',
      );
    }

    return recommendations;
  }

  SystemHealth _calculateSystemHealth() {
    if (_metricsHistory.isEmpty) return SystemHealth.unknown;

    final latest = _metricsHistory.last;

    if (latest.cpuUsage > 90 || latest.memoryUsage > 95) {
      return SystemHealth.critical;
    } else if (latest.cpuUsage > 80 || latest.memoryUsage > 85) {
      return SystemHealth.warning;
    } else {
      return SystemHealth.healthy;
    }
  }

  // Mock data methods (would be platform-specific in real implementation)

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
  Future<Duration> _getSystemUptime() async => const Duration(hours: 24);
  Future<int> _getTotalRequests() async => 10000;
  Future<int> _getErrorCount() async => 10;

  // Persistence methods

  Future<void> _loadAlertRules() async {
    // Load from SharedPreferences in real implementation
  }

  Future<void> _saveAlertRule(AlertRule rule) async {
    // Save to SharedPreferences in real implementation
  }

  Future<void> _saveAlert(MonitoringAlert alert) async {
    // Save to SharedPreferences in real implementation
  }

  Future<void> _saveLogEntry(LogEntry logEntry) async {
    // Save to SharedPreferences in real implementation
  }

  Future<void> _saveMetrics(SystemMetrics metrics) async {
    // Save to SharedPreferences in real implementation
  }

  String _generateAlertId() =>
      'alert_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

  String _generateLogId() =>
      'log_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
}

// Supporting data classes and enums

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

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'cpuUsage': cpuUsage,
    'memoryUsage': memoryUsage,
    'diskUsage': diskUsage,
    'networkLatency': networkLatency.inMilliseconds,
    'activeConnections': activeConnections,
    'requestsPerMinute': requestsPerMinute,
    'errorRate': errorRate,
    'responseTime': responseTime.inMilliseconds,
    'throughput': throughput,
  };
}

class MonitoringAlert {
  final String id;
  final String ruleId;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;
  final SystemMetrics? metrics;
  final bool isResolved;

  MonitoringAlert({
    required this.id,
    required this.ruleId,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.metrics,
    required this.isResolved,
  });
}

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String category;
  final Map<String, dynamic> metadata;
  final String? userId;
  final String? sessionId;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    required this.category,
    required this.metadata,
    this.userId,
    this.sessionId,
  });
}

class AlertRule {
  final String id;
  final String name;
  final String description;
  final AlertCondition condition;
  final AlertSeverity severity;
  final bool enabled;

  AlertRule({
    required this.id,
    required this.name,
    required this.description,
    required this.condition,
    required this.severity,
    required this.enabled,
  });
}

class AlertCondition {
  final AlertConditionType type;
  final double threshold;

  AlertCondition({required this.type, required this.threshold});
}

class MonitoringDashboard {
  final SystemMetrics? currentMetrics;
  final List<MonitoringAlert> activeAlerts;
  final SystemHealth systemHealth;
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

class MonitoringReport {
  final Duration period;
  final DateTime generatedAt;
  final int metricsCount;
  final int logsCount;
  final int alertsCount;
  final double averageCpuUsage;
  final double averageMemoryUsage;
  final double peakCpuUsage;
  final double peakMemoryUsage;
  final int totalErrors;
  final double systemAvailability;
  final List<String> recommendations;

  MonitoringReport({
    required this.period,
    required this.generatedAt,
    required this.metricsCount,
    required this.logsCount,
    required this.alertsCount,
    required this.averageCpuUsage,
    required this.averageMemoryUsage,
    required this.peakCpuUsage,
    required this.peakMemoryUsage,
    required this.totalErrors,
    required this.systemAvailability,
    required this.recommendations,
  });
}

class PerformanceTrends {
  final TrendDirection cpuTrend;
  final TrendDirection memoryTrend;
  final TrendDirection responseTrend;
  final TrendDirection throughputTrend;
  final TrendDirection errorRateTrend;

  PerformanceTrends({
    required this.cpuTrend,
    required this.memoryTrend,
    required this.responseTrend,
    required this.throughputTrend,
    required this.errorRateTrend,
  });

  factory PerformanceTrends.empty() => PerformanceTrends(
    cpuTrend: TrendDirection.stable,
    memoryTrend: TrendDirection.stable,
    responseTrend: TrendDirection.stable,
    throughputTrend: TrendDirection.stable,
    errorRateTrend: TrendDirection.stable,
  );
}

// Enums

enum LogLevel { debug, info, warning, error, critical }

enum AlertSeverity { low, medium, high, warning, critical }

enum AlertConditionType {
  cpuUsage,
  memoryUsage,
  diskUsage,
  errorRate,
  responseTime,
}

enum SystemHealth { healthy, warning, critical, unknown }

enum TrendDirection { increasing, decreasing, stable }

