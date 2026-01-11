import 'package:flutter/foundation.dart';

/// AIVONITY Offline Sync Service
/// Simplified offline synchronization without external dependencies
class OfflineSyncService extends ChangeNotifier {
  static OfflineSyncService? _instance;
  static OfflineSyncService get instance =>
      _instance ??= OfflineSyncService._();

  OfflineSyncService._();

  bool _isOnline = true;
  bool _isSyncing = false;
  final List<SyncItem> _pendingSync = [];
  final Map<String, dynamic> _offlineData = {};
  DateTime? _lastSyncTime;

  /// Initialize offline sync service
  static Future<void> initialize() async {
    try {
      await instance._initializeService();
      debugPrint('Offline sync service initialized');
    } catch (e) {
      debugPrint('Failed to initialize offline sync service: $e');
    }
  }

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  List<SyncItem> get pendingSync => List.unmodifiable(_pendingSync);
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingSyncCount => _pendingSync.length;

  Future<void> _initializeService() async {
    // Simulate initialization
    await Future.delayed(const Duration(milliseconds: 300));

    // Start connectivity monitoring
    _startConnectivityMonitoring();

    // Load pending sync items
    await _loadPendingSyncItems();
  }

  /// Start monitoring connectivity
  void _startConnectivityMonitoring() {
    // Simulate connectivity changes
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _simulateConnectivityChange();
      }
    });
  }

  void _simulateConnectivityChange() {
    // Randomly simulate connectivity changes for demo
    final wasOnline = _isOnline;
    _isOnline = DateTime.now().millisecond % 2 == 0;

    if (wasOnline != _isOnline) {
      notifyListeners();

      if (_isOnline && _pendingSync.isNotEmpty) {
        _syncPendingItems();
      }
    }

    // Schedule next check
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _simulateConnectivityChange();
      }
    });
  }

  /// Add item to sync queue
  Future<void> addToSyncQueue(SyncItem item) async {
    try {
      _pendingSync.add(item);
      await _savePendingSyncItems();
      notifyListeners();

      // Try to sync immediately if online
      if (_isOnline && !_isSyncing) {
        await _syncPendingItems();
      }
    } catch (e) {
      debugPrint('Failed to add item to sync queue: $e');
    }
  }

  /// Store data for offline use
  Future<void> storeOfflineData(String key, dynamic data) async {
    try {
      _offlineData[key] = data;
      await _saveOfflineData();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to store offline data: $e');
    }
  }

  /// Retrieve offline data
  T? getOfflineData<T>(String key) {
    try {
      final data = _offlineData[key];
      if (data is T) {
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to retrieve offline data: $e');
      return null;
    }
  }

  /// Sync pending items
  Future<void> _syncPendingItems() async {
    if (!_isOnline || _isSyncing || _pendingSync.isEmpty) {
      return;
    }

    try {
      _isSyncing = true;
      notifyListeners();

      final itemsToSync = List<SyncItem>.from(_pendingSync);
      final successfulSyncs = <SyncItem>[];

      for (final item in itemsToSync) {
        try {
          final success = await _syncItem(item);
          if (success) {
            successfulSyncs.add(item);
          }
        } catch (e) {
          debugPrint('Failed to sync item ${item.id}: $e');
        }
      }

      // Remove successfully synced items
      for (final item in successfulSyncs) {
        _pendingSync.remove(item);
      }

      if (successfulSyncs.isNotEmpty) {
        _lastSyncTime = DateTime.now();
        await _savePendingSyncItems();
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      debugPrint('Failed to sync pending items: $e');
    }
  }

  /// Sync individual item
  Future<bool> _syncItem(SyncItem item) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate success/failure (90% success rate)
      final success = DateTime.now().millisecond % 10 != 0;

      if (success) {
        debugPrint('Successfully synced ${item.type} item: ${item.id}');
      } else {
        debugPrint('Failed to sync ${item.type} item: ${item.id}');
      }

      return success;
    } catch (e) {
      debugPrint('Error syncing item ${item.id}: $e');
      return false;
    }
  }

  /// Force sync all pending items
  Future<void> forceSyncAll() async {
    if (_pendingSync.isEmpty) return;

    await _syncPendingItems();
  }

  /// Clear sync queue
  Future<void> clearSyncQueue() async {
    try {
      _pendingSync.clear();
      await _savePendingSyncItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear sync queue: $e');
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    final typeCount = <String, int>{};
    for (final item in _pendingSync) {
      typeCount[item.type.name] = (typeCount[item.type.name] ?? 0) + 1;
    }

    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'pendingCount': _pendingSync.length,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'typeBreakdown': typeCount,
    };
  }

  /// Save pending sync items (simulate persistence)
  Future<void> _savePendingSyncItems() async {
    // In a real implementation, this would save to local storage
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Load pending sync items (simulate persistence)
  Future<void> _loadPendingSyncItems() async {
    // In a real implementation, this would load from local storage
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Save offline data (simulate persistence)
  Future<void> _saveOfflineData() async {
    // In a real implementation, this would save to local storage
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Check if mounted (for timer cleanup)
  bool get mounted => true; // Simplified for demo
}

/// Sync Item Model
class SyncItem {
  final String id;
  final SyncType type;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  const SyncItem({
    required this.id,
    required this.type,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  SyncItem copyWith({
    String? id,
    SyncType? type,
    SyncOperation? operation,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncItem(
      id: id ?? this.id,
      type: type ?? this.type,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  String toString() {
    return 'SyncItem(id: $id, type: ${type.name}, operation: ${operation.name})';
  }
}

/// Sync Type Enum
enum SyncType {
  booking,
  telemetry,
  userProfile,
  vehicleData,
  chatMessage,
  settings,
}

/// Sync Operation Enum
enum SyncOperation { create, update, delete }

/// Connectivity Status Enum
enum ConnectivityStatus { online, offline, unknown }

