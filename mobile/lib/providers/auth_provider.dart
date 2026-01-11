import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/auth_service.dart';
import '../core/models/auth_models.dart';
import '../core/providers/service_providers.dart';
import '../core/utils/logger.dart';

/// Authentication state
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserData user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Authentication provider using comprehensive AuthService
class AuthNotifier extends StateNotifier<AuthState> with LoggingMixin {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthInitial());

  /// Initialize authentication service
  Future<void> initialize() async {
    await _authService.initialize();
    await checkAuthStatus();
  }

  /// Check authentication status on app start
  Future<void> checkAuthStatus() async {
    try {
      state = const AuthLoading();

      final isAuthenticated = await _authService.isAuthenticated();
      if (!isAuthenticated) {
        state = const AuthUnauthenticated();
        return;
      }

      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
        logInfo('User authenticated successfully');
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e, stackTrace) {
      logError('Failed to check auth status', e, stackTrace);
      state = const AuthUnauthenticated();
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    try {
      state = const AuthLoading();

      logUserAction('login_attempt', {'email': email});

      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result.success && result.user != null) {
        state = AuthAuthenticated(result.user!);
        logUserAction('login_success', {'user_id': result.user!.id});
      } else {
        state = AuthError(result.error ?? 'Login failed');
        logUserAction('login_failed', {
          'email': email,
          'error': result.error,
        });
      }
    } catch (e, stackTrace) {
      logError('Login error', e, stackTrace);
      state = const AuthError('Login failed. Please try again.');
    }
  }

  /// Register new user
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      state = const AuthLoading();

      logUserAction('register_attempt', {'email': email, 'name': name});

      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );

      if (result.success && result.user != null) {
        state = AuthAuthenticated(result.user!);
        logUserAction('register_success', {'user_id': result.user!.id});
      } else {
        state = AuthError(result.error ?? 'Registration failed');
        logUserAction('register_failed', {
          'email': email,
          'error': result.error,
        });
      }
    } catch (e, stackTrace) {
      logError('Registration error', e, stackTrace);
      state = const AuthError('Registration failed. Please try again.');
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      state = const AuthLoading();

      logUserAction('password_reset_request', {'email': email});

      final result = await _authService.requestPasswordReset(email);

      if (result.success) {
        state = const AuthUnauthenticated();
        logUserAction('password_reset_sent', {'email': email});
      } else {
        state =
            AuthError(result.error ?? 'Failed to send password reset email');
        logUserAction('password_reset_failed', {
          'email': email,
          'error': result.error,
        });
      }
    } catch (e, stackTrace) {
      logError('Password reset request error', e, stackTrace);
      state = const AuthError(
          'Failed to send password reset email. Please try again.',);
    }
  }

  /// Confirm password reset
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    try {
      state = const AuthLoading();

      final result = await _authService.confirmPasswordReset(
        token: token,
        newPassword: newPassword,
      );

      if (result.success) {
        state = const AuthUnauthenticated();
        logInfo('Password reset confirmed successfully');
      } else {
        state = AuthError(result.error ?? 'Failed to reset password');
      }
    } catch (e, stackTrace) {
      logError('Password reset confirmation error', e, stackTrace);
      state = const AuthError('Failed to reset password. Please try again.');
    }
  }

  /// Verify email address
  Future<void> verifyEmail(String token) async {
    try {
      state = const AuthLoading();

      final result = await _authService.verifyEmail(token);

      if (result.success && result.user != null) {
        state = AuthAuthenticated(result.user!);
        logInfo('Email verified successfully');
      } else {
        state = AuthError(result.error ?? 'Email verification failed');
      }
    } catch (e, stackTrace) {
      logError('Email verification error', e, stackTrace);
      state = const AuthError('Email verification failed. Please try again.');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _authService.logout();
      state = const AuthUnauthenticated();
      logInfo('User logged out successfully');
    } catch (e, stackTrace) {
      logError('Logout error', e, stackTrace);
      state = const AuthUnauthenticated();
    }
  }

  /// Refresh authentication token
  Future<void> refreshToken() async {
    try {
      final result = await _authService.refreshToken();

      if (result.success && result.user != null) {
        state = AuthAuthenticated(result.user!);
        logInfo('Token refreshed successfully');
      } else {
        // Token refresh failed, logout user
        await logout();
      }
    } catch (e, stackTrace) {
      logError('Token refresh error', e, stackTrace);
      await logout();
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      state = const AuthLoading();

      logUserAction('google_signin_attempt', {});

      final result = await _authService.signInWithGoogle();

      if (result.success && result.user != null) {
        state = AuthAuthenticated(result.user!);
        logUserAction('google_signin_success', {'user_id': result.user!.id});
      } else {
        state = AuthError(result.error ?? 'Google Sign-In failed');
        logUserAction('google_signin_failed', {
          'error': result.error,
        });
      }
    } catch (e, stackTrace) {
      logError('Google Sign-In error', e, stackTrace);
      state = const AuthError('Google Sign-In failed. Please try again.');
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    try {
      state = const AuthLoading();

      logUserAction('apple_signin_attempt', {});

      final result = await _authService.signInWithApple();

      if (result.success && result.user != null) {
        state = AuthAuthenticated(result.user!);
        logUserAction('apple_signin_success', {'user_id': result.user!.id});
      } else {
        state = AuthError(result.error ?? 'Apple Sign-In failed');
        logUserAction('apple_signin_failed', {
          'error': result.error,
        });
      }
    } catch (e, stackTrace) {
      logError('Apple Sign-In error', e, stackTrace);
      state = const AuthError('Apple Sign-In failed. Please try again.');
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await _authService.isBiometricAvailable();
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    return await _authService.isBiometricEnabled();
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    try {
      state = const AuthLoading();

      logUserAction('biometric_enable_attempt', {});

      final result = await _authService.enableBiometric();

      if (result.success) {
        // Keep current authenticated state
        final currentState = state;
        if (currentState is AuthAuthenticated) {
          state = AuthAuthenticated(currentState.user);
        } else {
          state = const AuthUnauthenticated();
        }
        logUserAction('biometric_enable_success', {});
      } else {
        state = AuthError(
            result.error ?? 'Failed to enable biometric authentication',);
        logUserAction('biometric_enable_failed', {
          'error': result.error,
        });
      }
    } catch (e, stackTrace) {
      logError('Enable biometric error', e, stackTrace);
      state = const AuthError(
          'Failed to enable biometric authentication. Please try again.',);
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await _authService.disableBiometric();
      logUserAction('biometric_disable_success', {});
    } catch (e, stackTrace) {
      logError('Disable biometric error', e, stackTrace);
    }
  }

  /// Authenticate with biometrics
  Future<void> authenticateWithBiometric() async {
    try {
      state = const AuthLoading();

      logUserAction('biometric_auth_attempt', {});

      final result = await _authService.authenticateWithBiometric();

      if (result.success && result.user != null) {
        state = AuthAuthenticated(result.user!);
        logUserAction('biometric_auth_success', {'user_id': result.user!.id});
      } else {
        state = AuthError(result.error ?? 'Biometric authentication failed');
        logUserAction('biometric_auth_failed', {
          'error': result.error,
        });
      }
    } catch (e, stackTrace) {
      logError('Biometric authentication error', e, stackTrace);
      state =
          const AuthError('Biometric authentication failed. Please try again.');
    }
  }

  /// Authenticate with fingerprint
  Future<void> authenticateWithFingerprint() async {
    try {
      state = const AuthLoading();

      logUserAction('fingerprint_auth_attempt', {});

      final result = await _authService.authenticateWithFingerprint();

      if (result.success && result.user != null) {
        state = AuthAuthenticated(result.user!);
        logUserAction('fingerprint_auth_success', {'user_id': result.user!.id});
      } else {
        state = AuthError(result.error ?? 'Fingerprint authentication failed');
        logUserAction('fingerprint_auth_failed', {
          'error': result.error,
        });
      }
    } catch (e, stackTrace) {
      logError('Fingerprint authentication error', e, stackTrace);
      state = const AuthError(
          'Fingerprint authentication failed. Please try again.',);
    }
  }

  /// Authenticate with face recognition
  Future<void> authenticateWithFace() async {
    try {
      state = const AuthLoading();

      logUserAction('face_auth_attempt', {});

      final result = await _authService.authenticateWithFace();

      if (result.success && result.user != null) {
        state = AuthAuthenticated(result.user!);
        logUserAction('face_auth_success', {'user_id': result.user!.id});
      } else {
        state = AuthError(result.error ?? 'Face recognition failed');
        logUserAction('face_auth_failed', {
          'error': result.error,
        });
      }
    } catch (e, stackTrace) {
      logError('Face recognition error', e, stackTrace);
      state = const AuthError('Face recognition failed. Please try again.');
    }
  }

  /// Get current device information
  Future<DeviceInfo> getCurrentDeviceInfo() async {
    return await _authService.getCurrentDeviceInfo();
  }

  /// Get registered devices for the current user
  Future<List<DeviceInfo>> getRegisteredDevices() async {
    return await _authService.getRegisteredDevices();
  }

  /// Revoke a specific device
  Future<bool> revokeDevice(String deviceId) async {
    try {
      logUserAction('device_revoke_attempt', {'device_id': deviceId});

      final success = await _authService.revokeDevice(deviceId);

      if (success) {
        logUserAction('device_revoke_success', {'device_id': deviceId});
      } else {
        logUserAction('device_revoke_failed', {'device_id': deviceId});
      }

      return success;
    } catch (e, stackTrace) {
      logError('Device revocation error', e, stackTrace);
      return false;
    }
  }

  /// Revoke all other devices (keep current device)
  Future<bool> revokeAllOtherDevices() async {
    try {
      logUserAction('revoke_all_devices_attempt', {});

      final success = await _authService.revokeAllOtherDevices();

      if (success) {
        logUserAction('revoke_all_devices_success', {});
      } else {
        logUserAction('revoke_all_devices_failed', {});
      }

      return success;
    } catch (e, stackTrace) {
      logError('Revoke all devices error', e, stackTrace);
      return false;
    }
  }

  /// Update device activity (heartbeat)
  Future<void> updateDeviceActivity() async {
    try {
      await _authService.updateDeviceActivity();
    } catch (e, stackTrace) {
      logError('Update device activity error', e, stackTrace);
    }
  }
}

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final socialAuthService = ref.watch(socialAuthServiceProvider);
  final biometricAuthService = ref.watch(biometricAuthServiceProvider);
  final deviceManagementService = ref.watch(deviceManagementServiceProvider);
  return AuthService(apiService, storageService, socialAuthService,
      biometricAuthService, deviceManagementService,);
});

/// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Current user provider
final currentUserProvider = Provider<UserData?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

/// Authentication status provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is AuthAuthenticated;
});

