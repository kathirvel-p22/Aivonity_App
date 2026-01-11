import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../caching/cache_service.dart';
import '../sync/sync_service.dart';

/// Manager for offline functionality across the app
class OfflineManager extends ChangeNotifier {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final CacheService _cache = CacheService();
  final SyncService _sync = SyncService();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;

  bool _isInitialized = false;
  final Map<String, OfflineCapability> _offlineCapabilities = {};

  // Getters
  bool get isOnline => _connectivityResult != ConnectivityResult.none;
  bool get isOffline => !isOnline;
  bool get isInitialized => _isInitialized;

  ConnectivityResult get connectivityResult => _connectivityResult;

  /// Initialize offline manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _setupOfflineCapabilities();
    await _checkConnectivity();
    _startConnectivityMonitoring();

    _isInitialized = true;
    notifyListeners();
  }

  /// Setup offline capabilities for different features
  Future<void> _setupOfflineCapabilities() async {
    // Vehicle data viewing
    _offlineCapabilities['vehicle_data'] = OfflineCapability(
      featureName: 'Vehicle Data',
      isAvailableOffline: true,
      cacheDuration: const Duration(hours: 24),
      syncPriority: 3,
      offlineActions: ['view', 'export'],
    );

    // Chat functionality
    _offlineCapabilities['chat'] = OfflineCapability(
      featureName: 'AI Chat',
      isAvailableOffline: true,
      cacheDuration: const Duration(days: 7),
      syncPriority: 2,
      offlineActions: ['view_history', 'compose'],
    );

    // Service centers
    _offlineCapabilities['service_centers'] = OfflineCapability(
      featureName: 'Service Centers',
      isAvailableOffline: true,
      cacheDuration: const Duration(days: 14),
      syncPriority: 1,
      offlineActions: ['view', 'search', 'get_directions'],
    );

    // Reports
    _offlineCapabilities['reports'] = OfflineCapability(
      featureName: 'Reports',
      isAvailableOffline: true,
      cacheDuration: const Duration(days: 30),
      syncPriority: 2,
      offlineActions: ['view', 'export'],
    );

    // Analytics
    _offlineCapabilities['analytics'] = OfflineCapability(
      featureName: 'Analytics',
      isAvailableOffline: true,
      cacheDuration: const Duration(hours: 12),
      syncPriority: 2,
      offlineActions: ['view'],
    );
  }

  /// Check if a feature is available offline
  bool isFeatureAvailableOffline(String featureName) {
    final capability = _offlineCapabilities[featureName];
    return capability?.isAvailableOffline ?? false;
  }

  /// Check if a specific action is available offline for a feature
  bool isActionAvailableOffline(String featureName, String action) {
    final capability = _offlineCapabilities[featureName];
    return capability?.offlineActions.contains(action) ?? false;
  }

  /// Get offline vehicle data
  Future<List<Map<String, dynamic>>> getOfflineVehicleData({
    required String vehicleId,
    String? dataType,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    return await _db.getVehicleData(
      vehicleId: vehicleId,
      dataType: dataType,
      startTime: startTime,
      endTime: endTime,
      limit: limit,
    );
  }

  /// Store vehicle data for offline access
  Future<void> storeVehicleDataOffline(Map<String, dynamic> data) async {
    await _db.insertVehicleData(data);

    // Queue for sync when online
    if (isOffline) {
      await _sync.queueForSync(
        operationType: 'CREATE',
        tableName: 'vehicle_data',
        recordId:
            data['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        data: data,
        priority: 3,
      );
    }
  }

  /// Get offline chat messages
  Future<List<Map<String, dynamic>>> getOfflineChatMessages({
    required String conversationId,
    int? limit,
    int? offset,
  }) async {
    return await _db.getChatMessages(
      conversationId: conversationId,
      limit: limit,
      offset: offset,
    );
  }

  /// Store chat message for offline access
  Future<void> storeChatMessageOffline(Map<String, dynamic> message) async {
    await _db.insertChatMessage(message);

    // Queue for sync when online
    if (isOffline) {
      await _sync.queueForSync(
        operationType: 'CREATE',
        tableName: 'chat_messages',
        recordId:
            message['message_id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        data: message,
        priority: 2,
      );
    }
  }

  /// Get offline service centers
  Future<List<Map<String, dynamic>>> getOfflineServiceCenters({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    return await _db.getCachedServiceCenters(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  /// Cache service centers for offline access
  Future<void> cacheServiceCentersOffline(
    List<Map<String, dynamic>> centers,
  ) async {
    await _db.cacheServiceCenters(centers);
  }

  /// Create offline report
  Future<Map<String, dynamic>> createOfflineReport({
    required String vehicleId,
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Get cached vehicle data for the date range
    final vehicleData = await getOfflineVehicleData(
      vehicleId: vehicleId,
      startTime: startDate,
      endTime: endDate,
    );

    // Generate report from cached data
    final report = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'vehicle_id': vehicleId,
      'report_type': reportType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'generated_at': DateTime.now().toIso8601String(),
      'data_points': vehicleData.length,
      'is_offline_generated': true,
      'summary': _generateReportSummary(vehicleData, reportType),
    };

    // Store report for later sync
    await _sync.queueForSync(
      operationType: 'CREATE',
      tableName: 'reports',
      recordId: report['id'] as String,
      data: report,
      priority: 2,
    );

    return report;
  }

  /// Preload data for offline use
  Future<void> preloadDataForOffline({
    required String vehicleId,
    List<String> features = const ['vehicle_data', 'service_centers', 'chat'],
  }) async {
    for (final feature in features) {
      switch (feature) {
        case 'vehicle_data':
          await _preloadVehicleData(vehicleId);
          break;
        case 'service_centers':
          await _preloadServiceCenters();
          break;
        case 'chat':
          await _preloadChatHistory();
          break;
      }
    }
  }

  /// Get offline capability status
  OfflineStatus getOfflineStatus() {
    final capabilities = _offlineCapabilities.values.toList();
    final availableFeatures = capabilities
        .where((c) => c.isAvailableOffline)
        .length;

    return OfflineStatus(
      isOnline: isOnline,
      totalFeatures: capabilities.length,
      availableOfflineFeatures: availableFeatures,
      lastDataUpdate: DateTime.now(), // This would be tracked properly
      cacheSize: 0, // This would be calculated from database
      capabilities: Map.fromEntries(
        _offlineCapabilities.entries.map((e) => MapEntry(e.key, e.value)),
      ),
    );
  }

  /// Clear offline data
  Future<void> clearOfflineData({List<String>? features}) async {
    if (features == null) {
      // Clear all offline data
      await _db.clearAllData();
    } else {
      // Clear specific features
      for (final feature in features) {
        await _cache.clearCategory(feature);
      }
    }

    notifyListeners();
  }

  // Private methods

  Future<void> _checkConnectivity() async {
    _connectivityResult = await Connectivity().checkConnectivity();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      final wasOffline = _connectivityResult == ConnectivityResult.none;
      _connectivityResult = result;
      final isNowOnline = result != ConnectivityResult.none;

      if (wasOffline && isNowOnline) {
        _onConnectivityRestored();
      } else if (!wasOffline && !isNowOnline) {
        _onConnectivityLost();
      }

      notifyListeners();
    });
  }

  void _onConnectivityRestored() {
    debugPrint('Connectivity restored - triggering sync');
    // Trigger sync when connectivity is restored
    _sync.sync();
  }

  void _onConnectivityLost() {
    debugPrint('Connectivity lost - switching to offline mode');
    // Could show offline indicator or cache critical data
  }

  Future<void> _preloadVehicleData(String vehicleId) async {
    // This would fetch recent vehicle data and cache it
    // For now, we'll simulate with existing data
    final recentData = await _db.getVehicleData(
      vehicleId: vehicleId,
      limit: 1000,
    );

    debugPrint('Preloaded ${recentData.length} vehicle data records');
  }

  Future<void> _preloadServiceCenters() async {
    // This would fetch service centers and cache them
    final cachedCenters = await _db.getCachedServiceCenters();
    debugPrint('Preloaded ${cachedCenters.length} service centers');
  }

  Future<void> _preloadChatHistory() async {
    // This would fetch recent chat messages
    final messages = await _db.getChatMessages(
      conversationId: 'default',
      limit: 500,
    );

    debugPrint('Preloaded ${messages.length} chat messages');
  }

  Map<String, dynamic> _generateReportSummary(
    List<Map<String, dynamic>> data,
    String reportType,
  ) {
    if (data.isEmpty) {
      return {'message': 'No data available for the selected period'};
    }

    switch (reportType) {
      case 'performance':
        return {
          'total_records': data.length,
          'date_range':
              '${data.last['timestamp']} - ${data.first['timestamp']}',
          'avg_performance': 'Calculated from cached data',
        };
      case 'maintenance':
        return {
          'total_records': data.length,
          'maintenance_alerts': 0, // Would be calculated
          'next_service_due': 'Based on cached data',
        };
      default:
        return {
          'total_records': data.length,
          'summary': 'Generated from offline data',
        };
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Offline capability configuration
class OfflineCapability {
  final String featureName;
  final bool isAvailableOffline;
  final Duration cacheDuration;
  final int syncPriority;
  final List<String> offlineActions;

  OfflineCapability({
    required this.featureName,
    required this.isAvailableOffline,
    required this.cacheDuration,
    required this.syncPriority,
    required this.offlineActions,
  });

  Map<String, dynamic> toJson() {
    return {
      'feature_name': featureName,
      'is_available_offline': isAvailableOffline,
      'cache_duration_ms': cacheDuration.inMilliseconds,
      'sync_priority': syncPriority,
      'offline_actions': offlineActions,
    };
  }
}

/// Offline status information
class OfflineStatus {
  final bool isOnline;
  final int totalFeatures;
  final int availableOfflineFeatures;
  final DateTime lastDataUpdate;
  final int cacheSize;
  final Map<String, OfflineCapability> capabilities;

  OfflineStatus({
    required this.isOnline,
    required this.totalFeatures,
    required this.availableOfflineFeatures,
    required this.lastDataUpdate,
    required this.cacheSize,
    required this.capabilities,
  });

  double get offlineAvailabilityPercentage =>
      totalFeatures > 0 ? availableOfflineFeatures / totalFeatures : 0.0;

  String get formattedCacheSize {
    if (cacheSize < 1024) return '${cacheSize}B';
    if (cacheSize < 1024 * 1024) {
      return '${(cacheSize / 1024).toStringAsFixed(1)}KB';
    }
    return '${(cacheSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'is_online': isOnline,
      'total_features': totalFeatures,
      'available_offline_features': availableOfflineFeatures,
      'last_data_update': lastDataUpdate.toIso8601String(),
      'cache_size': cacheSize,
      'offline_availability_percentage': offlineAvailabilityPercentage,
      'capabilities': capabilities.map((k, v) => MapEntry(k, v.toJson())),
    };
  }
}

