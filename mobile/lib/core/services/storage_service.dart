import 'dart:convert';
import 'package:flutter/foundation.dart';

/// AIVONITY Storage Service
/// Simplified storage service using SharedPreferences-like functionality
class StorageService extends ChangeNotifier {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  final Map<String, dynamic> _storage = {};
  final Map<String, dynamic> _secureStorage = {};

  bool _isInitialized = false;

  /// Initialize storage service
  static Future<void> initialize() async {
    try {
      await instance._loadFromPlatform();
      instance._isInitialized = true;
      debugPrint('Storage service initialized');
    } catch (e) {
      debugPrint('Failed to initialize storage service: $e');
    }
  }

  /// Check if storage is initialized
  bool get isInitialized => _isInitialized;

  // Regular Storage Methods

  /// Store a value
  Future<void> store(String key, dynamic value) async {
    try {
      _storage[key] = value;
      await _saveToPlatform();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to store value for key $key: $e');
    }
  }

  /// Retrieve a value
  T? retrieve<T>(String key) {
    try {
      final value = _storage[key];
      if (value is T) {
        return value;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to retrieve value for key $key: $e');
      return null;
    }
  }

  /// Remove a value
  Future<void> remove(String key) async {
    try {
      _storage.remove(key);
      await _saveToPlatform();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove value for key $key: $e');
    }
  }

  /// Check if key exists
  bool contains(String key) {
    return _storage.containsKey(key);
  }

  /// Clear all storage
  Future<void> clear() async {
    try {
      _storage.clear();
      await _saveToPlatform();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear storage: $e');
    }
  }

  /// Get all keys
  List<String> getAllKeys() {
    return _storage.keys.toList();
  }

  // Secure Storage Methods

  /// Store a secure value
  Future<void> storeSecure(String key, String value) async {
    try {
      _secureStorage[key] = value;
      await _saveSecureToPlatform();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to store secure value for key $key: $e');
    }
  }

  /// Retrieve a secure value
  Future<String?> retrieveSecure(String key) async {
    try {
      return _secureStorage[key] as String?;
    } catch (e) {
      debugPrint('Failed to retrieve secure value for key $key: $e');
      return null;
    }
  }

  /// Remove a secure value
  Future<void> removeSecure(String key) async {
    try {
      _secureStorage.remove(key);
      await _saveSecureToPlatform();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove secure value for key $key: $e');
    }
  }

  /// Clear all secure storage
  Future<void> clearSecure() async {
    try {
      _secureStorage.clear();
      await _saveSecureToPlatform();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear secure storage: $e');
    }
  }

  // Convenience Methods for Common Data Types

  /// Store JSON object
  Future<void> storeJson(String key, Map<String, dynamic> json) async {
    await store(key, jsonEncode(json));
  }

  /// Retrieve JSON object
  Map<String, dynamic>? retrieveJson(String key) {
    try {
      final jsonString = retrieve<String>(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to retrieve JSON for key $key: $e');
      return null;
    }
  }

  /// Store list
  Future<void> storeList(String key, List<dynamic> list) async {
    await store(key, jsonEncode(list));
  }

  /// Retrieve list
  List<dynamic>? retrieveList(String key) {
    try {
      final jsonString = retrieve<String>(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as List<dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to retrieve list for key $key: $e');
      return null;
    }
  }

  /// Store boolean
  Future<void> storeBool(String key, bool value) async {
    await store(key, value);
  }

  /// Retrieve boolean
  bool? retrieveBool(String key) {
    return retrieve<bool>(key);
  }

  /// Store integer
  Future<void> storeInt(String key, int value) async {
    await store(key, value);
  }

  /// Retrieve integer
  int? retrieveInt(String key) {
    return retrieve<int>(key);
  }

  /// Store double
  Future<void> storeDouble(String key, double value) async {
    await store(key, value);
  }

  /// Retrieve double
  double? retrieveDouble(String key) {
    return retrieve<double>(key);
  }

  /// Store string
  Future<void> storeString(String key, String value) async {
    await store(key, value);
  }

  /// Retrieve string
  String? retrieveString(String key) {
    return retrieve<String>(key);
  }

  // Cache Management

  /// Store with expiration
  Future<void> storeWithExpiration(
    String key,
    dynamic value,
    Duration expiration,
  ) async {
    final expirationTime = DateTime.now().add(expiration);
    final cacheData = {
      'value': value,
      'expiration': expirationTime.millisecondsSinceEpoch,
    };
    await store('cache_$key', jsonEncode(cacheData));
  }

  /// Retrieve with expiration check
  T? retrieveWithExpiration<T>(String key) {
    try {
      final cacheString = retrieve<String>('cache_$key');
      if (cacheString == null) return null;

      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(
        cacheData['expiration'] as int,
      );

      if (DateTime.now().isAfter(expirationTime)) {
        // Cache expired, remove it
        remove('cache_$key');
        return null;
      }

      final value = cacheData['value'];
      if (value is T) {
        return value;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to retrieve cached value for key $key: $e');
      return null;
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final keysToRemove = <String>[];
      final now = DateTime.now();

      for (final key in _storage.keys) {
        if (key.startsWith('cache_')) {
          try {
            final cacheString = _storage[key] as String?;
            if (cacheString != null) {
              final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
              final expirationTime = DateTime.fromMillisecondsSinceEpoch(
                cacheData['expiration'] as int,
              );

              if (now.isAfter(expirationTime)) {
                keysToRemove.add(key);
              }
            }
          } catch (e) {
            // Invalid cache entry, remove it
            keysToRemove.add(key);
          }
        }
      }

      for (final key in keysToRemove) {
        _storage.remove(key);
      }

      if (keysToRemove.isNotEmpty) {
        await _saveToPlatform();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to clear expired cache: $e');
    }
  }

  // Platform Integration (Simulated)

  Future<void> _loadFromPlatform() async {
    // Simulate loading from platform storage
    await Future.delayed(const Duration(milliseconds: 100));
    // In a real implementation, this would load from SharedPreferences
  }

  Future<void> _saveToPlatform() async {
    // Simulate saving to platform storage
    await Future.delayed(const Duration(milliseconds: 50));
    // In a real implementation, this would save to SharedPreferences
  }

  Future<void> _saveSecureToPlatform() async {
    // Simulate saving to secure storage
    await Future.delayed(const Duration(milliseconds: 50));
    // In a real implementation, this would save to FlutterSecureStorage
  }

  // Storage Statistics

  /// Get storage size (approximate)
  int getStorageSize() {
    try {
      final jsonString = jsonEncode(_storage);
      return jsonString.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get number of stored items
  int getItemCount() {
    return _storage.length;
  }

  /// Get storage info
  Map<String, dynamic> getStorageInfo() {
    return {
      'itemCount': getItemCount(),
      'storageSize': getStorageSize(),
      'secureItemCount': _secureStorage.length,
      'isInitialized': _isInitialized,
    };
  }

  // Authentication-specific methods

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await retrieveSecure('auth_token');
  }

  /// Set authentication token
  Future<void> setAuthToken(String token) async {
    await storeSecure('auth_token', token);
  }

  /// Clear authentication token
  Future<void> clearAuthToken() async {
    await removeSecure('auth_token');
  }

  /// Set user data
  Future<void> setUserData(Map<String, dynamic> userData) async {
    await storeJson('user_data', userData);
  }

  /// Get user data
  Map<String, dynamic>? getUserData() {
    return retrieveJson('user_data');
  }

  /// Clear user data
  Future<void> clearUserData() async {
    await remove('user_data');
  }
}

