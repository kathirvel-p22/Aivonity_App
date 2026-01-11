import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../utils/logger.dart';

/// Biometric Authentication Service
/// Handles fingerprint and face recognition authentication
class BiometricAuthService with LoggingMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      logInfo(
          'Biometric availability: $isAvailable, Device supported: $isDeviceSupported',);
      return isAvailable && isDeviceSupported;
    } catch (e, stackTrace) {
      logError('Error checking biometric availability', e, stackTrace);
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      logInfo('Available biometrics: $availableBiometrics');
      return availableBiometrics;
    } catch (e, stackTrace) {
      logError('Error getting available biometrics', e, stackTrace);
      return [];
    }
  }

  /// Check if fingerprint is available
  Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  /// Check if face recognition is available
  Future<bool> isFaceRecognitionAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Authenticate with biometrics
  Future<BiometricAuthResult> authenticate({
    String reason = 'Please authenticate to access your account',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if biometric authentication is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult.failure(
          error: 'Biometric authentication is not available on this device',
          errorType: BiometricAuthErrorType.notAvailable,
        );
      }

      logInfo('Starting biometric authentication');

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow fallback to PIN/password
        ),
      );

      if (authenticated) {
        logInfo('Biometric authentication successful');
        return BiometricAuthResult.success();
      } else {
        logInfo('Biometric authentication cancelled by user');
        return BiometricAuthResult.failure(
          error: 'Authentication was cancelled',
          errorType: BiometricAuthErrorType.userCancel,
        );
      }
    } on PlatformException catch (e, stackTrace) {
      logError('Biometric authentication platform error', e, stackTrace);

      final errorType = _mapPlatformExceptionToErrorType(e);
      return BiometricAuthResult.failure(
        error: _getErrorMessage(e),
        errorType: errorType,
      );
    } catch (e, stackTrace) {
      logError('Biometric authentication error', e, stackTrace);
      return BiometricAuthResult.failure(
        error: 'Biometric authentication failed: ${e.toString()}',
        errorType: BiometricAuthErrorType.unknown,
      );
    }
  }

  /// Authenticate with fingerprint specifically
  Future<BiometricAuthResult> authenticateWithFingerprint() async {
    final isAvailable = await isFingerprintAvailable();
    if (!isAvailable) {
      return BiometricAuthResult.failure(
        error: 'Fingerprint authentication is not available',
        errorType: BiometricAuthErrorType.notAvailable,
      );
    }

    return authenticate(
      reason: 'Please scan your fingerprint to authenticate',
    );
  }

  /// Authenticate with face recognition specifically
  Future<BiometricAuthResult> authenticateWithFace() async {
    final isAvailable = await isFaceRecognitionAvailable();
    if (!isAvailable) {
      return BiometricAuthResult.failure(
        error: 'Face recognition is not available',
        errorType: BiometricAuthErrorType.notAvailable,
      );
    }

    return authenticate(
      reason: 'Please look at the camera to authenticate',
    );
  }

  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      logInfo('Biometric authentication stopped');
    } catch (e, stackTrace) {
      logError('Error stopping biometric authentication', e, stackTrace);
    }
  }

  /// Get user-friendly error message from PlatformException
  String _getErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return 'Biometric authentication is not available on this device';
      case 'NotEnrolled':
        return 'No biometric credentials are enrolled. Please set up biometric authentication in Settings';
      case 'PasscodeNotSet':
        return 'Device passcode is not set. Please set up a passcode in Settings';
      case 'BiometricOnlyNotSupported':
        return 'Biometric-only authentication is not supported';
      case 'DeviceNotSupported':
        return 'This device does not support biometric authentication';
      case 'LockedOut':
        return 'Biometric authentication is temporarily locked. Please try again later';
      case 'PermanentlyLockedOut':
        return 'Biometric authentication is permanently locked. Please use your passcode';
      case 'UserCancel':
        return 'Authentication was cancelled';
      case 'UserFallback':
        return 'User chose to use fallback authentication';
      case 'SystemCancel':
        return 'Authentication was cancelled by the system';
      case 'InvalidContext':
        return 'Authentication context is invalid';
      case 'NotInteractive':
        return 'Authentication requires user interaction';
      default:
        return e.message ?? 'Biometric authentication failed';
    }
  }

  /// Map PlatformException to BiometricAuthErrorType
  BiometricAuthErrorType _mapPlatformExceptionToErrorType(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
      case 'DeviceNotSupported':
      case 'BiometricOnlyNotSupported':
        return BiometricAuthErrorType.notAvailable;
      case 'NotEnrolled':
        return BiometricAuthErrorType.notEnrolled;
      case 'PasscodeNotSet':
        return BiometricAuthErrorType.passcodeNotSet;
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return BiometricAuthErrorType.lockedOut;
      case 'UserCancel':
        return BiometricAuthErrorType.userCancel;
      case 'UserFallback':
        return BiometricAuthErrorType.userFallback;
      case 'SystemCancel':
        return BiometricAuthErrorType.systemCancel;
      default:
        return BiometricAuthErrorType.unknown;
    }
  }
}

/// Biometric authentication result
class BiometricAuthResult {
  final bool success;
  final String? error;
  final BiometricAuthErrorType? errorType;

  const BiometricAuthResult._({
    required this.success,
    this.error,
    this.errorType,
  });

  factory BiometricAuthResult.success() {
    return const BiometricAuthResult._(success: true);
  }

  factory BiometricAuthResult.failure({
    required String error,
    required BiometricAuthErrorType errorType,
  }) {
    return BiometricAuthResult._(
      success: false,
      error: error,
      errorType: errorType,
    );
  }
}

/// Biometric authentication error types
enum BiometricAuthErrorType {
  notAvailable,
  notEnrolled,
  passcodeNotSet,
  lockedOut,
  userCancel,
  userFallback,
  systemCancel,
  unknown,
}

