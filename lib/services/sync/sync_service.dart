import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../caching/cache_service.dart';
import 'conflict_resolver.dart';
import 'sync_status.dart';

/// Data synchronization service with conflict resolution
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final CacheService _cache = CacheService();
  final ConflictResolver _conflictResolver = ConflictResolver();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  int _pendingItems = 0;
  String? _lastError;

  // Getters
  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingItems => _pendingItems;
  String? get lastError => _lastError;
  bool get isOnline => _connectivityResult != ConnectivityResult.none;

  ConnectivityResult _connectivityResult = ConnectivityResult.none;

  /// Initialize sync service
  Future<void> initialize() async {
    await _checkConnectivity();
    _startConnectivityMonitoring();
    _startPeriodicSync();
    await _updatePendingItemsCount();
  }

  /// Start manual sync
  Future<SyncResult> sync({bool force = false}) async {
    if (_status == SyncStatus.syncing && !force) {
      return SyncResult.alreadyInProgress();
    }

    _updateStatus(SyncStatus.syncing);

    try {
      final result = await _performSync();
      _updateStatus(SyncStatus.idle);
      _lastSyncTime = DateTime.now();
      _lastError = null;
      await _updatePendingItemsCount();

      return result;
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(SyncStatus.error);
      debugPrint('Sync failed: $e');
      return SyncResult.error(e.toString());
    }
  }

  /// Add item to sync queue
  Future<void> queueForSync({
    required String operationType,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
    int priority = 1,
  }) async {
    await _db.addToSyncQueue(
      operationType: operationType,
      tableName: tableName,
      recordId: recordId,
      data: data,
      priority: priority,
    );

    await _updatePendingItemsCount();

    // Trigger immediate sync for high priority items
    if (priority >= 3 && isOnline) {
      unawaited(_performIncrementalSync());
    }
  }

  /// Force sync of specific item
  Future<SyncResult> syncItem(String recordId) async {
    try {
      final items = await _db.getPendingSyncItems();
      final item = items.where((i) => i['record_id'] == recordId).firstOrNull;

      if (item == null) {
        return SyncResult.error('Item not found in sync queue');
      }

      final success = await _syncSingleItem(item);
      if (success) {
        await _db.removeSyncItem(item['id'] as int);
        await _updatePendingItemsCount();
        return SyncResult.success(itemsSynced: 1);
      } else {
        return SyncResult.error('Failed to sync item');
      }
    } catch (e) {
      return SyncResult.error(e.toString());
    }
  }

  /// Clear sync queue
  Future<void> clearSyncQueue() async {
    // This would clear the sync_queue table
    // Implementation depends on specific requirements
  }

  /// Get sync statistics
  Future<SyncStatistics> getStatistics() async {
    final pendingItems = await _db.getPendingSyncItems();
    final failedItems = pendingItems
        .where((item) => (item['retry_count'] as int? ?? 0) > 0)
        .length;

    return SyncStatistics(
      totalPendingItems: pendingItems.length,
      failedItems: failedItems,
      lastSyncTime: _lastSyncTime,
      lastError: _lastError,
      isOnline: isOnline,
      status: _status,
    );
  }

  // Private methods

  Future<void> _checkConnectivity() async {
    _connectivityResult = await Connectivity().checkConnectivity();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      final wasOnline = _connectivityResult != ConnectivityResult.none;
      _connectivityResult = result;
      final isNowOnline = result != ConnectivityResult.none;

      if (!wasOnline && isNowOnline) {
        // Just came online, trigger sync
        unawaited(_performIncrementalSync());
      }

      notifyListeners();
    });
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (isOnline && _status != SyncStatus.syncing) {
        unawaited(_performIncrementalSync());
      }
    });
  }

  Future<SyncResult> _performSync() async {
    if (!isOnline) {
      return SyncResult.error('No internet connection');
    }

    final pendingItems = await _db.getPendingSyncItems();
    if (pendingItems.isEmpty) {
      return SyncResult.success(itemsSynced: 0);
    }

    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    for (final item in pendingItems) {
      try {
        final success = await _syncSingleItem(item);
        if (success) {
          await _db.removeSyncItem(item['id'] as int);
          successCount++;
        } else {
          await _db.updateSyncItemRetry(
            item['id'] as int,
            'Sync failed for unknown reason',
          );
          failureCount++;
        }
      } catch (e) {
        await _db.updateSyncItemRetry(item['id'] as int, e.toString());
        failureCount++;
        errors.add(e.toString());
      }
    }

    if (failureCount > 0) {
      return SyncResult.partialSuccess(
        itemsSynced: successCount,
        itemsFailed: failureCount,
        errors: errors,
      );
    }

    return SyncResult.success(itemsSynced: successCount);
  }

  Future<void> _performIncrementalSync() async {
    if (_status == SyncStatus.syncing || !isOnline) return;

    _updateStatus(SyncStatus.syncing);

    try {
      // Sync only high priority items for incremental sync
      final highPriorityItems = await _db.getPendingSyncItems(limit: 10);
      final priorityItems = highPriorityItems
          .where((item) => (item['priority'] as int? ?? 1) >= 2)
          .toList();

      for (final item in priorityItems) {
        try {
          final success = await _syncSingleItem(item);
          if (success) {
            await _db.removeSyncItem(item['id'] as int);
          }
        } catch (e) {
          await _db.updateSyncItemRetry(item['id'] as int, e.toString());
        }
      }

      await _updatePendingItemsCount();
    } finally {
      _updateStatus(SyncStatus.idle);
    }
  }

  Future<bool> _syncSingleItem(Map<String, dynamic> item) async {
    final operationType = item['operation_type'] as String;
    final tableName = item['table_name'] as String;
    final recordId = item['record_id'] as String;
    final data =
        json.decode(item['data_json'] as String) as Map<String, dynamic>;

    switch (operationType) {
      case 'CREATE':
        return await _syncCreate(tableName, recordId, data);
      case 'UPDATE':
        return await _syncUpdate(tableName, recordId, data);
      case 'DELETE':
        return await _syncDelete(tableName, recordId);
      default:
        debugPrint('Unknown operation type: $operationType');
        return false;
    }
  }

  Future<bool> _syncCreate(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    try {
      // This would make an API call to create the record on the server
      // For now, we'll simulate success
      await Future.delayed(const Duration(milliseconds: 100));

      // Check for conflicts
      final conflict = await _checkForConflicts(tableName, recordId, data);
      if (conflict != null) {
        final resolution = await _conflictResolver.resolve(conflict);
        return await _applyResolution(resolution);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to sync create for $tableName:$recordId: $e');
      return false;
    }
  }

  Future<bool> _syncUpdate(
    String tableName,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    try {
      // This would make an API call to update the record on the server
      await Future.delayed(const Duration(milliseconds: 100));

      // Check for conflicts
      final conflict = await _checkForConflicts(tableName, recordId, data);
      if (conflict != null) {
        final resolution = await _conflictResolver.resolve(conflict);
        return await _applyResolution(resolution);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to sync update for $tableName:$recordId: $e');
      return false;
    }
  }

  Future<bool> _syncDelete(String tableName, String recordId) async {
    try {
      // This would make an API call to delete the record on the server
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      debugPrint('Failed to sync delete for $tableName:$recordId: $e');
      return false;
    }
  }

  Future<SyncConflict?> _checkForConflicts(
    String tableName,
    String recordId,
    Map<String, dynamic> localData,
  ) async {
    // This would fetch the server version and compare
    // For now, we'll simulate no conflicts
    return null;
  }

  Future<bool> _applyResolution(ConflictResolution resolution) async {
    switch (resolution.strategy) {
      case ResolutionStrategy.useLocal:
        // Keep local version, sync to server
        return true;
      case ResolutionStrategy.useRemote:
        // Use server version, update local
        return true;
      case ResolutionStrategy.merge:
        // Apply merged data
        return true;
      case ResolutionStrategy.manual:
        // Requires user intervention
        return false;
    }
  }

  void _updateStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  Future<void> _updatePendingItemsCount() async {
    final items = await _db.getPendingSyncItems();
    _pendingItems = items.length;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int itemsSynced;
  final int itemsFailed;
  final List<String> errors;
  final String? message;

  SyncResult._({
    required this.success,
    required this.itemsSynced,
    required this.itemsFailed,
    required this.errors,
    this.message,
  });

  factory SyncResult.success({required int itemsSynced}) {
    return SyncResult._(
      success: true,
      itemsSynced: itemsSynced,
      itemsFailed: 0,
      errors: [],
      message: itemsSynced > 0
          ? 'Synced $itemsSynced items'
          : 'Nothing to sync',
    );
  }

  factory SyncResult.error(String error) {
    return SyncResult._(
      success: false,
      itemsSynced: 0,
      itemsFailed: 1,
      errors: [error],
      message: error,
    );
  }

  factory SyncResult.partialSuccess({
    required int itemsSynced,
    required int itemsFailed,
    required List<String> errors,
  }) {
    return SyncResult._(
      success: false,
      itemsSynced: itemsSynced,
      itemsFailed: itemsFailed,
      errors: errors,
      message: 'Synced $itemsSynced items, $itemsFailed failed',
    );
  }

  factory SyncResult.alreadyInProgress() {
    return SyncResult._(
      success: false,
      itemsSynced: 0,
      itemsFailed: 0,
      errors: [],
      message: 'Sync already in progress',
    );
  }
}

/// Sync statistics
class SyncStatistics {
  final int totalPendingItems;
  final int failedItems;
  final DateTime? lastSyncTime;
  final String? lastError;
  final bool isOnline;
  final SyncStatus status;

  SyncStatistics({
    required this.totalPendingItems,
    required this.failedItems,
    required this.lastSyncTime,
    required this.lastError,
    required this.isOnline,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_pending_items': totalPendingItems,
      'failed_items': failedItems,
      'last_sync_time': lastSyncTime?.toIso8601String(),
      'last_error': lastError,
      'is_online': isOnline,
      'status': status.toString(),
    };
  }
}

// Extension to add firstOrNull method
extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// Helper function for unawaited futures
void unawaited(Future<void> future) {
  // Intentionally not awaiting
}

