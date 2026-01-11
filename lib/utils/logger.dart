import 'dart:developer' as developer;
import 'package:logger/logger.dart';

import '../config/app_config.dart';

/// AIVONITY Advanced Logging System
/// Provides structured logging with different levels and outputs
class AppLogger {
  static late Logger _logger;
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;

    _logger = Logger(
      filter: AppConfig.isDebugMode ? DevelopmentFilter() : ProductionFilter(),
      printer: _CustomPrinter(),
      output: _CustomOutput(),
    );

    _initialized = true;
    info('📝 Logger initialized');
  }

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // Performance logging
  static void performance(
    String operation,
    Duration duration, [
    Map<String, dynamic>? metadata,
  ]) {
    if (!_initialized) initialize();

    final message =
        '⚡ Performance: $operation took ${duration.inMilliseconds}ms';
    final logData = {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?metadata,
    };

    _logger.i(message, error: logData);
  }

  // Network logging
  static void network(
    String method,
    String url,
    int statusCode,
    Duration duration,
  ) {
    if (!_initialized) initialize();

    final message =
        '🌐 $method $url - $statusCode (${duration.inMilliseconds}ms)';
    final logData = {
      'method': method,
      'url': url,
      'status_code': statusCode,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (statusCode >= 200 && statusCode < 300) {
      _logger.i(message, error: logData);
    } else if (statusCode >= 400) {
      _logger.e(message, error: logData);
    } else {
      _logger.w(message, error: logData);
    }
  }

  // User action logging
  static void userAction(String action, [Map<String, dynamic>? context]) {
    if (!_initialized) initialize();

    final message = '👤 User Action: $action';
    final logData = {
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
      ...?context,
    };

    _logger.i(message, error: logData);
  }

  // Security logging
  static void security(
    String event,
    String severity, [
    Map<String, dynamic>? details,
  ]) {
    if (!_initialized) initialize();

    final message = '🔒 Security Event: $event ($severity)';
    final logData = {
      'event': event,
      'severity': severity,
      'timestamp': DateTime.now().toIso8601String(),
      ...?details,
    };

    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        _logger.e(message, error: logData);
        break;
      case 'medium':
        _logger.w(message, error: logData);
        break;
      default:
        _logger.i(message, error: logData);
    }
  }

  // Analytics logging
  static void analytics(String event, [Map<String, dynamic>? properties]) {
    if (!_initialized) initialize();

    final message = '📊 Analytics: $event';
    final logData = {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      ...?properties,
    };

    _logger.i(message, error: logData);
  }
}

/// Custom printer for enhanced log formatting
class _CustomPrinter extends LogPrinter {
  static final Map<Level, String> _levelEmojis = {
    Level.trace: '🔍',
    Level.debug: '🐛',
    Level.info: 'ℹ️',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.fatal: '💀',
  };

  static final Map<Level, String> _levelNames = {
    Level.trace: 'TRACE',
    Level.debug: 'DEBUG',
    Level.info: 'INFO',
    Level.warning: 'WARN',
    Level.error: 'ERROR',
    Level.fatal: 'FATAL',
  };

  @override
  List<String> log(LogEvent event) {
    final emoji = _levelEmojis[event.level] ?? '';
    final levelName = _levelNames[event.level] ?? 'UNKNOWN';
    final timestamp = DateTime.now().toIso8601String();

    final lines = <String>[];

    // Main log line
    lines.add('$emoji [$levelName] $timestamp - ${event.message}');

    // Error details
    if (event.error != null) {
      if (event.error is Map) {
        // Structured data
        final data = event.error as Map;
        for (final entry in data.entries) {
          lines.add('  ${entry.key}: ${entry.value}');
        }
      } else {
        // Regular error
        lines.add('  Error: ${event.error}');
      }
    }

    // Stack trace
    if (event.stackTrace != null) {
      lines.add('  Stack Trace:');
      final stackLines = event.stackTrace.toString().split('\n');
      for (final line in stackLines.take(10)) {
        // Limit stack trace lines
        if (line.trim().isNotEmpty) {
          lines.add('    $line');
        }
      }
    }

    return lines;
  }
}

/// Custom output for handling different log destinations
class _CustomOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // Output to console/debug console
    for (final line in event.lines) {
      if (AppConfig.isDebugMode) {
        developer.log(line, name: 'AIVONITY');
      }
    }

    // In production, you might want to send logs to a remote service
    if (!AppConfig.isDebugMode) {
      _sendToRemoteLogging(event);
    }
  }

  void _sendToRemoteLogging(OutputEvent event) {
    // Implementation for remote logging service
    // This could be Firebase Crashlytics, Sentry, or custom logging service

    // For now, we'll just store critical logs locally
    if (event.level.index >= Level.error.index) {
      // Store error logs for later upload
      _storeErrorLog(event);
    }
  }

  void _storeErrorLog(OutputEvent event) {
    // Store error logs locally for later upload when network is available
    // This could use the storage service to persist error logs
  }
}

/// Performance measurement utility
class PerformanceTimer {
  final String operation;
  final Stopwatch _stopwatch;
  final Map<String, dynamic>? metadata;

  PerformanceTimer(this.operation, [this.metadata])
    : _stopwatch = Stopwatch()..start();

  void stop() {
    _stopwatch.stop();
    AppLogger.performance(operation, _stopwatch.elapsed, metadata);
  }

  Duration get elapsed => _stopwatch.elapsed;
}

/// Extension for easy performance measurement
extension PerformanceLogging<T> on Future<T> Function() {
  Future<T> measurePerformance(
    String operation, [
    Map<String, dynamic>? metadata,
  ]) async {
    final timer = PerformanceTimer(operation, metadata);
    try {
      final result = await this();
      timer.stop();
      return result;
    } catch (e) {
      timer.stop();
      AppLogger.error('Performance measurement failed for $operation', e);
      rethrow;
    }
  }
}

/// Logging mixin for easy integration
mixin LoggingMixin {
  void logDebug(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.debug('$runtimeType: $message', error, stackTrace);
  }

  void logInfo(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.info('$runtimeType: $message', error, stackTrace);
  }

  void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.warning('$runtimeType: $message', error, stackTrace);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.error('$runtimeType: $message', error, stackTrace);
  }

  void logUserAction(String action, [Map<String, dynamic>? context]) {
    final actionContext = {'class': runtimeType.toString(), ...?context};
    AppLogger.userAction(action, actionContext);
  }

  PerformanceTimer startPerformanceTimer(
    String operation, [
    Map<String, dynamic>? metadata,
  ]) {
    final timerMetadata = {'class': runtimeType.toString(), ...?metadata};
    return PerformanceTimer('$runtimeType: $operation', timerMetadata);
  }
}
