import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Redis-like caching service for backend scalability
class RedisCacheService {
  static const String _cachePrefix = 'redis_cache_';
  static const String _keyExpirationPrefix = 'redis_exp_';
  static const Duration _defaultTtl = Duration(hours: 1);

  SharedPreferences? _prefs;
  Timer? _cleanupTimer;

  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _expirationTimes = {};
  final Map<String, Timer> _expirationTimers = {};

  /// Initialize the Redis cache service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCacheFromStorage();
    _startCleanupTimer();

    print('🔴 Redis cache service initialized');
  }

  /// Set a key-value pair with optional TTL
  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    ttl ??= _defaultTtl;

    try {
      // Store in memory cache
      _memoryCache[key] = value;

      // Set expiration
      final expirationTime = DateTime.now().add(ttl);
      _expirationTimes[key] = expirationTime;

      // Set expiration timer
      _setExpirationTimer(key, ttl);

      // Persist to storage
      await _persistToStorage(key, value, expirationTime);

      print('🔴 SET $key (TTL: ${ttl.inSeconds}s)');
    } catch (e) {
      print('❌ Error setting cache key $key: $e');
    }
  }

  /// Get a value by key
  Future<T?> get<T>(String key) async {
    try {
      // Check if key exists and not expired
      if (!_isKeyValid(key)) {
        await delete(key);
        return null;
      }

      // Return from memory cache
      final value = _memoryCache[key];
      if (value != null) {
        print('🔴 GET $key (HIT)');
        return value as T?;
      }

      // Try to load from persistent storage
      final persistedValue = await _loadFromStorage(key);
      if (persistedValue != null) {
        _memoryCache[key] = persistedValue;
        print('🔴 GET $key (DISK HIT)');
        return persistedValue as T?;
      }

      print('🔴 GET $key (MISS)');
      return null;
    } catch (e) {
      print('❌ Error getting cache key $key: $e');
      return null;
    }
  }

  /// Delete a key
  Future<void> delete(String key) async {
    try {
      // Remove from memory
      _memoryCache.remove(key);
      _expirationTimes.remove(key);

      // Cancel expiration timer
      _expirationTimers[key]?.cancel();
      _expirationTimers.remove(key);

      // Remove from persistent storage
      await _prefs?.remove('$_cachePrefix$key');
      await _prefs?.remove('$_keyExpirationPrefix$key');

      print('🔴 DEL $key');
    } catch (e) {
      print('❌ Error deleting cache key $key: $e');
    }
  }

  /// Check if key exists
  Future<bool> exists(String key) async {
    return _isKeyValid(key);
  }

  /// Set expiration time for a key
  Future<void> expire(String key, Duration ttl) async {
    if (!_memoryCache.containsKey(key)) return;

    final expirationTime = DateTime.now().add(ttl);
    _expirationTimes[key] = expirationTime;

    // Update expiration timer
    _setExpirationTimer(key, ttl);

    // Update persistent storage
    await _prefs?.setString(
      '$_keyExpirationPrefix$key',
      expirationTime.toIso8601String(),
    );

    print('🔴 EXPIRE $key ${ttl.inSeconds}s');
  }

  /// Get time to live for a key
  Duration? ttl(String key) {
    final expirationTime = _expirationTimes[key];
    if (expirationTime == null) return null;

    final now = DateTime.now();
    if (expirationTime.isBefore(now)) return Duration.zero;

    return expirationTime.difference(now);
  }

  /// Increment a numeric value
  Future<int> increment(String key, {int by = 1}) async {
    final currentValue = await get<int>(key) ?? 0;
    final newValue = currentValue + by;

    await set(key, newValue);
    return newValue;
  }

  /// Decrement a numeric value
  Future<int> decrement(String key, {int by = 1}) async {
    return await increment(key, by: -by);
  }

  /// Add item to a list
  Future<void> listPush(String key, dynamic value) async {
    final list = await get<List<dynamic>>(key) ?? <dynamic>[];
    list.add(value);
    await set(key, list);
  }

  /// Remove and return item from list
  Future<T?> listPop<T>(String key) async {
    final list = await get<List<dynamic>>(key);
    if (list == null || list.isEmpty) return null;

    final value = list.removeLast();
    await set(key, list);

    return value as T?;
  }

  /// Get list length
  Future<int> listLength(String key) async {
    final list = await get<List<dynamic>>(key);
    return list?.length ?? 0;
  }

  /// Add item to a set
  Future<void> setAdd(String key, dynamic value) async {
    final set = await get<Set<dynamic>>(key) ?? <dynamic>{};
    set.add(value);
    await this.set(key, set.toList());
  }

  /// Remove item from a set
  Future<void> setRemove(String key, dynamic value) async {
    final set = await get<List<dynamic>>(key);
    if (set != null) {
      set.remove(value);
      await this.set(key, set);
    }
  }

  /// Check if item is in set
  Future<bool> setContains(String key, dynamic value) async {
    final set = await get<List<dynamic>>(key);
    return set?.contains(value) ?? false;
  }

  /// Set hash field
  Future<void> hashSet(String key, String field, dynamic value) async {
    final hash = await get<Map<String, dynamic>>(key) ?? <String, dynamic>{};
    hash[field] = value;
    await set(key, hash);
  }

  /// Get hash field
  Future<T?> hashGet<T>(String key, String field) async {
    final hash = await get<Map<String, dynamic>>(key);
    return hash?[field] as T?;
  }

  /// Delete hash field
  Future<void> hashDelete(String key, String field) async {
    final hash = await get<Map<String, dynamic>>(key);
    if (hash != null) {
      hash.remove(field);
      await set(key, hash);
    }
  }

  /// Get all hash fields
  Future<Map<String, dynamic>?> hashGetAll(String key) async {
    return await get<Map<String, dynamic>>(key);
  }

  /// Get all keys matching pattern
  Future<List<String>> keys(String pattern) async {
    final allKeys = _memoryCache.keys.toList();

    if (pattern == '*') {
      return allKeys;
    }

    // Simple pattern matching (supports * wildcard)
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    return allKeys.where((key) => regex.hasMatch(key)).toList();
  }

  /// Flush all cache data
  Future<void> flushAll() async {
    try {
      // Clear memory cache
      _memoryCache.clear();
      _expirationTimes.clear();

      // Cancel all timers
      for (final timer in _expirationTimers.values) {
        timer.cancel();
      }
      _expirationTimers.clear();

      // Clear persistent storage
      final keys = _prefs?.getKeys() ?? <String>{};
      final cacheKeys = keys.where(
        (key) =>
            key.startsWith(_cachePrefix) ||
            key.startsWith(_keyExpirationPrefix),
      );

      for (final key in cacheKeys) {
        await _prefs?.remove(key);
      }

      print('🔴 FLUSHALL - Cache cleared');
    } catch (e) {
      print('❌ Error flushing cache: $e');
    }
  }

  /// Get cache statistics
  CacheStatistics getStats() {
    final totalKeys = _memoryCache.length;
    final expiredKeys = _expirationTimes.entries
        .where((entry) => entry.value.isBefore(DateTime.now()))
        .length;

    return CacheStatistics(
      totalKeys: totalKeys,
      expiredKeys: expiredKeys,
      memoryUsage: _calculateMemoryUsage(),
      hitRate: 0.0, // Would need to track hits/misses
    );
  }

  // Private helper methods

  bool _isKeyValid(String key) {
    if (!_memoryCache.containsKey(key)) return false;

    final expirationTime = _expirationTimes[key];
    if (expirationTime == null) return true;

    return expirationTime.isAfter(DateTime.now());
  }

  void _setExpirationTimer(String key, Duration ttl) {
    // Cancel existing timer
    _expirationTimers[key]?.cancel();

    // Set new timer
    _expirationTimers[key] = Timer(ttl, () async {
      await delete(key);
    });
  }

  Future<void> _persistToStorage(
    String key,
    dynamic value,
    DateTime expirationTime,
  ) async {
    try {
      final serializedValue = jsonEncode(value);
      await _prefs?.setString('$_cachePrefix$key', serializedValue);
      await _prefs?.setString(
        '$_keyExpirationPrefix$key',
        expirationTime.toIso8601String(),
      );
    } catch (e) {
      print('❌ Error persisting cache key $key: $e');
    }
  }

  Future<dynamic> _loadFromStorage(String key) async {
    try {
      // Check expiration first
      final expirationString = _prefs?.getString('$_keyExpirationPrefix$key');
      if (expirationString != null) {
        final expirationTime = DateTime.parse(expirationString);
        if (expirationTime.isBefore(DateTime.now())) {
          // Key expired, remove it
          await _prefs?.remove('$_cachePrefix$key');
          await _prefs?.remove('$_keyExpirationPrefix$key');
          return null;
        }
        _expirationTimes[key] = expirationTime;
      }

      // Load value
      final serializedValue = _prefs?.getString('$_cachePrefix$key');
      if (serializedValue != null) {
        return jsonDecode(serializedValue);
      }

      return null;
    } catch (e) {
      print('❌ Error loading cache key $key from storage: $e');
      return null;
    }
  }

  Future<void> _loadCacheFromStorage() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));

      for (final storageKey in cacheKeys) {
        final cacheKey = storageKey.substring(_cachePrefix.length);
        final value = await _loadFromStorage(cacheKey);

        if (value != null) {
          _memoryCache[cacheKey] = value;
        }
      }

      print('🔴 Loaded ${_memoryCache.length} keys from storage');
    } catch (e) {
      print('❌ Error loading cache from storage: $e');
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupExpiredKeys();
    });
  }

  void _cleanupExpiredKeys() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _expirationTimes.entries) {
      if (entry.value.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      delete(key);
    }

    if (expiredKeys.isNotEmpty) {
      print('🔴 Cleaned up ${expiredKeys.length} expired keys');
    }
  }

  int _calculateMemoryUsage() {
    // Rough estimation of memory usage
    int totalSize = 0;

    for (final entry in _memoryCache.entries) {
      try {
        final serialized = jsonEncode(entry.value);
        totalSize += serialized.length;
      } catch (e) {
        // Skip items that can't be serialized
      }
    }

    return totalSize;
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();

    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }

    _memoryCache.clear();
    _expirationTimes.clear();
    _expirationTimers.clear();
  }
}

/// Cache statistics
class CacheStatistics {
  final int totalKeys;
  final int expiredKeys;
  final int memoryUsage;
  final double hitRate;

  CacheStatistics({
    required this.totalKeys,
    required this.expiredKeys,
    required this.memoryUsage,
    required this.hitRate,
  });
}

