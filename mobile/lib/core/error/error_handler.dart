import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app_error.dart';

@singleton
class ErrorHandler {
  final Logger _logger;

  ErrorHandler(this._logger);

  /// Handle and convert exceptions to AppError
  AppError handleError(dynamic error, [StackTrace? stackTrace]) {
    _logger.e('Error occurred: $error', error: error, stackTrace: stackTrace);

    // Report to Sentry in production
    if (kReleaseMode) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }

    if (error is AppError) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    // Default error
    return ServerError(
      message: error.toString(),
      code: 'UNKNOWN_ERROR',
    );
  }

  /// Handle Dio network errors
  AppError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkError(
          message: 'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT_ERROR',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _getErrorMessageFromResponse(error.response);

        if (statusCode == 401) {
          return AuthError(
            message: message ?? 'Authentication failed',
            code: 'UNAUTHORIZED',
          );
        } else if (statusCode == 403) {
          return AuthError(
            message: message ?? 'Access forbidden',
            code: 'FORBIDDEN',
          );
        } else if (statusCode == 404) {
          return ServerError(
            message: message ?? 'Resource not found',
            code: 'NOT_FOUND',
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerError(
            message: message ?? 'Server error occurred',
            code: 'SERVER_ERROR',
          );
        }

        return ServerError(
          message: message ?? 'Request failed',
          code: 'REQUEST_FAILED',
        );

      case DioExceptionType.cancel:
        return const NetworkError(
          message: 'Request was cancelled',
          code: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.connectionError:
        return const NetworkError(
          message: 'No internet connection',
          code: 'NO_CONNECTION',
        );

      default:
        return NetworkError(
          message: error.message ?? 'Network error occurred',
          code: 'NETWORK_ERROR',
        );
    }
  }

  /// Extract error message from response
  String? _getErrorMessageFromResponse(Response<dynamic>? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] ?? data['error'] ?? data['detail'])?.toString();
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Get user-friendly error message
  String getUserFriendlyMessage(AppError error) {
    switch (error.runtimeType) {
      case NetworkError:
        return _getNetworkErrorMessage(error as NetworkError);
      case AuthError:
        return _getAuthErrorMessage(error as AuthError);
      case ValidationError:
        return error.message;
      case ServerError:
        return _getServerErrorMessage(error as ServerError);
      case VoiceError:
        return _getVoiceErrorMessage(error as VoiceError);
      case AIError:
        return _getAIErrorMessage(error as AIError);
      case LocationError:
        return _getLocationErrorMessage(error as LocationError);
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  String _getNetworkErrorMessage(NetworkError error) {
    switch (error.code) {
      case 'TIMEOUT_ERROR':
        return 'Connection timeout. Please check your internet connection and try again.';
      case 'NO_CONNECTION':
        return 'No internet connection. Please check your network settings.';
      case 'REQUEST_CANCELLED':
        return 'Request was cancelled.';
      default:
        return 'Network error occurred. Please try again.';
    }
  }

  String _getAuthErrorMessage(AuthError error) {
    switch (error.code) {
      case 'UNAUTHORIZED':
        return 'Please log in to continue.';
      case 'FORBIDDEN':
        return 'You don\'t have permission to access this resource.';
      default:
        return 'Authentication error. Please log in again.';
    }
  }

  String _getServerErrorMessage(ServerError error) {
    switch (error.code) {
      case 'NOT_FOUND':
        return 'The requested resource was not found.';
      case 'SERVER_ERROR':
        return 'Server error occurred. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _getVoiceErrorMessage(VoiceError error) {
    return 'Voice service error: ${error.message}';
  }

  String _getAIErrorMessage(AIError error) {
    return 'AI service error: ${error.message}';
  }

  String _getLocationErrorMessage(LocationError error) {
    return 'Location service error: ${error.message}';
  }
}

