import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';

/// Service for monitoring and optimizing app performance
class PerformanceOptimizationService {
  static const String _performanceMetricsKey = 'performance_metrics';
  static const String _memoryUsageKey = 'memory_usage_history';

  SharedPreferences? _prefs;
  Timer? _monitoringTimer;

  final StreamController<PerformanceMetrics> _metricsController =
      StreamController<PerformanceMetrics>.broadcast();
  final List<MemoryUsageSnapshot> _memoryHistory = [];

  // Performance thresholds
  static const int _maxMemoryUsageMB = 200;
  static const int _maxFrameDrops = 5;
  static const Duration _maxResponseTime = Duration(milliseconds: 500);

  /// Stream for performance metrics
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;

  /// Initialize the performance optimization service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPerformanceHistory();
    _startPerformanceMonitoring();

    AppLogger.info('📊 Performance optimization service initialized');
  }

  /// Start continuous performance monitoring
  void _startPerformanceMonitoring() {
    _monitoringTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      await _collectPerformanceMetrics();
    });
  }

  /// Collect current performance metrics
  Future<void> _collectPerformanceMetrics() async {
    try {
      final memoryUsage = await _getMemoryUsage();
      final frameMetrics = await _getFrameMetrics();
      final networkMetrics = await _getNetworkMetrics();

      final metrics = PerformanceMetrics(
        timestamp: DateTime.now(),
        memoryUsageMB: memoryUsage,
        frameDropCount: frameMetrics.droppedFrames,
        averageFrameTime: frameMetrics.averageFrameTime,
        networkLatency: networkMetrics.latency,
        networkThroughput: networkMetrics.throughput,
        cpuUsage: await _getCpuUsage(),
        batteryLevel: await _getBatteryLevel(),
      );

      // Store memory usage history
      _memoryHistory.add(
        MemoryUsageSnapshot(
          timestamp: DateTime.now(),
          memoryUsageMB: memoryUsage,
        ),
      );

      // Keep only last 100 snapshots
      if (_memoryHistory.length > 100) {
        _memoryHistory.removeAt(0);
      }

      // Emit metrics
      _metricsController.add(metrics);

      // Check for performance issues
      await _checkPerformanceThresholds(metrics);

      // Save metrics
      await _savePerformanceMetrics(metrics);
    } catch (e) {
      AppLogger.error('❌ Error collecting performance metrics', e);
    }
  }

  /// Get current memory usage in MB
  Future<double> _getMemoryUsage() async {
    if (kIsWeb) return 0.0;

    try {
      // This is a simplified implementation
      // In a real app, you'd use platform-specific memory APIs
      return 50.0; // Placeholder value
    } catch (e) {
      return 0.0;
    }
  }

  /// Get frame rendering metrics
  Future<FrameMetrics> _getFrameMetrics() async {
    // This would integrate with Flutter's frame metrics
    return FrameMetrics(
      droppedFrames: 0,
      averageFrameTime: Duration(milliseconds: 16),
    );
  }

  /// Get network performance metrics
  Future<NetworkMetrics> _getNetworkMetrics() async {
    return NetworkMetrics(
      latency: Duration(milliseconds: 50),
      throughput: 1000.0, // KB/s
    );
  }

  /// Get CPU usage percentage
  Future<double> _getCpuUsage() async {
    if (kIsWeb) return 0.0;
    return 25.0; // Placeholder
  }

  /// Get battery level percentage
  Future<double> _getBatteryLevel() async {
    if (kIsWeb) return 100.0;

    try {
      return 80.0; // Placeholder
    } catch (e) {
      return 100.0;
    }
  }

  /// Optimize memory usage by clearing caches
  Future<void> optimizeMemoryUsage() async {
    try {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      print('🧹 Memory optimization completed');
    } catch (e) {
      print('❌ Error optimizing memory: $e');
    }
  }

  /// Check if performance metrics exceed thresholds
  Future<void> _checkPerformanceThresholds(PerformanceMetrics metrics) async {
    // Check memory usage
    if (metrics.memoryUsageMB > _maxMemoryUsageMB) {
      print(
        '⚠️ High memory usage: ${metrics.memoryUsageMB.toStringAsFixed(1)}MB',
      );
    }

    // Check frame drops
    if (metrics.frameDropCount > _maxFrameDrops) {
      print('⚠️ Frame drops detected: ${metrics.frameDropCount}');
    }

    // Check network latency
    if (metrics.networkLatency > _maxResponseTime) {
      print(
        '⚠️ High network latency: ${metrics.networkLatency.inMilliseconds}ms',
      );
    }
  }

  /// Save performance metrics to storage
  Future<void> _savePerformanceMetrics(PerformanceMetrics metrics) async {
    try {
      final metricsJson = metrics.toJson();
      await _prefs?.setString(
        '${_performanceMetricsKey}_${DateTime.now().millisecondsSinceEpoch}',
        metricsJson,
      );
    } catch (e) {
      print('❌ Error saving performance metrics: $e');
    }
  }

  /// Load performance history from storage
  Future<void> _loadPerformanceHistory() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      final memoryKeys = keys
          .where((key) => key.startsWith(_memoryUsageKey))
          .toList();

      for (final key in memoryKeys) {
        final data = _prefs?.getString(key);
        if (data != null) {
          // Parse and load memory usage data
        }
      }
    } catch (e) {
      print('❌ Error loading performance history: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _metricsController.close();
  }
}

/// Performance metrics data
class PerformanceMetrics {
  final DateTime timestamp;
  final double memoryUsageMB;
  final int frameDropCount;
  final Duration averageFrameTime;
  final Duration networkLatency;
  final double networkThroughput;
  final double cpuUsage;
  final double batteryLevel;

  PerformanceMetrics({
    required this.timestamp,
    required this.memoryUsageMB,
    required this.frameDropCount,
    required this.averageFrameTime,
    required this.networkLatency,
    required this.networkThroughput,
    required this.cpuUsage,
    required this.batteryLevel,
  });

  String toJson() {
    return '''
    {
      "timestamp": "${timestamp.toIso8601String()}",
      "memoryUsageMB": $memoryUsageMB,
      "frameDropCount": $frameDropCount,
      "averageFrameTimeMs": ${averageFrameTime.inMilliseconds},
      "networkLatencyMs": ${networkLatency.inMilliseconds},
      "networkThroughput": $networkThroughput,
      "cpuUsage": $cpuUsage,
      "batteryLevel": $batteryLevel
    }
    ''';
  }
}

/// Frame rendering metrics
class FrameMetrics {
  final int droppedFrames;
  final Duration averageFrameTime;

  FrameMetrics({required this.droppedFrames, required this.averageFrameTime});
}

/// Network performance metrics
class NetworkMetrics {
  final Duration latency;
  final double throughput;

  NetworkMetrics({required this.latency, required this.throughput});
}

/// Memory usage snapshot
class MemoryUsageSnapshot {
  final DateTime timestamp;
  final double memoryUsageMB;

  MemoryUsageSnapshot({required this.timestamp, required this.memoryUsageMB});
}
