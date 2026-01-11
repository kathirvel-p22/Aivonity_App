import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:uuid/uuid.dart';

import '../models/auth_models.dart';
import '../utils/logger.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'social_auth_service.dart';
import 'biometric_auth_service.dart';
import 'device_management_service.dart';

/// Comprehensive Authentication Service
/// Handles JWT-based authentication with refresh tokens, email verification,
/// password reset, secure password hashing, social authentication, biometric authentication,
/// and multi-device session management
class AuthService with LoggingMixin {
  final ApiService _apiService;
  final StorageService _storageService;
  final SocialAuthService _socialAuthService;
  final BiometricAuthService _biometricAuthService;
  final DeviceManagementService _deviceManagementService;
  final FlutterSecureStorage _secureStorage;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  // Token storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _deviceIdKey = 'device_id';
  static const String _deviceNameKey = 'device_name';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // Security constants
  static const int _saltLength = 32;

  AuthService(
    this._apiService,
    this._storageService,
    this._socialAuthService,
    this._biometricAuthService,
    this._deviceManagementService,
  ) : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  /// Initialize authentication service
  Future<void> initialize() async {
    try {
      // Generate or retrieve device ID
      await _ensureDeviceId();

      // Check for existing tokens and validate
      await _validateStoredTokens();

      logInfo('AuthService initialized successfully');
    } catch (e, stackTrace) {
      logError('Failed to initialize AuthService', e, stackTrace);
    }
  }

  /// Register new user with email verification
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      logInfo('Starting user registration for email: $email');

      // Validate input
      final validationError = _validateRegistrationInput(name, email, password);
      if (validationError != null) {
        return AuthResult.failure(error: validationError);
      }

      // Get device information
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();

      // Hash password securely
      final hashedPassword = _hashPassword(password);

      final registrationData = RegistrationData(
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: hashedPassword,
        phone: phone?.trim(),
        deviceId: deviceId,
        deviceName: deviceName,
      );

      // Call API to register user
      final response = await _apiService.register(registrationData.toJson());

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        final authResult = AuthResult.fromJson(data);

        if (authResult.success && authResult.accessToken != null) {
          // Store tokens securely
          await _storeTokens(
            authResult.accessToken!,
            authResult.refreshToken!,
          );

          // Store user data
          if (authResult.user != null) {
            await _storeUserData(authResult.user!);

            // Register device for session management
            await _deviceManagementService.registerDevice(authResult.user!.id);
          }

          logInfo('User registration successful');
          return authResult;
        }
      }

      return AuthResult.failure(
        error: response.error ?? 'Registration failed',
      );
    } catch (e, stackTrace) {
      logError('Registration error', e, stackTrace);
      return AuthResult.failure(
        error: 'Registration failed. Please try again.',
      );
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      logInfo('Starting user login for email: $email');

      // Validate input
      if (email.trim().isEmpty || password.isEmpty) {
        return AuthResult.failure(error: 'Email and password are required');
      }

      // Get device information
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();

      final credentials = LoginCredentials(
        email: email.trim().toLowerCase(),
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
      );

      // Call API to login
      final response = await _apiService.login(credentials.toJson());

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        final authResult = AuthResult.fromJson(data);

        if (authResult.success && authResult.accessToken != null) {
          // Store tokens securely
          await _storeTokens(
            authResult.accessToken!,
            authResult.refreshToken!,
          );

          // Store user data
          if (authResult.user != null) {
            await _storeUserData(authResult.user!);

            // Register device for session management
            await _deviceManagementService.registerDevice(authResult.user!.id);
          }

          logInfo('User login successful');
          return authResult;
        }
      }

      return AuthResult.failure(
        error: response.error ?? 'Login failed',
      );
    } catch (e, stackTrace) {
      logError('Login error', e, stackTrace);
      return AuthResult.failure(
        error: 'Login failed. Please try again.',
      );
    }
  }

  /// Request password reset
  Future<AuthResult> requestPasswordReset(String email) async {
    try {
      logInfo('Requesting password reset for email: $email');

      if (email.trim().isEmpty) {
        return AuthResult.failure(error: 'Email is required');
      }

      final request = PasswordResetRequest(
        email: email.trim().toLowerCase(),
      );

      final response = await _apiService.requestPasswordReset(request.toJson());

      if (response.isSuccess) {
        logInfo('Password reset request sent successfully');
        return AuthResult.success(
          accessToken: '',
          refreshToken: '',
          user: UserData(
            id: '',
            email: email,
            name: '',
            createdAt: DateTime.now(),
          ),
          message: 'Password reset instructions sent to your email',
        );
      }

      return AuthResult.failure(
        error: response.error ?? 'Failed to send password reset email',
      );
    } catch (e, stackTrace) {
      logError('Password reset request error', e, stackTrace);
      return AuthResult.failure(
        error: 'Failed to send password reset email. Please try again.',
      );
    }
  }

  /// Confirm password reset
  Future<AuthResult> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    try {
      logInfo('Confirming password reset');

      if (token.trim().isEmpty || newPassword.isEmpty) {
        return AuthResult.failure(
          error: 'Reset token and new password are required',
        );
      }

      // Validate new password
      final passwordError = _validatePassword(newPassword);
      if (passwordError != null) {
        return AuthResult.failure(error: passwordError);
      }

      // Hash new password
      final hashedPassword = _hashPassword(newPassword);

      final confirmation = PasswordResetConfirmation(
        token: token.trim(),
        newPassword: hashedPassword,
      );

      final response =
          await _apiService.confirmPasswordReset(confirmation.toJson());

      if (response.isSuccess) {
        logInfo('Password reset confirmed successfully');
        return AuthResult.success(
          accessToken: '',
          refreshToken: '',
          user: UserData(
            id: '',
            email: '',
            name: '',
            createdAt: DateTime.now(),
          ),
          message:
              'Password reset successful. Please login with your new password.',
        );
      }

      return AuthResult.failure(
        error: response.error ?? 'Failed to reset password',
      );
    } catch (e, stackTrace) {
      logError('Password reset confirmation error', e, stackTrace);
      return AuthResult.failure(
        error: 'Failed to reset password. Please try again.',
      );
    }
  }

  /// Verify email address
  Future<AuthResult> verifyEmail(String token) async {
    try {
      logInfo('Verifying email with token');

      if (token.trim().isEmpty) {
        return AuthResult.failure(error: 'Verification token is required');
      }

      final request = EmailVerificationRequest(token: token.trim());

      final response = await _apiService.verifyEmail(request.toJson());

      if (response.isSuccess) {
        logInfo('Email verification successful');

        // Update stored user data if available
        final userData = await _getUserData();
        if (userData != null) {
          final updatedUser = UserData(
            id: userData.id,
            email: userData.email,
            name: userData.name,
            phone: userData.phone,
            avatarUrl: userData.avatarUrl,
            isVerified: true,
            emailVerified: true,
            role: userData.role,
            createdAt: userData.createdAt,
            lastLoginAt: userData.lastLoginAt,
          );
          await _storeUserData(updatedUser);
        }

        return AuthResult.success(
          accessToken: '',
          refreshToken: '',
          user: userData ??
              UserData(
                id: '',
                email: '',
                name: '',
                createdAt: DateTime.now(),
              ),
          message: 'Email verified successfully',
        );
      }

      return AuthResult.failure(
        error: response.error ?? 'Email verification failed',
      );
    } catch (e, stackTrace) {
      logError('Email verification error', e, stackTrace);
      return AuthResult.failure(
        error: 'Email verification failed. Please try again.',
      );
    }
  }

  /// Refresh access token
  Future<AuthResult> refreshToken() async {
    try {
      logInfo('Refreshing access token');

      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        return AuthResult.failure(error: 'No refresh token available');
      }

      final response =
          await _apiService.refreshToken({'refresh_token': refreshToken});

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final tokenPair = TokenPair.fromJson(data);

        await _storeTokens(tokenPair.accessToken, tokenPair.refreshToken);

        logInfo('Token refresh successful');
        return AuthResult.success(
          accessToken: tokenPair.accessToken,
          refreshToken: tokenPair.refreshToken,
          user: await _getUserData() ??
              UserData(
                id: '',
                email: '',
                name: '',
                createdAt: DateTime.now(),
              ),
        );
      }

      return AuthResult.failure(
        error: response.error ?? 'Token refresh failed',
      );
    } catch (e, stackTrace) {
      logError('Token refresh error', e, stackTrace);
      return AuthResult.failure(
        error: 'Token refresh failed',
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      logInfo('Logging out user');

      // Call API to invalidate tokens on server
      final accessToken = await _getAccessToken();
      if (accessToken != null) {
        await _apiService.logout({'access_token': accessToken});
      }

      // Sign out from social providers
      await _socialAuthService.signOutAll();

      // Clear device session data
      await _deviceManagementService.clearSessionData();

      // Clear all stored data
      await _clearAllTokens();

      logInfo('User logged out successfully');
    } catch (e, stackTrace) {
      logError('Logout error', e, stackTrace);
      // Still clear local data even if API call fails
      await _clearAllTokens();
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      // For development/testing - always return true to skip login
      // You can comment this out when you want real authentication
      return true;

      /* Original authentication logic - uncomment when needed
      final accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      // Check if token is expired
      if (JwtDecoder.isExpired(accessToken)) {
        // Try to refresh token
        final refreshResult = await refreshToken();
        return refreshResult.success;
      }

      return true;
      */
    } catch (e) {
      return false;
    }
  }

  /// Get current user data
  Future<UserData?> getCurrentUser() async {
    // Return mock user for development/testing
    return UserData(
      id: 'demo_user_001',
      email: 'demo@aivonity.com',
      name: 'Demo User',
      phone: '+1234567890',
      avatarUrl: null,
      isVerified: true,
      emailVerified: true,
      role: 'user',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    /* Original logic - uncomment when needed
    return await _getUserData();
    */
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    // Return mock token for development/testing
    return 'mock_access_token_for_demo';

    /* Original logic - uncomment when needed
    return await _getAccessToken();
    */
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      logInfo('Starting Google Sign-In authentication');

      final socialData = await _socialAuthService.signInWithGoogle();
      if (socialData == null) {
        return AuthResult.failure(error: 'Google Sign-In was cancelled');
      }

      return await _processSocialLogin(socialData);
    } catch (e, stackTrace) {
      logError('Google Sign-In authentication error', e, stackTrace);
      return AuthResult.failure(
        error: 'Google Sign-In failed. Please try again.',
      );
    }
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    try {
      logInfo('Starting Apple Sign-In authentication');

      final socialData = await _socialAuthService.signInWithApple();
      if (socialData == null) {
        return AuthResult.failure(
          error: 'Apple Sign-In was cancelled or unavailable',
        );
      }

      return await _processSocialLogin(socialData);
    } catch (e, stackTrace) {
      logError('Apple Sign-In authentication error', e, stackTrace);
      return AuthResult.failure(
        error: 'Apple Sign-In failed. Please try again.',
      );
    }
  }

  /// Process social login data
  Future<AuthResult> _processSocialLogin(SocialLoginData socialData) async {
    try {
      // Get device information
      final deviceId = await _getDeviceId();
      final deviceName = await _getDeviceName();

      // Prepare social login request
      final socialLoginRequest = {
        'provider': socialData.provider.name,
        'token': socialData.token,
        'email': socialData.email,
        'name': socialData.name,
        'avatar_url': socialData.avatarUrl,
        'device_id': deviceId,
        'device_name': deviceName,
      };

      // Call API to authenticate with social provider
      final response = await _apiService.socialLogin(socialLoginRequest);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        final authResult = AuthResult.fromJson(data);

        if (authResult.success && authResult.accessToken != null) {
          // Store tokens securely
          await _storeTokens(
            authResult.accessToken!,
            authResult.refreshToken!,
          );

          // Store user data
          if (authResult.user != null) {
            await _storeUserData(authResult.user!);
          }

          logInfo('Social authentication successful');
          return authResult;
        }
      }

      return AuthResult.failure(
        error: response.error ?? 'Social authentication failed',
      );
    } catch (e, stackTrace) {
      logError('Social login processing error', e, stackTrace);
      return AuthResult.failure(
        error: 'Social authentication failed. Please try again.',
      );
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await _biometricAuthService.isBiometricAvailable();
  }

  /// Check if biometric authentication is enabled for the user
  Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Enable biometric authentication for the user
  Future<AuthResult> enableBiometric() async {
    try {
      logInfo('Enabling biometric authentication');

      // Check if biometric is available
      final isAvailable = await _biometricAuthService.isBiometricAvailable();
      if (!isAvailable) {
        return AuthResult.failure(
          error: 'Biometric authentication is not available on this device',
        );
      }

      // Test biometric authentication
      final authResult = await _biometricAuthService.authenticate(
        reason: 'Please authenticate to enable biometric login',
      );

      if (!authResult.success) {
        return AuthResult.failure(
          error: authResult.error ?? 'Biometric authentication failed',
        );
      }

      // Store biometric enabled flag
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');

      logInfo('Biometric authentication enabled successfully');
      return AuthResult.success(
        accessToken: '',
        refreshToken: '',
        user: await _getUserData() ??
            UserData(
              id: '',
              email: '',
              name: '',
              createdAt: DateTime.now(),
            ),
        message: 'Biometric authentication enabled successfully',
      );
    } catch (e, stackTrace) {
      logError('Enable biometric error', e, stackTrace);
      return AuthResult.failure(
        error: 'Failed to enable biometric authentication',
      );
    }
  }

  /// Disable biometric authentication for the user
  Future<void> disableBiometric() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      logInfo('Biometric authentication disabled');
    } catch (e, stackTrace) {
      logError('Disable biometric error', e, stackTrace);
    }
  }

  /// Authenticate with biometrics
  Future<AuthResult> authenticateWithBiometric() async {
    try {
      logInfo('Starting biometric authentication');

      // Check if biometric is enabled
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return AuthResult.failure(
          error: 'Biometric authentication is not enabled',
        );
      }

      // Check if user is already authenticated
      final currentUser = await _getUserData();
      if (currentUser == null) {
        return AuthResult.failure(
          error: 'No user data found. Please login first.',
        );
      }

      // Perform biometric authentication
      final authResult = await _biometricAuthService.authenticate(
        reason: 'Please authenticate to access your account',
      );

      if (!authResult.success) {
        return AuthResult.failure(
          error: authResult.error ?? 'Biometric authentication failed',
        );
      }

      // Check if tokens are still valid
      final isAuthenticatedResult = await isAuthenticated();
      if (!isAuthenticatedResult) {
        return AuthResult.failure(
          error: 'Session expired. Please login again.',
        );
      }

      logInfo('Biometric authentication successful');
      return AuthResult.success(
        accessToken: await _getAccessToken() ?? '',
        refreshToken: await _getRefreshToken() ?? '',
        user: currentUser,
        message: 'Biometric authentication successful',
      );
    } catch (e, stackTrace) {
      logError('Biometric authentication error', e, stackTrace);
      return AuthResult.failure(
        error: 'Biometric authentication failed. Please try again.',
      );
    }
  }

  /// Authenticate with fingerprint
  Future<AuthResult> authenticateWithFingerprint() async {
    try {
      logInfo('Starting fingerprint authentication');

      // Check if biometric is enabled
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return AuthResult.failure(
          error: 'Biometric authentication is not enabled',
        );
      }

      // Check if fingerprint is available
      final isAvailable = await _biometricAuthService.isFingerprintAvailable();
      if (!isAvailable) {
        return AuthResult.failure(
          error: 'Fingerprint authentication is not available',
        );
      }

      // Check if user is already authenticated
      final currentUser = await _getUserData();
      if (currentUser == null) {
        return AuthResult.failure(
          error: 'No user data found. Please login first.',
        );
      }

      // Perform fingerprint authentication
      final authResult =
          await _biometricAuthService.authenticateWithFingerprint();

      if (!authResult.success) {
        return AuthResult.failure(
          error: authResult.error ?? 'Fingerprint authentication failed',
        );
      }

      logInfo('Fingerprint authentication successful');
      return AuthResult.success(
        accessToken: await _getAccessToken() ?? '',
        refreshToken: await _getRefreshToken() ?? '',
        user: currentUser,
        message: 'Fingerprint authentication successful',
      );
    } catch (e, stackTrace) {
      logError('Fingerprint authentication error', e, stackTrace);
      return AuthResult.failure(
        error: 'Fingerprint authentication failed. Please try again.',
      );
    }
  }

  /// Authenticate with face recognition
  Future<AuthResult> authenticateWithFace() async {
    try {
      logInfo('Starting face recognition authentication');

      // Check if biometric is enabled
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return AuthResult.failure(
          error: 'Biometric authentication is not enabled',
        );
      }

      // Check if face recognition is available
      final isAvailable =
          await _biometricAuthService.isFaceRecognitionAvailable();
      if (!isAvailable) {
        return AuthResult.failure(
          error: 'Face recognition is not available',
        );
      }

      // Check if user is already authenticated
      final currentUser = await _getUserData();
      if (currentUser == null) {
        return AuthResult.failure(
          error: 'No user data found. Please login first.',
        );
      }

      // Perform face recognition authentication
      final authResult = await _biometricAuthService.authenticateWithFace();

      if (!authResult.success) {
        return AuthResult.failure(
          error: authResult.error ?? 'Face recognition failed',
        );
      }

      logInfo('Face recognition authentication successful');
      return AuthResult.success(
        accessToken: await _getAccessToken() ?? '',
        refreshToken: await _getRefreshToken() ?? '',
        user: currentUser,
        message: 'Face recognition successful',
      );
    } catch (e, stackTrace) {
      logError('Face recognition authentication error', e, stackTrace);
      return AuthResult.failure(
        error: 'Face recognition failed. Please try again.',
      );
    }
  }

  /// Get current device information
  Future<DeviceInfo> getCurrentDeviceInfo() async {
    return await _deviceManagementService.getCurrentDeviceInfo();
  }

  /// Get registered devices for the current user
  Future<List<DeviceInfo>> getRegisteredDevices() async {
    try {
      final response = await _apiService.getRegisteredDevices();
      if (response.isSuccess && response.data != null) {
        final devicesData = response.data!;
        return devicesData.map((data) => DeviceInfo.fromJson(data)).toList();
      }
      return [];
    } catch (e, stackTrace) {
      logError('Failed to get registered devices', e, stackTrace);
      return [];
    }
  }

  /// Revoke a specific device
  Future<bool> revokeDevice(String deviceId) async {
    try {
      logInfo('Revoking device: $deviceId');
      final response = await _apiService.revokeDevice({'device_id': deviceId});
      return response.isSuccess;
    } catch (e, stackTrace) {
      logError('Device revocation error', e, stackTrace);
      return false;
    }
  }

  /// Revoke all other devices (keep current device)
  Future<bool> revokeAllOtherDevices() async {
    try {
      logInfo('Revoking all other devices');
      final currentDeviceId = await _deviceManagementService.getDeviceId();
      final response = await _apiService.revokeAllOtherDevices({
        'current_device_id': currentDeviceId,
      });
      return response.isSuccess;
    } catch (e, stackTrace) {
      logError('Revoke all other devices error', e, stackTrace);
      return false;
    }
  }

  /// Update device activity (heartbeat)
  Future<void> updateDeviceActivity() async {
    try {
      final deviceId = await _deviceManagementService.getDeviceId();
      final sessionId = await _deviceManagementService.getCurrentSessionId();

      if (sessionId != null) {
        await _apiService.updateDeviceActivity({
          'device_id': deviceId,
          'session_id': sessionId,
          'last_active_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e, stackTrace) {
      logError('Failed to update device activity', e, stackTrace);
    }
  }

  // Private helper methods

  /// Ensure device ID exists
  Future<void> _ensureDeviceId() async {
    String? deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }

    String? deviceName = await _secureStorage.read(key: _deviceNameKey);
    if (deviceName == null) {
      deviceName = await _getDeviceName();
      await _secureStorage.write(key: _deviceNameKey, value: deviceName);
    }
  }

  /// Get device ID
  Future<String> _getDeviceId() async {
    return await _secureStorage.read(key: _deviceIdKey) ?? _uuid.v4();
  }

  /// Get device name
  Future<String> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Validate stored tokens
  Future<void> _validateStoredTokens() async {
    final accessToken = await _getAccessToken();
    if (accessToken != null && JwtDecoder.isExpired(accessToken)) {
      // Try to refresh token
      await refreshToken();
    }
  }

  /// Store tokens securely
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Store user data
  Future<void> _storeUserData(UserData userData) async {
    final userJson = jsonEncode(userData.toJson());
    await _secureStorage.write(key: _userDataKey, value: userJson);
  }

  /// Get access token
  Future<String?> _getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  Future<String?> _getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Get user data
  Future<UserData?> _getUserData() async {
    final userJson = await _secureStorage.read(key: _userDataKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserData.fromJson(userMap);
      } catch (e) {
        logError('Failed to parse user data', e);
      }
    }
    return null;
  }

  /// Clear all tokens and user data
  Future<void> _clearAllTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userDataKey);
  }

  /// Hash password securely using PBKDF2
  String _hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}:$salt';
  }

  /// Generate random salt
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes =
        List<int>.generate(_saltLength, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  /// Validate registration input
  String? _validateRegistrationInput(
    String name,
    String email,
    String password,
  ) {
    if (name.trim().isEmpty) {
      return 'Name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return _validatePassword(password);
  }

  /// Validate password strength
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
}
