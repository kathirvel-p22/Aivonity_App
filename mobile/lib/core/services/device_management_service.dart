import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/auth_models.dart';
import '../utils/logger.dart';
import 'api_service.dart';

/// Device Management Service
/// Handles device registration, tracking, and multi-device session management
class DeviceManagementService with LoggingMixin {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  // Storage keys
  static const String _deviceIdKey = 'device_id';
  static const String _sessionIdKey = 'session_id';

  DeviceManagementService(this._apiService)
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  /// Get current device ID
  Future<String> getDeviceId() async {
    String? deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }
    return deviceId;
  }

  /// Get current device information
  Future<DeviceInfo> getCurrentDeviceInfo() async {
    final deviceId = await getDeviceId();
    final deviceName = await _getDeviceName();
    final platform = Platform.operatingSystem;
    final model = await _getDeviceModel();
    final version = await _getAppVersion();

    return DeviceInfo(
      id: deviceId,
      name: deviceName,
      platform: platform,
      model: model,
      version: version,
      registeredAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );
  }

  /// Register current device with the server
  Future<bool> registerDevice(String userId) async {
    try {
      logInfo('Registering device for user: $userId');

      final deviceInfo = await getCurrentDeviceInfo();
      final sessionId = _uuid.v4();

      final registrationData = {
        'user_id': userId,
        'device_id': deviceInfo.id,
        'device_name': deviceInfo.name,
        'platform': deviceInfo.platform,
        'model': deviceInfo.model,
        'app_version': deviceInfo.version,
        'session_id': sessionId,
      };

      final response = await _apiService.registerDevice(registrationData);

      if (response.isSuccess) {
        await _secureStorage.write(key: _sessionIdKey, value: sessionId);
        logInfo('Device registered successfully');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      logError('Device registration error', e, stackTrace);
      return false;
    }
  }

  /// Get current session ID
  Future<String?> getCurrentSessionId() async {
    return await _secureStorage.read(key: _sessionIdKey);
  }

  /// Clear device session data
  Future<void> clearSessionData() async {
    try {
      await _secureStorage.delete(key: _sessionIdKey);
      logInfo('Device session data cleared');
    } catch (e, stackTrace) {
      logError('Failed to clear session data', e, stackTrace);
    }
  }

  // Private helper methods

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

  /// Get device model
  Future<String> _getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.model;
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get app version
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return '1.0.0';
    }
  }
}

