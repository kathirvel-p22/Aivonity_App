import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/social_auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/device_management_service.dart';

/// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Social Auth Service Provider
final socialAuthServiceProvider = Provider<SocialAuthService>((ref) {
  return SocialAuthService();
});

/// Biometric Auth Service Provider
final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// Device Management Service Provider
final deviceManagementServiceProvider =
    Provider<DeviceManagementService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DeviceManagementService(apiService);
});

