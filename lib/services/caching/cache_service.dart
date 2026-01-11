import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import 'cache_policy.dart';

/// Intelligent caching service with multiple cache levels
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, Timer> _memoryTimers = {};
  final Map<String, CachePolicy> _cachePolicies = {};

  /// Initialize cache service with default policies
  void initialize() {
    _setupDefaultPolicies();
    _startCleanupTimer();
  }

  void _setupDefaultPolicies() {
    // Vehicle telemetry data - short TTL, high frequency
    _cachePolicies['telemetry'] = CachePolicy(
      ttl: const Duration(minutes: 5),
      maxMemoryItems: 100,
      compressionEnabled: true,
      syncStrategy: SyncStrategy.immediate,
    );

    // Service centers - long TTL, location-based
    _cachePolicies['service_centers'] = CachePolicy(
      ttl: const Duration(days: 7),
      maxMemoryItems: 50,
      compressionEnabled: false,
      syncStrategy: SyncStrategy.background,
    );

    // User settings - persistent, immediate sync
    _cachePolicies['user_settings'] = CachePolicy(
      ttl: const Duration(days: 30),
      maxMemoryItems: 20,
      compressionEnabled: false,
      syncStrategy: SyncStrategy.immediate,
    );

    // API responses - medium TTL, conditional requests
    _cachePolicies['api_responses'] = CachePolicy(
      ttl: const Duration(hours: 1),
      maxMemoryItems: 200,
      compressionEnabled: true,
      syncStrategy: SyncStrategy.conditional,
    );

    // Chat messages - persistent, background sync
    _cachePolicies['chat_messages'] = CachePolicy(
      ttl: const Duration(days: 30),
      maxMemoryItems: 500,
      compressionEnabled: true,
      syncStrategy: SyncStrategy.background,
    );
  }

  /// Get data from cache with fallback strategy
  Future<T?> get<T>({
    required String key,
    required String category,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final policy = _cachePolicies[category] ?? _getDefaultPolicy();

    // 1. Check memory cache first
    final memoryResult = _getFromMemory<T>(key, fromJson);
    if (memoryResult != null) {
      return memoryResult;
    }

    // 2. Check database cache
    final dbResult = await _getFromDatabase<T>(key, category, fromJson);
    if (dbResult != null) {
      // Store in memory cache for faster access
      _storeInMemory(key, dbResult, policy);
      return dbResult;
    }

    return null;
  }

  /// Store data in cache with intelligent placement
  Future<void> put({
    required String key,
    required dynamic data,
    required String category,
    Map<String, dynamic>? metadata,
  }) async {
    final policy = _cachePolicies[category] ?? _getDefaultPolicy();

    // Store in memory cache
    _storeInMemory(key, data, policy);

    // Store in database cache
    await _storeInDatabase(key, data, category, policy, metadata);
  }

  /// Remove data from all cache levels
  Future<void> remove(String key, String category) async {
    // Remove from memory
    _memoryCache.remove(key);
    _memoryTimers[key]?.cancel();
    _memoryTimers.remove(key);

    // Remove from database (implementation depends on category)
    // This is a simplified version - in practice, you'd need category-specific removal
  }

  /// Clear cache for a specific category
  Future<void> clearCategory(String category) async {
    // Remove from memory cache
    final keysToRemove = <String>[];
    for (final key in _memoryCache.keys) {
      if (key.startsWith('$category:')) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _memoryTimers[key]?.cancel();
      _memoryTimers.remove(key);
    }

    // Clear from database based on category
    switch (category) {
      case 'telemetry':
        // Clear old telemetry data
        break;
      case 'service_centers':
        // Clear expired service centers
        break;
      // Add other categories as needed
    }
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    final dbSize = await _db.getDatabaseSize();

    return CacheStats(
      memoryItems: _memoryCache.length,
      databaseSizeBytes: dbSize,
      hitRate: _calculateHitRate(),
      categories: _cachePolicies.keys.toList(),
    );
  }

  /// Preload frequently accessed data
  Future<void> preloadData({
    required String vehicleId,
    required List<String> categories,
  }) async {
    for (final category in categories) {
      switch (category) {
        case 'telemetry':
          await _preloadTelemetryData(vehicleId);
          break;
        case 'service_centers':
          await _preloadServiceCenters();
          break;
        // Add other categories
      }
    }
  }

  // Private methods

  T? _getFromMemory<T>(String key, T Function(Map<String, dynamic>)? fromJson) {
    final cached = _memoryCache[key];
    if (cached == null) return null;

    if (cached is CachedItem) {
      if (cached.isExpired) {
        _memoryCache.remove(key);
        _memoryTimers[key]?.cancel();
        _memoryTimers.remove(key);
        return null;
      }

      if (fromJson != null && cached.data is Map<String, dynamic>) {
        return fromJson(cached.data as Map<String, dynamic>);
      }
      return cached.data as T?;
    }

    return cached as T?;
  }

  Future<T?> _getFromDatabase<T>(
    String key,
    String category,
    T Function(Map<String, dynamic>)? fromJson,
  ) async {
    try {
      switch (category) {
        case 'api_responses':
          final cached = await _db.getCachedApiResponse(key);
          if (cached != null) {
            final data = cached['data'];
            if (fromJson != null && data is Map<String, dynamic>) {
              return fromJson(data);
            }
            return data as T?;
          }
          break;
        // Add other category handlers
      }
    } catch (e) {
      debugPrint('Error getting from database cache: $e');
    }
    return null;
  }

  void _storeInMemory(String key, dynamic data, CachePolicy policy) {
    // Check memory limits
    if (_memoryCache.length >= policy.maxMemoryItems) {
      _evictLeastRecentlyUsed();
    }

    final cachedItem = CachedItem(
      data: data,
      timestamp: DateTime.now(),
      ttl: policy.ttl,
    );

    _memoryCache[key] = cachedItem;

    // Set expiration timer
    _memoryTimers[key]?.cancel();
    _memoryTimers[key] = Timer(policy.ttl, () {
      _memoryCache.remove(key);
      _memoryTimers.remove(key);
    });
  }

  Future<void> _storeInDatabase(
    String key,
    dynamic data,
    String category,
    CachePolicy policy,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      switch (category) {
        case 'api_responses':
          if (data is Map<String, dynamic>) {
            await _db.cacheApiResponse(
              endpoint: key,
              responseData: data,
              ttl: policy.ttl,
              etag: metadata?['etag'],
            );
          }
          break;
        case 'telemetry':
          if (data is Map<String, dynamic>) {
            await _db.insertVehicleData({
              'vehicle_id': metadata?['vehicle_id'] ?? 'unknown',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'data_type': 'telemetry',
              'data_json': json.encode(data),
            });
          }
          break;
        // Add other category handlers
      }
    } catch (e) {
      debugPrint('Error storing in database cache: $e');
    }
  }

  void _evictLeastRecentlyUsed() {
    if (_memoryCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _memoryCache.entries) {
      if (entry.value is CachedItem) {
        final item = entry.value as CachedItem;
        if (oldestTime == null || item.timestamp.isBefore(oldestTime)) {
          oldestTime = item.timestamp;
          oldestKey = entry.key;
        }
      }
    }

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
      _memoryTimers[oldestKey]?.cancel();
      _memoryTimers.remove(oldestKey);
    }
  }

  CachePolicy _getDefaultPolicy() {
    return CachePolicy(
      ttl: const Duration(hours: 1),
      maxMemoryItems: 100,
      compressionEnabled: false,
      syncStrategy: SyncStrategy.background,
    );
  }

  double _calculateHitRate() {
    // Simplified hit rate calculation
    // In a real implementation, you'd track hits and misses
    return 0.85; // Placeholder
  }

  Future<void> _preloadTelemetryData(String vehicleId) async {
    // Preload recent telemetry data
    final recentData = await _db.getVehicleData(
      vehicleId: vehicleId,
      limit: 100,
    );

    for (final data in recentData) {
      final key = 'telemetry:${data['id']}';
      _storeInMemory(key, data, _cachePolicies['telemetry']!);
    }
  }

  Future<void> _preloadServiceCenters() async {
    // Preload cached service centers
    final centers = await _db.getCachedServiceCenters();

    for (final center in centers) {
      final key = 'service_center:${center['center_id']}';
      _storeInMemory(key, center, _cachePolicies['service_centers']!);
    }
  }

  void _startCleanupTimer() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupExpiredData();
    });
  }

  Future<void> _cleanupExpiredData() async {
    // Clean up expired database cache
    await _db.clearExpiredCache();

    // Clean up expired memory cache (already handled by individual timers)

    // Vacuum database periodically for better performance
    final stats = await getStats();
    if (stats.databaseSizeBytes > 50 * 1024 * 1024) {
      // 50MB threshold
      await _db.vacuum();
    }
  }
}

/// Cached item wrapper for memory cache
class CachedItem {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  CachedItem({required this.data, required this.timestamp, required this.ttl});

  bool get isExpired => DateTime.now().isAfter(timestamp.add(ttl));
}

/// Cache statistics
class CacheStats {
  final int memoryItems;
  final int databaseSizeBytes;
  final double hitRate;
  final List<String> categories;

  CacheStats({
    required this.memoryItems,
    required this.databaseSizeBytes,
    required this.hitRate,
    required this.categories,
  });

  String get formattedDatabaseSize {
    if (databaseSizeBytes < 1024) return '${databaseSizeBytes}B';
    if (databaseSizeBytes < 1024 * 1024) {
      return '${(databaseSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(databaseSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

