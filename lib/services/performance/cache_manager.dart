import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../../utils/logger.dart';

/// Advanced cache management service with multiple cache layers
class AdvancedCacheManager {
  static const String _cachePrefix = 'cache_';
  static const String _cacheMetadataPrefix = 'cache_meta_';
  static const int _defaultMaxCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration _defaultTtl = Duration(hours: 24);

  SharedPreferences? _prefs;
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, Timer> _expirationTimers = {};

  int _maxCacheSize = _defaultMaxCacheSize;
  int _currentCacheSize = 0;

  /// Initialize the cache manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCacheMetadata();
    _startCacheCleanup();

    AppLogger.info('💾 Advanced cache manager initialized');
  }

  /// Store data in cache with TTL
  Future<void> put(String key, dynamic data, {Duration? ttl}) async {
    ttl ??= _defaultTtl;

    try {
      final serializedData = _serializeData(data);
      final compressedData = await _compressData(serializedData);
      final cacheKey = _generateCacheKey(key);

      final entry = CacheEntry(
        key: key,
        data: compressedData,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(ttl),
        size: compressedData.length,
        accessCount: 0,
        lastAccessed: DateTime.now(),
      );

      // Store in memory cache
      _memoryCache[cacheKey] = entry;

      // Store in persistent cache
      await _storePersistentCache(cacheKey, entry);

      // Update cache size
      _currentCacheSize += entry.size;

      // Set expiration timer
      _setExpirationTimer(cacheKey, ttl);

      // Check cache size limits
      await _enforceMaxCacheSize();

      AppLogger.info('💾 Cached data for key: $key (${entry.size} bytes)');
    } catch (e) {
      AppLogger.error('❌ Error caching data for key $key: $e');
    }
  }

  /// Retrieve data from cache
  Future<T?> get<T>(String key) async {
    final cacheKey = _generateCacheKey(key);

    try {
      // Check memory cache first
      CacheEntry? entry = _memoryCache[cacheKey];

      // If not in memory, check persistent cache
      if (entry == null) {
        entry = await _loadPersistentCache(cacheKey);
        if (entry != null) {
          _memoryCache[cacheKey] = entry;
        }
      }

      if (entry == null) {
        return null;
      }

      // Check if expired
      if (entry.expiresAt.isBefore(DateTime.now())) {
        await remove(key);
        return null;
      }

      // Update access statistics
      entry.accessCount++;
      entry.lastAccessed = DateTime.now();

      // Decompress and deserialize data
      final decompressedData = await _decompressData(entry.data);
      final deserializedData = _deserializeData(decompressedData);

      AppLogger.info('💾 Cache hit for key: $key');
      return deserializedData as T?;
    } catch (e) {
      AppLogger.error('❌ Error retrieving cached data for key $key: $e');
      return null;
    }
  }

  /// Remove data from cache
  Future<void> remove(String key) async {
    final cacheKey = _generateCacheKey(key);

    try {
      // Remove from memory cache
      final entry = _memoryCache.remove(cacheKey);
      if (entry != null) {
        _currentCacheSize -= entry.size;
      }

      // Remove from persistent cache
      await _prefs?.remove(cacheKey);
      await _prefs?.remove('$_cacheMetadataPrefix$cacheKey');

      // Cancel expiration timer
      _expirationTimers[cacheKey]?.cancel();
      _expirationTimers.remove(cacheKey);

      AppLogger.info('💾 Removed cached data for key: $key');
    } catch (e) {
      AppLogger.error('❌ Error removing cached data for key $key: $e');
    }
  }

  /// Clear all cache data
  Future<void> clear() async {
    try {
      // Clear memory cache
      _memoryCache.clear();
      _currentCacheSize = 0;

      // Cancel all timers
      for (final timer in _expirationTimers.values) {
        timer.cancel();
      }
      _expirationTimers.clear();

      // Clear persistent cache
      final keys = _prefs?.getKeys() ?? <String>{};
      final cacheKeys = keys.where(
        (key) =>
            key.startsWith(_cachePrefix) ||
            key.startsWith(_cacheMetadataPrefix),
      );

      for (final key in cacheKeys) {
        await _prefs?.remove(key);
      }

      AppLogger.info('💾 Cleared all cache data');
    } catch (e) {
      AppLogger.error('❌ Error clearing cache: $e');
    }
  }

  /// Check if key exists in cache
  Future<bool> contains(String key) async {
    final cacheKey = _generateCacheKey(key);

    // Check memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      final entry = _memoryCache[cacheKey]!;
      return entry.expiresAt.isAfter(DateTime.now());
    }

    // Check persistent cache
    final entry = await _loadPersistentCache(cacheKey);
    if (entry != null) {
      return entry.expiresAt.isAfter(DateTime.now());
    }

    return false;
  }

  /// Get cache statistics
  CacheStatistics getStatistics() {
    final totalEntries = _memoryCache.length;
    final totalSize = _currentCacheSize;
    final hitRate = _calculateHitRate();

    return CacheStatistics(
      totalEntries: totalEntries,
      totalSizeBytes: totalSize,
      maxSizeBytes: _maxCacheSize,
      hitRate: hitRate,
      memoryEntries: _memoryCache.length,
    );
  }

  /// Set maximum cache size
  void setMaxCacheSize(int maxSize) {
    _maxCacheSize = maxSize;
    _enforceMaxCacheSize();
  }

  // Private helper methods

  String _generateCacheKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return '$_cachePrefix${digest.toString()}';
  }

  Uint8List _serializeData(dynamic data) {
    final jsonString = jsonEncode(data);
    return utf8.encode(jsonString);
  }

  dynamic _deserializeData(Uint8List data) {
    final jsonString = utf8.decode(data);
    return jsonDecode(jsonString);
  }

  Future<Uint8List> _compressData(Uint8List data) async {
    // Simple compression simulation
    // In a real implementation, you'd use gzip or similar
    return data;
  }

  Future<Uint8List> _decompressData(Uint8List data) async {
    // Simple decompression simulation
    return data;
  }

  Future<void> _storePersistentCache(String cacheKey, CacheEntry entry) async {
    try {
      // Store data
      final dataString = base64Encode(entry.data);
      await _prefs?.setString(cacheKey, dataString);

      // Store metadata
      final metadata = {
        'key': entry.key,
        'createdAt': entry.createdAt.toIso8601String(),
        'expiresAt': entry.expiresAt.toIso8601String(),
        'size': entry.size,
        'accessCount': entry.accessCount,
        'lastAccessed': entry.lastAccessed.toIso8601String(),
      };

      await _prefs?.setString(
        '$_cacheMetadataPrefix$cacheKey',
        jsonEncode(metadata),
      );
    } catch (e) {
      AppLogger.error('❌ Error storing persistent cache: $e');
    }
  }

  Future<CacheEntry?> _loadPersistentCache(String cacheKey) async {
    try {
      // Load data
      final dataString = _prefs?.getString(cacheKey);
      if (dataString == null) return null;

      // Load metadata
      final metadataString = _prefs?.getString(
        '$_cacheMetadataPrefix$cacheKey',
      );
      if (metadataString == null) return null;

      final metadata = jsonDecode(metadataString);
      final data = base64Decode(dataString);

      return CacheEntry(
        key: metadata['key'],
        data: data,
        createdAt: DateTime.parse(metadata['createdAt']),
        expiresAt: DateTime.parse(metadata['expiresAt']),
        size: metadata['size'],
        accessCount: metadata['accessCount'],
        lastAccessed: DateTime.parse(metadata['lastAccessed']),
      );
    } catch (e) {
      AppLogger.error('❌ Error loading persistent cache: $e');
      return null;
    }
  }

  Future<void> _loadCacheMetadata() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      final metadataKeys = keys.where(
        (key) => key.startsWith(_cacheMetadataPrefix),
      );

      for (final metadataKey in metadataKeys) {
        final cacheKey = metadataKey.substring(_cacheMetadataPrefix.length);
        final entry = await _loadPersistentCache(cacheKey);

        if (entry != null) {
          // Check if expired
          if (entry.expiresAt.isBefore(DateTime.now())) {
            await _prefs?.remove(cacheKey);
            await _prefs?.remove(metadataKey);
          } else {
            _currentCacheSize += entry.size;
          }
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error loading cache metadata: $e');
    }
  }

  void _setExpirationTimer(String cacheKey, Duration ttl) {
    _expirationTimers[cacheKey]?.cancel();
    _expirationTimers[cacheKey] = Timer(ttl, () async {
      final entry = _memoryCache[cacheKey];
      if (entry != null) {
        await remove(entry.key);
      }
    });
  }

  void _startCacheCleanup() {
    Timer.periodic(Duration(minutes: 30), (_) async {
      await _cleanupExpiredEntries();
    });
  }

  Future<void> _cleanupExpiredEntries() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _memoryCache.entries) {
      if (entry.value.expiresAt.isBefore(now)) {
        expiredKeys.add(entry.value.key);
      }
    }

    for (final key in expiredKeys) {
      await remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.info(
        '💾 Cleaned up ${expiredKeys.length} expired cache entries',
      );
    }
  }

  Future<void> _enforceMaxCacheSize() async {
    if (_currentCacheSize <= _maxCacheSize) return;

    // Sort entries by last accessed time (LRU)
    final entries = _memoryCache.entries.toList();
    entries.sort(
      (a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed),
    );

    // Remove oldest entries until under limit
    while (_currentCacheSize > _maxCacheSize && entries.isNotEmpty) {
      final oldestEntry = entries.removeAt(0);
      await remove(oldestEntry.value.key);
    }

    AppLogger.info(
      '💾 Enforced cache size limit, current size: $_currentCacheSize bytes',
    );
  }

  double _calculateHitRate() {
    if (_memoryCache.isEmpty) return 0.0;

    final totalAccesses = _memoryCache.values
        .map((entry) => entry.accessCount)
        .fold(0, (sum, count) => sum + count);

    if (totalAccesses == 0) return 0.0;

    return _memoryCache.length / totalAccesses;
  }

  /// Dispose resources
  void dispose() {
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();
    _memoryCache.clear();
  }
}

/// Cache entry data structure
class CacheEntry {
  final String key;
  final Uint8List data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int size;
  int accessCount;
  DateTime lastAccessed;

  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    required this.size,
    required this.accessCount,
    required this.lastAccessed,
  });
}

/// Cache statistics
class CacheStatistics {
  final int totalEntries;
  final int totalSizeBytes;
  final int maxSizeBytes;
  final double hitRate;
  final int memoryEntries;

  CacheStatistics({
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.maxSizeBytes,
    required this.hitRate,
    required this.memoryEntries,
  });

  double get utilizationPercentage => (totalSizeBytes / maxSizeBytes) * 100;
}
