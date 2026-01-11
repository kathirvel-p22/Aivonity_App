import 'package:flutter/foundation.dart';
import 'error_handler_service.dart';

/// Enhanced Error Handler
/// Advanced error handling with categorization and user-friendly messages
class EnhancedErrorHandler {
  static EnhancedErrorHandler? _instance;
  static EnhancedErrorHandler get instance =>
      _instance ??= EnhancedErrorHandler._();

  EnhancedErrorHandler._();

  final ErrorHandlerService _errorHandler = ErrorHandlerService.instance;
  final List<AppError> _recentErrors = [];

  /// Initialize enhanced error handler
  static void initialize() {
    ErrorHandlerService.initialize();
    debugPrint('Enhanced error handler initialized');
  }

  /// Handle application error with enhanced categorization
  Future<AppError> handleAppError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
    ErrorCategory category = ErrorCategory.general,
  }) async {
    final appError = AppError(
      originalError: error,
      category: category,
      context: context,
      stackTrace: stackTrace,
      additionalData: additionalData,
      timestamp: DateTime.now(),
    );

    // Add to recent errors
    _recentErrors.insert(0, appError);
    if (_recentErrors.length > 50) {
      _recentErrors.removeRange(50, _recentErrors.length);
    }

    // Determine severity based on category
    final severity = _getSeverityFromCategory(category);

    // Handle with base error handler
    await _errorHandler.handleError(
      error,
      stackTrace: stackTrace,
      context: context,
      additionalData: {
        'category': category.name,
        'userMessage': appError.userMessage,
        ...?additionalData,
      },
      severity: severity,
    );

    return appError;
  }

  /// Handle network error with specific categorization
  Future<AppError> handleNetworkError(
    dynamic error, {
    String? endpoint,
    int? statusCode,
    Map<String, dynamic>? requestData,
  }) async {
    return handleAppError(
      error,
      context: 'Network Request',
      additionalData: {
        'endpoint': endpoint,
        'statusCode': statusCode,
        'requestData': requestData,
      },
      category: ErrorCategory.network,
    );
  }

  /// Handle authentication error
  Future<AppError> handleAuthError(
    dynamic error, {
    String? action,
    Map<String, dynamic>? userData,
  }) async {
    return handleAppError(
      error,
      context: 'Authentication',
      additionalData: {'action': action, 'userData': userData},
      category: ErrorCategory.authentication,
    );
  }

  /// Handle validation error
  Future<AppError> handleValidationError(
    String field,
    String message, {
    dynamic value,
    Map<String, dynamic>? formData,
  }) async {
    return handleAppError(
      ValidationError(field, message),
      context: 'Form Validation',
      additionalData: {
        'field': field,
        'value': value?.toString(),
        'formData': formData,
      },
      category: ErrorCategory.validation,
    );
  }

  /// Handle business logic error
  Future<AppError> handleBusinessError(
    String message, {
    String? operation,
    Map<String, dynamic>? businessData,
  }) async {
    return handleAppError(
      BusinessError(message),
      context: 'Business Logic',
      additionalData: {'operation': operation, 'businessData': businessData},
      category: ErrorCategory.business,
    );
  }

  /// Get recent errors
  List<AppError> getRecentErrors({ErrorCategory? category, Duration? since}) {
    final errors = _recentErrors
        .asMap()
        .entries
        .where((entry) {
          final error = entry.value;

          if (category != null && error.category != category) {
            return false;
          }

          if (since != null &&
              error.timestamp.isBefore(DateTime.now().subtract(since))) {
            return false;
          }

          return true;
        })
        .map((entry) => entry.value);

    return errors.toList();
  }

  /// Clear recent errors
  void clearRecentErrors() {
    _recentErrors.clear();
  }

  /// Get error statistics by category
  Map<String, dynamic> getErrorStatistics() {
    final categoryCount = <String, int>{};
    for (final error in _recentErrors) {
      final category = error.category.name;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    return {
      'totalErrors': _recentErrors.length,
      'categoryBreakdown': categoryCount,
      'recentErrors': _recentErrors
          .take(5)
          .map(
            (error) => {
              'category': error.category.name,
              'message': error.userMessage,
              'timestamp': error.timestamp.toIso8601String(),
            },
          )
          .toList(),
    };
  }

  ErrorSeverity _getSeverityFromCategory(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.critical:
        return ErrorSeverity.critical;
      case ErrorCategory.authentication:
      case ErrorCategory.security:
        return ErrorSeverity.high;
      case ErrorCategory.network:
      case ErrorCategory.business:
        return ErrorSeverity.medium;
      case ErrorCategory.validation:
      case ErrorCategory.ui:
        return ErrorSeverity.low;
      case ErrorCategory.general:
        return ErrorSeverity.medium;
    }
  }
}

/// Enhanced App Error Model
class AppError {
  final dynamic originalError;
  final ErrorCategory category;
  final String? context;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;

  const AppError({
    required this.originalError,
    required this.category,
    this.context,
    this.stackTrace,
    this.additionalData,
    required this.timestamp,
  });

  /// Get user-friendly error message
  String get userMessage {
    switch (category) {
      case ErrorCategory.network:
        return 'Network connection error. Please check your internet connection and try again.';
      case ErrorCategory.authentication:
        return 'Authentication failed. Please log in again.';
      case ErrorCategory.validation:
        if (originalError is ValidationError) {
          return (originalError as ValidationError).message;
        }
        return 'Please check your input and try again.';
      case ErrorCategory.business:
        if (originalError is BusinessError) {
          return (originalError as BusinessError).message;
        }
        return 'Unable to complete the operation. Please try again.';
      case ErrorCategory.security:
        return 'Security error. Please contact support if this continues.';
      case ErrorCategory.critical:
        return 'A critical error occurred. Please restart the app and contact support if the issue persists.';
      case ErrorCategory.ui:
        return 'Display error. Please refresh the screen.';
      case ErrorCategory.general:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get technical error message
  String get technicalMessage {
    return originalError.toString();
  }

  @override
  String toString() {
    return 'AppError(category: ${category.name}, message: $userMessage, timestamp: $timestamp)';
  }
}

/// Error Category Enum
enum ErrorCategory {
  general,
  network,
  authentication,
  validation,
  business,
  security,
  critical,
  ui,
}

/// Business Error Class
class BusinessError implements Exception {
  final String message;

  const BusinessError(this.message);

  @override
  String toString() => 'BusinessError: $message';
}

