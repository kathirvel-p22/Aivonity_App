import 'package:equatable/equatable.dart';

/// Base class for all application errors
abstract class AppError extends Equatable implements Exception {
  const AppError({
    required this.message,
    this.code,
    this.details,
  });

  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'AppError(message: $message, code: $code)';
}

/// Network related errors
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.details,
  });
}

/// Authentication related errors
class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.code,
    super.details,
  });
}

/// Validation related errors
class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code,
    super.details,
  });
}

/// Server related errors
class ServerError extends AppError {
  const ServerError({
    required super.message,
    super.code,
    super.details,
  });
}

/// Cache related errors
class CacheError extends AppError {
  const CacheError({
    required super.message,
    super.code,
    super.details,
  });
}

/// Voice service related errors
class VoiceError extends AppError {
  const VoiceError({
    required super.message,
    super.code,
    super.details,
  });
}

/// AI service related errors
class AIError extends AppError {
  const AIError({
    required super.message,
    super.code,
    super.details,
  });
}

/// Location service related errors
class LocationError extends AppError {
  const LocationError({
    required super.message,
    super.code,
    super.details,
  });
}

