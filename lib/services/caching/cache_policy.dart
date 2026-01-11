/// Cache policy configuration for different data types
class CachePolicy {
  /// Time-to-live for cached data
  final Duration ttl;

  /// Maximum number of items to keep in memory cache
  final int maxMemoryItems;

  /// Whether to compress data before storing
  final bool compressionEnabled;

  /// Strategy for syncing data when online
  final SyncStrategy syncStrategy;

  /// Priority level for cache eviction (higher = keep longer)
  final int priority;

  /// Whether this data should be preloaded on app start
  final bool preloadOnStart;

  const CachePolicy({
    required this.ttl,
    this.maxMemoryItems = 100,
    this.compressionEnabled = false,
    this.syncStrategy = SyncStrategy.background,
    this.priority = 1,
    this.preloadOnStart = false,
  });

  /// Policy for real-time telemetry data
  static const telemetry = CachePolicy(
    ttl: Duration(minutes: 5),
    maxMemoryItems: 200,
    compressionEnabled: true,
    syncStrategy: SyncStrategy.immediate,
    priority: 3,
    preloadOnStart: true,
  );

  /// Policy for service center data
  static const serviceCenters = CachePolicy(
    ttl: Duration(days: 7),
    maxMemoryItems: 50,
    compressionEnabled: false,
    syncStrategy: SyncStrategy.background,
    priority: 2,
    preloadOnStart: true,
  );

  /// Policy for user settings
  static const userSettings = CachePolicy(
    ttl: Duration(days: 30),
    maxMemoryItems: 20,
    compressionEnabled: false,
    syncStrategy: SyncStrategy.immediate,
    priority: 5,
    preloadOnStart: true,
  );

  /// Policy for API responses
  static const apiResponses = CachePolicy(
    ttl: Duration(hours: 1),
    maxMemoryItems: 300,
    compressionEnabled: true,
    syncStrategy: SyncStrategy.conditional,
    priority: 2,
  );

  /// Policy for chat messages
  static const chatMessages = CachePolicy(
    ttl: Duration(days: 30),
    maxMemoryItems: 1000,
    compressionEnabled: true,
    syncStrategy: SyncStrategy.background,
    priority: 4,
    preloadOnStart: false,
  );

  /// Policy for analytics data
  static const analytics = CachePolicy(
    ttl: Duration(hours: 6),
    maxMemoryItems: 100,
    compressionEnabled: true,
    syncStrategy: SyncStrategy.background,
    priority: 1,
  );

  /// Policy for map tiles and location data
  static const mapData = CachePolicy(
    ttl: Duration(days: 14),
    maxMemoryItems: 50,
    compressionEnabled: false,
    syncStrategy: SyncStrategy.background,
    priority: 2,
  );

  /// Policy for vehicle reports
  static const reports = CachePolicy(
    ttl: Duration(days: 7),
    maxMemoryItems: 30,
    compressionEnabled: true,
    syncStrategy: SyncStrategy.background,
    priority: 3,
  );
}

/// Synchronization strategy for cached data
enum SyncStrategy {
  /// Sync immediately when online
  immediate,

  /// Sync in background when convenient
  background,

  /// Sync only if data has changed (using ETags, etc.)
  conditional,

  /// Never sync automatically (manual only)
  manual,

  /// Sync on app startup
  onStartup,
}

/// Cache eviction strategy
enum EvictionStrategy {
  /// Least Recently Used
  lru,

  /// Least Frequently Used
  lfu,

  /// First In, First Out
  fifo,

  /// Based on priority and age
  priorityBased,
}

/// Cache compression configuration
class CompressionConfig {
  /// Whether compression is enabled
  final bool enabled;

  /// Compression algorithm to use
  final CompressionAlgorithm algorithm;

  /// Minimum size threshold for compression (bytes)
  final int threshold;

  /// Compression level (1-9, higher = better compression but slower)
  final int level;

  const CompressionConfig({
    this.enabled = false,
    this.algorithm = CompressionAlgorithm.gzip,
    this.threshold = 1024, // 1KB
    this.level = 6,
  });
}

/// Available compression algorithms
enum CompressionAlgorithm { gzip, deflate, brotli }

/// Cache warming configuration
class CacheWarmingConfig {
  /// Categories to preload on app start
  final List<String> preloadCategories;

  /// Maximum time to spend on cache warming
  final Duration maxWarmupTime;

  /// Whether to warm cache in background
  final bool backgroundWarming;

  /// Priority order for warming
  final List<String> priorityOrder;

  const CacheWarmingConfig({
    this.preloadCategories = const [],
    this.maxWarmupTime = const Duration(seconds: 30),
    this.backgroundWarming = true,
    this.priorityOrder = const [],
  });

  /// Default cache warming configuration
  static const defaultConfig = CacheWarmingConfig(
    preloadCategories: ['user_settings', 'telemetry', 'service_centers'],
    maxWarmupTime: Duration(seconds: 15),
    backgroundWarming: true,
    priorityOrder: [
      'user_settings',
      'telemetry',
      'service_centers',
      'chat_messages',
    ],
  );
}

/// Cache metrics and monitoring
class CacheMetrics {
  /// Total cache hits
  int hits = 0;

  /// Total cache misses
  int misses = 0;

  /// Cache hit rate (0.0 to 1.0)
  double get hitRate => (hits + misses) > 0 ? hits / (hits + misses) : 0.0;

  /// Memory cache size in bytes
  int memorySizeBytes = 0;

  /// Database cache size in bytes
  int databaseSizeBytes = 0;

  /// Number of items in memory cache
  int memoryItemCount = 0;

  /// Number of items in database cache
  int databaseItemCount = 0;

  /// Last cleanup timestamp
  DateTime? lastCleanup;

  /// Average response time for cache operations
  Duration averageResponseTime = Duration.zero;

  void recordHit() => hits++;
  void recordMiss() => misses++;

  void reset() {
    hits = 0;
    misses = 0;
    memorySizeBytes = 0;
    memoryItemCount = 0;
    averageResponseTime = Duration.zero;
  }

  Map<String, dynamic> toJson() {
    return {
      'hits': hits,
      'misses': misses,
      'hit_rate': hitRate,
      'memory_size_bytes': memorySizeBytes,
      'database_size_bytes': databaseSizeBytes,
      'memory_item_count': memoryItemCount,
      'database_item_count': databaseItemCount,
      'last_cleanup': lastCleanup?.toIso8601String(),
      'average_response_time_ms': averageResponseTime.inMilliseconds,
    };
  }
}

