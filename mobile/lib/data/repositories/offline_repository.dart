import 'dart:async';

import '../models/vehicle.dart';
import '../models/telemetry_data.dart';
import '../models/maintenance_prediction.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/utils/logger.dart';

/// Base offline-first repository with automatic sync capabilities
abstract class OfflineRepository<T> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService.instance;
  final OfflineSyncService _syncService = OfflineSyncService.instance;

  /// Table name for offline storage
  String get tableName;

  /// API endpoint for this resource
  String get apiEndpoint;

  /// Convert model to JSON
  Map<String, dynamic> toJson(T model);

  /// Convert JSON to model
  T fromJson(Map<String, dynamic> json);

  /// Get unique identifier for the model
  String getId(T model);

  /// Helper method to get all offline data for a table
  List<Map<String, dynamic>> _getAllOfflineData(String table) {
    final allKeys = _storageService.getAllKeys();
    final tableKeys =
        allKeys.where((key) => key.startsWith('${table}_')).toList();
    final data = <Map<String, dynamic>>[];

    for (final key in tableKeys) {
      final json = _storageService.retrieveJson(key);
      if (json != null) {
        data.add(json);
      }
    }

    return data;
  }

  /// Helper method to get offline data by ID
  Map<String, dynamic>? _getOfflineData({
    required String id,
    required String tableName,
  }) {
    return _storageService.retrieveJson('${tableName}_$id');
  }

  /// Helper method to store offline data
  Future<void> _storeOfflineData({
    required String id,
    required String tableName,
    required Map<String, dynamic> data,
  }) async {
    await _storageService.storeJson('${tableName}_$id', data);
  }

  /// Helper method to queue sync operation
  Future<void> _queueOperation({
    required String operationType,
    required String endpoint,
    required String method,
    Map<String, dynamic>? data,
    int priority = 0,
  }) async {
    final syncItem = SyncItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _getSyncType(operationType),
      operation: _getSyncOperation(method),
      data: data ?? {},
      createdAt: DateTime.now(),
    );

    await _syncService.addToSyncQueue(syncItem);
  }

  /// Helper method to get sync type from operation type
  SyncType _getSyncType(String operationType) {
    if (operationType.contains('vehicle')) return SyncType.vehicleData;
    if (operationType.contains('telemetry')) return SyncType.telemetry;
    return SyncType.vehicleData; // Default
  }

  /// Helper method to get sync operation from HTTP method
  SyncOperation _getSyncOperation(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return SyncOperation.create;
      case 'PUT':
        return SyncOperation.update;
      case 'DELETE':
        return SyncOperation.delete;
      default:
        return SyncOperation.create;
    }
  }

  /// Get all items (offline-first)
  Future<List<T>> getAll({bool forceRefresh = false}) async {
    try {
      // Try to get from cache first
      if (!forceRefresh) {
        final cachedData = _getAllOfflineData(tableName);
        if (cachedData.isNotEmpty) {
          AppLogger.debug('📱 Returning cached data for $tableName');
          return cachedData.map((json) => fromJson(json)).toList();
        }
      }

      // If online, fetch from API
      if (_syncService.isOnline) {
        final response = await _apiService.get<List<dynamic>>(apiEndpoint);

        if (response.isSuccess && response.data != null) {
          final items = (response.data as List)
              .map((json) => fromJson(json as Map<String, dynamic>))
              .toList();

          // Cache the data
          for (final item in items) {
            await _storeOfflineData(
              id: getId(item),
              tableName: tableName,
              data: toJson(item),
            );
          }

          AppLogger.debug(
            '🌐 Fetched and cached ${items.length} items for $tableName',
          );
          return items;
        }
      }

      // Fallback to cached data
      final cachedData = _getAllOfflineData(tableName);
      AppLogger.debug('📱 Fallback to cached data for $tableName');
      return cachedData.map((json) => fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('❌ Failed to get all items for $tableName', e);

      // Return cached data as fallback
      final cachedData = _getAllOfflineData(tableName);
      return cachedData.map((json) => fromJson(json)).toList();
    }
  }

  /// Get item by ID (offline-first)
  Future<T?> getById(String id, {bool forceRefresh = false}) async {
    try {
      // Try cache first
      if (!forceRefresh) {
        final cachedData = _getOfflineData(
          id: id,
          tableName: tableName,
        );
        if (cachedData != null) {
          AppLogger.debug('📱 Returning cached item $id for $tableName');
          return fromJson(cachedData);
        }
      }

      // If online, fetch from API
      if (_syncService.isOnline) {
        final response = await _apiService.get<Map<String, dynamic>>(
          '$apiEndpoint/$id',
        );

        if (response.isSuccess && response.data != null) {
          final item = fromJson(response.data!);

          // Cache the data
          await _storeOfflineData(
            id: id,
            tableName: tableName,
            data: toJson(item),
          );

          AppLogger.debug('🌐 Fetched and cached item $id for $tableName');
          return item;
        }
      }

      // Fallback to cached data
      final cachedData = _getOfflineData(
        id: id,
        tableName: tableName,
      );
      if (cachedData != null) {
        AppLogger.debug('📱 Fallback to cached item $id for $tableName');
        return fromJson(cachedData);
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ Failed to get item $id for $tableName', e);

      // Return cached data as fallback
      final cachedData = _getOfflineData(
        id: id,
        tableName: tableName,
      );
      return cachedData != null ? fromJson(cachedData) : null;
    }
  }

  /// Create item (offline-first)
  Future<T> create(T item) async {
    try {
      final itemId = getId(item);
      final itemData = toJson(item);

      // Store locally first
      await _storeOfflineData(
        id: itemId,
        tableName: tableName,
        data: itemData,
      );

      // Queue for sync
      await _queueOperation(
        operationType: 'create_$tableName',
        endpoint: apiEndpoint,
        method: 'POST',
        data: itemData,
      );

      AppLogger.debug(
        '✅ Created item $itemId for $tableName (queued for sync)',
      );
      return item;
    } catch (e) {
      AppLogger.error('❌ Failed to create item for $tableName', e);
      rethrow;
    }
  }

  /// Update item (offline-first)
  Future<T> update(T item) async {
    try {
      final itemId = getId(item);
      final itemData = toJson(item);

      // Store locally first
      await _storeOfflineData(
        id: itemId,
        tableName: tableName,
        data: itemData,
      );

      // Queue for sync
      await _queueOperation(
        operationType: 'update_$tableName',
        endpoint: '$apiEndpoint/$itemId',
        method: 'PUT',
        data: itemData,
      );

      AppLogger.debug(
        '✅ Updated item $itemId for $tableName (queued for sync)',
      );
      return item;
    } catch (e) {
      AppLogger.error('❌ Failed to update item for $tableName', e);
      rethrow;
    }
  }

  /// Delete item (offline-first)
  Future<void> delete(String id) async {
    try {
      // Remove from local storage
      await _storageService.remove('${tableName}_$id');

      // Queue for sync
      await _queueOperation(
        operationType: 'delete_$tableName',
        endpoint: '$apiEndpoint/$id',
        method: 'DELETE',
      );

      AppLogger.debug('✅ Deleted item $id for $tableName (queued for sync)');
    } catch (e) {
      AppLogger.error('❌ Failed to delete item $id for $tableName', e);
      rethrow;
    }
  }

  /// Force sync with server
  Future<void> sync() async {
    if (!_syncService.isOnline) {
      AppLogger.warning('⚠️ Cannot sync $tableName - device is offline');
      return;
    }

    try {
      AppLogger.info('🔄 Starting sync for $tableName');

      // This would trigger the sync service to process pending operations
      // for this specific table/resource type
      await _syncService.forceSyncAll();

      AppLogger.info('✅ Sync completed for $tableName');
    } catch (e) {
      AppLogger.error('❌ Sync failed for $tableName', e);
      rethrow;
    }
  }
}

/// Vehicle repository with offline capabilities
class VehicleRepository extends OfflineRepository<Vehicle> {
  @override
  String get tableName => 'vehicles';

  @override
  String get apiEndpoint => '/vehicles';

  @override
  Map<String, dynamic> toJson(Vehicle model) => model.toJson();

  @override
  Vehicle fromJson(Map<String, dynamic> json) => Vehicle.fromJson(json);

  @override
  String getId(Vehicle model) => model.id;

  /// Get vehicles for current user
  Future<List<Vehicle>> getUserVehicles(String userId) async {
    final allVehicles = await getAll();
    return allVehicles.where((v) => v.userId == userId).toList();
  }

  /// Update vehicle health score
  Future<Vehicle> updateHealthScore(
    String vehicleId,
    double healthScore,
  ) async {
    final vehicle = await getById(vehicleId);
    if (vehicle == null) {
      throw Exception('Vehicle not found: $vehicleId');
    }

    final updatedVehicle = vehicle.copyWith(
      healthScore: healthScore,
      updatedAt: DateTime.now(),
    );

    return await update(updatedVehicle);
  }
}

/// Telemetry repository with offline capabilities
class TelemetryRepository extends OfflineRepository<TelemetryData> {
  @override
  String get tableName => 'telemetry';

  @override
  String get apiEndpoint => '/telemetry';

  @override
  Map<String, dynamic> toJson(TelemetryData model) => model.toJson();

  @override
  TelemetryData fromJson(Map<String, dynamic> json) =>
      TelemetryData.fromJson(json);

  @override
  String getId(TelemetryData model) => model.id;

  /// Get telemetry data for a specific vehicle
  Future<List<TelemetryData>> getVehicleTelemetry(
    String vehicleId, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'vehicle_id': vehicleId,
        if (startTime != null) 'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime.toIso8601String(),
      };

      // Try API first if online
      if (_syncService.isOnline) {
        final response = await _apiService.get<List<dynamic>>(
          '/telemetry/vehicle/$vehicleId',
          queryParameters: queryParams,
        );

        if (response.isSuccess && response.data != null) {
          final telemetryList = (response.data as List)
              .map((json) => fromJson(json as Map<String, dynamic>))
              .toList();

          // Cache the data
          for (final telemetry in telemetryList) {
            await _storeOfflineData(
              id: getId(telemetry),
              tableName: tableName,
              data: toJson(telemetry),
            );
          }

          return telemetryList;
        }
      }

      // Fallback to cached data
      final allTelemetry = await getAll();
      return allTelemetry.where((t) => t.vehicleId == vehicleId).toList();
    } catch (e) {
      AppLogger.error('❌ Failed to get vehicle telemetry', e);

      // Return cached data as fallback
      final allTelemetry = await getAll();
      return allTelemetry.where((t) => t.vehicleId == vehicleId).toList();
    }
  }

  /// Store telemetry data (optimized for frequent updates)
  Future<void> storeTelemetryBatch(List<TelemetryData> telemetryList) async {
    try {
      // Store all items locally
      for (final telemetry in telemetryList) {
        await _storeOfflineData(
          id: getId(telemetry),
          tableName: tableName,
          data: toJson(telemetry),
        );
      }

      // Queue batch operation for sync
      await _queueOperation(
        operationType: 'batch_create_telemetry',
        endpoint: '/telemetry/batch',
        method: 'POST',
        data: {'telemetry_data': telemetryList.map(toJson).toList()},
        priority: 1, // High priority for telemetry data
      );

      AppLogger.debug(
        '✅ Stored ${telemetryList.length} telemetry records (queued for sync)',
      );
    } catch (e) {
      AppLogger.error('❌ Failed to store telemetry batch', e);
      rethrow;
    }
  }
}

/// Maintenance prediction repository with offline capabilities
class MaintenancePredictionRepository
    extends OfflineRepository<MaintenancePrediction> {
  @override
  String get tableName => 'predictions';

  @override
  String get apiEndpoint => '/predictions';

  @override
  Map<String, dynamic> toJson(MaintenancePrediction model) => model.toJson();

  @override
  MaintenancePrediction fromJson(Map<String, dynamic> json) =>
      MaintenancePrediction.fromJson(json);

  @override
  String getId(MaintenancePrediction model) => model.id;

  /// Get predictions for a specific vehicle
  Future<List<MaintenancePrediction>> getVehiclePredictions(
    String vehicleId,
  ) async {
    try {
      // Try API first if online
      if (_syncService.isOnline) {
        final response = await _apiService.get<List<dynamic>>(
          '/predictions/vehicle/$vehicleId',
        );

        if (response.isSuccess && response.data != null) {
          final predictions = (response.data as List)
              .map((json) => fromJson(json as Map<String, dynamic>))
              .toList();

          // Cache the data
          for (final prediction in predictions) {
            await _storeOfflineData(
              id: getId(prediction),
              tableName: tableName,
              data: toJson(prediction),
            );
          }

          return predictions;
        }
      }

      // Fallback to cached data
      final allPredictions = await getAll();
      return allPredictions.where((p) => p.vehicleId == vehicleId).toList();
    } catch (e) {
      AppLogger.error('❌ Failed to get vehicle predictions', e);

      // Return cached data as fallback
      final allPredictions = await getAll();
      return allPredictions.where((p) => p.vehicleId == vehicleId).toList();
    }
  }

  /// Get high-priority predictions
  Future<List<MaintenancePrediction>> getHighPriorityPredictions() async {
    final allPredictions = await getAll();
    return allPredictions.where((p) => p.failureProbability > 0.7).toList()
      ..sort((a, b) => b.failureProbability.compareTo(a.failureProbability));
  }
}

