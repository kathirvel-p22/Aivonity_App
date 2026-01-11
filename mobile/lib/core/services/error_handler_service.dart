import 'package:flutter/foundation.dart';

/// AIVONITY Error Handler Service
/// Simplified error handling without external dependencies
class ErrorHandlerService {
  static ErrorHandlerService? _instance;
  static ErrorHandlerService get instance =>
      _instance ??= ErrorHandlerService._();

  ErrorHandlerService._();

  final List<ErrorLog> _errorLogs = [];
  final List<ErrorHandler> _errorHandlers = [];

  /// Initialize error handler
  static void initialize() {
    instance._setupDefaultHandlers();
    debugPrint('Error handler service initialized');
  }

  void _setupDefaultHandlers() {
    // Add default error handlers
    addErrorHandler(LoggingErrorHandler());
    addErrorHandler(UserFriendlyErrorHandler());
  }

  /// Add custom error handler
  void addErrorHandler(ErrorHandler handler) {
    _errorHandlers.add(handler);
  }

  /// Handle error
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) async {
    try {
      final errorLog = ErrorLog(
        error: error,
        stackTrace: stackTrace,
        context: context,
        additionalData: additionalData,
        severity: severity,
        timestamp: DateTime.now(),
      );

      // Add to error logs
      _errorLogs.insert(0, errorLog);

      // Keep only last 100 errors
      if (_errorLogs.length > 100) {
        _errorLogs.removeRange(100, _errorLogs.length);
      }

      // Process through all error handlers
      for (final handler in _errorHandlers) {
        try {
          await handler.handle(errorLog);
        } catch (handlerError) {
          debugPrint('Error handler failed: $handlerError');
        }
      }
    } catch (e) {
      debugPrint('Failed to handle error: $e');
    }
  }

  /// Handle network error
  Future<void> handleNetworkError(
    dynamic error, {
    String? endpoint,
    int? statusCode,
    Map<String, dynamic>? requestData,
  }) async {
    final additionalData = <String, dynamic>{
      'type': 'network_error',
      if (endpoint != null) 'endpoint': endpoint,
      if (statusCode != null) 'statusCode': statusCode,
      if (requestData != null) 'requestData': requestData,
    };

    await handleError(
      error,
      context: 'Network Request',
      additionalData: additionalData,
      severity: _getNetworkErrorSeverity(statusCode),
    );
  }

  /// Handle API error
  Future<void> handleApiError(
    String message, {
    int? statusCode,
    String? endpoint,
    Map<String, dynamic>? responseData,
  }) async {
    final additionalData = <String, dynamic>{
      'type': 'api_error',
      if (statusCode != null) 'statusCode': statusCode,
      if (endpoint != null) 'endpoint': endpoint,
      if (responseData != null) 'responseData': responseData,
    };

    await handleError(
      ApiError(message, statusCode: statusCode),
      context: 'API Call',
      additionalData: additionalData,
      severity: _getApiErrorSeverity(statusCode),
    );
  }

  /// Handle validation error
  Future<void> handleValidationError(
    String field,
    String message, {
    dynamic value,
    Map<String, dynamic>? formData,
  }) async {
    final additionalData = <String, dynamic>{
      'type': 'validation_error',
      'field': field,
      if (value != null) 'value': value.toString(),
      if (formData != null) 'formData': formData,
    };

    await handleError(
      ValidationError(field, message),
      context: 'Form Validation',
      additionalData: additionalData,
      severity: ErrorSeverity.low,
    );
  }

  /// Get error logs
  List<ErrorLog> getErrorLogs({
    ErrorSeverity? minSeverity,
    DateTime? since,
    String? context,
  }) {
    final logs = _errorLogs
        .asMap()
        .entries
        .where((entry) {
          final log = entry.value;

          if (minSeverity != null && log.severity.index < minSeverity.index) {
            return false;
          }

          if (since != null && log.timestamp.isBefore(since)) {
            return false;
          }

          if (context != null && log.context != context) {
            return false;
          }

          return true;
        })
        .map((entry) => entry.value);

    return logs.toList();
  }

  /// Clear error logs
  void clearErrorLogs() {
    _errorLogs.clear();
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    final stats = <String, dynamic>{
      'totalErrors': _errorLogs.length,
      'severityBreakdown': <String, int>{},
      'contextBreakdown': <String, int>{},
      'recentErrors': _errorLogs
          .take(5)
          .map(
            (log) => {
              'error': log.error.toString(),
              'context': log.context,
              'severity': log.severity.name,
              'timestamp': log.timestamp.toIso8601String(),
            },
          )
          .toList(),
    };

    // Count by severity
    for (final log in _errorLogs) {
      final severity = log.severity.name;
      stats['severityBreakdown'][severity] =
          (stats['severityBreakdown'][severity] ?? 0) + 1;
    }

    // Count by context
    for (final log in _errorLogs) {
      final context = log.context ?? 'Unknown';
      stats['contextBreakdown'][context] =
          (stats['contextBreakdown'][context] ?? 0) + 1;
    }

    return stats;
  }

  ErrorSeverity _getNetworkErrorSeverity(int? statusCode) {
    if (statusCode == null) return ErrorSeverity.high;

    if (statusCode >= 500) return ErrorSeverity.high;
    if (statusCode >= 400) return ErrorSeverity.medium;
    return ErrorSeverity.low;
  }

  ErrorSeverity _getApiErrorSeverity(int? statusCode) {
    if (statusCode == null) return ErrorSeverity.medium;

    if (statusCode >= 500) return ErrorSeverity.high;
    if (statusCode == 401 || statusCode == 403) return ErrorSeverity.high;
    if (statusCode >= 400) return ErrorSeverity.medium;
    return ErrorSeverity.low;
  }
}

/// Error Log Model
class ErrorLog {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final Map<String, dynamic>? additionalData;
  final ErrorSeverity severity;
  final DateTime timestamp;

  const ErrorLog({
    required this.error,
    this.stackTrace,
    this.context,
    this.additionalData,
    required this.severity,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ErrorLog(error: $error, context: $context, severity: ${severity.name}, timestamp: $timestamp)';
  }
}

/// Error Handler Interface
abstract class ErrorHandler {
  Future<void> handle(ErrorLog errorLog);
}

/// Logging Error Handler
class LoggingErrorHandler implements ErrorHandler {
  @override
  Future<void> handle(ErrorLog errorLog) async {
    final severity = errorLog.severity.name.toUpperCase();
    final context = errorLog.context ?? 'Unknown';
    final timestamp = errorLog.timestamp.toIso8601String();

    debugPrint('[$severity] [$context] [$timestamp] ${errorLog.error}');

    if (errorLog.stackTrace != null) {
      debugPrint('Stack trace: ${errorLog.stackTrace}');
    }

    if (errorLog.additionalData != null) {
      debugPrint('Additional data: ${errorLog.additionalData}');
    }
  }
}

/// User Friendly Error Handler
class UserFriendlyErrorHandler implements ErrorHandler {
  @override
  Future<void> handle(ErrorLog errorLog) async {
    // In a real app, this would show user-friendly error messages
    // For now, just log user-friendly messages
    final userMessage = _getUserFriendlyMessage(errorLog);
    debugPrint('User message: $userMessage');
  }

  String _getUserFriendlyMessage(ErrorLog errorLog) {
    if (errorLog.error is ApiError) {
      final apiError = errorLog.error as ApiError;
      if (apiError.statusCode == 401) {
        return 'Please log in again to continue.';
      } else if (apiError.statusCode == 403) {
        return 'You don\'t have permission to perform this action.';
      } else if (apiError.statusCode != null && apiError.statusCode! >= 500) {
        return 'Server error. Please try again later.';
      }
      return 'Something went wrong. Please try again.';
    }

    if (errorLog.error is ValidationError) {
      final validationError = errorLog.error as ValidationError;
      return validationError.message;
    }

    if (errorLog.additionalData?['type'] == 'network_error') {
      return 'Network connection error. Please check your internet connection.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}

/// Error Severity Enum
enum ErrorSeverity { low, medium, high, critical }

/// Custom Error Classes
class ApiError implements Exception {
  final String message;
  final int? statusCode;

  const ApiError(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiError: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class ValidationError implements Exception {
  final String field;
  final String message;

  const ValidationError(this.field, this.message);

  @override
  String toString() => 'ValidationError: $field - $message';
}

class NetworkError implements Exception {
  final String message;
  final String? endpoint;

  const NetworkError(this.message, {this.endpoint});

  @override
  String toString() =>
      'NetworkError: $message${endpoint != null ? ' (Endpoint: $endpoint)' : ''}';
}

