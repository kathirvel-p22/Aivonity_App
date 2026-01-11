
/// Conflict resolution service for handling data synchronization conflicts
class ConflictResolver {
  static final ConflictResolver _instance = ConflictResolver._internal();
  factory ConflictResolver() => _instance;
  ConflictResolver._internal();

  /// Resolve a sync conflict using appropriate strategy
  Future<ConflictResolution> resolve(SyncConflict conflict) async {
    switch (conflict.type) {
      case ConflictType.dataModified:
        return await _resolveDataModifiedConflict(conflict);
      case ConflictType.recordDeleted:
        return await _resolveRecordDeletedConflict(conflict);
      case ConflictType.versionMismatch:
        return await _resolveVersionMismatchConflict(conflict);
      case ConflictType.schemaChange:
        return await _resolveSchemaChangeConflict(conflict);
    }
  }

  /// Resolve data modification conflicts
  Future<ConflictResolution> _resolveDataModifiedConflict(
    SyncConflict conflict,
  ) async {
    final strategy = _determineResolutionStrategy(conflict);

    switch (strategy) {
      case ResolutionStrategy.useLocal:
        return ConflictResolution(
          strategy: ResolutionStrategy.useLocal,
          resolvedData: conflict.localData,
          reason: 'Local changes are more recent',
        );

      case ResolutionStrategy.useRemote:
        return ConflictResolution(
          strategy: ResolutionStrategy.useRemote,
          resolvedData: conflict.remoteData,
          reason: 'Remote changes are more recent',
        );

      case ResolutionStrategy.merge:
        final mergedData = await _mergeData(
          conflict.localData,
          conflict.remoteData,
        );
        return ConflictResolution(
          strategy: ResolutionStrategy.merge,
          resolvedData: mergedData,
          reason: 'Successfully merged local and remote changes',
        );

      case ResolutionStrategy.manual:
        return ConflictResolution(
          strategy: ResolutionStrategy.manual,
          resolvedData: null,
          reason: 'Requires manual resolution',
          requiresUserInput: true,
        );
    }
  }

  /// Resolve record deletion conflicts
  Future<ConflictResolution> _resolveRecordDeletedConflict(
    SyncConflict conflict,
  ) async {
    // If record was deleted remotely but modified locally
    if (conflict.remoteData == null && conflict.localData != null) {
      // Check if local changes are significant
      if (_hasSignificantChanges(conflict.localData!)) {
        return ConflictResolution(
          strategy: ResolutionStrategy.useLocal,
          resolvedData: conflict.localData,
          reason: 'Local changes are significant, restoring record',
        );
      } else {
        return ConflictResolution(
          strategy: ResolutionStrategy.useRemote,
          resolvedData: null,
          reason: 'Accepting remote deletion',
        );
      }
    }

    // If record was deleted locally but modified remotely
    if (conflict.localData == null && conflict.remoteData != null) {
      return ConflictResolution(
        strategy: ResolutionStrategy.manual,
        resolvedData: null,
        reason: 'Record deleted locally but modified remotely',
        requiresUserInput: true,
      );
    }

    // Both deleted - no conflict
    return ConflictResolution(
      strategy: ResolutionStrategy.useRemote,
      resolvedData: null,
      reason: 'Record deleted on both sides',
    );
  }

  /// Resolve version mismatch conflicts
  Future<ConflictResolution> _resolveVersionMismatchConflict(
    SyncConflict conflict,
  ) async {
    // Use timestamp-based resolution for version mismatches
    final localTimestamp = _extractTimestamp(conflict.localData);
    final remoteTimestamp = _extractTimestamp(conflict.remoteData);

    if (localTimestamp != null && remoteTimestamp != null) {
      if (localTimestamp.isAfter(remoteTimestamp)) {
        return ConflictResolution(
          strategy: ResolutionStrategy.useLocal,
          resolvedData: conflict.localData,
          reason: 'Local version is newer',
        );
      } else {
        return ConflictResolution(
          strategy: ResolutionStrategy.useRemote,
          resolvedData: conflict.remoteData,
          reason: 'Remote version is newer',
        );
      }
    }

    // Fallback to manual resolution
    return ConflictResolution(
      strategy: ResolutionStrategy.manual,
      resolvedData: null,
      reason: 'Cannot determine version precedence',
      requiresUserInput: true,
    );
  }

  /// Resolve schema change conflicts
  Future<ConflictResolution> _resolveSchemaChangeConflict(
    SyncConflict conflict,
  ) async {
    try {
      // Attempt to migrate local data to new schema
      final migratedData = await _migrateToNewSchema(
        conflict.localData!,
        conflict.remoteData!,
      );

      return ConflictResolution(
        strategy: ResolutionStrategy.merge,
        resolvedData: migratedData,
        reason: 'Successfully migrated to new schema',
      );
    } catch (e) {
      return ConflictResolution(
        strategy: ResolutionStrategy.manual,
        resolvedData: null,
        reason: 'Schema migration failed: $e',
        requiresUserInput: true,
      );
    }
  }

  /// Determine the best resolution strategy for a conflict
  ResolutionStrategy _determineResolutionStrategy(SyncConflict conflict) {
    // Check if data can be automatically merged
    if (_canAutoMerge(conflict.localData, conflict.remoteData)) {
      return ResolutionStrategy.merge;
    }

    // Use timestamp-based resolution
    final localTimestamp = _extractTimestamp(conflict.localData);
    final remoteTimestamp = _extractTimestamp(conflict.remoteData);

    if (localTimestamp != null && remoteTimestamp != null) {
      final timeDifference = localTimestamp.difference(remoteTimestamp).abs();

      // If changes are very close in time, require manual resolution
      if (timeDifference.inMinutes < 5) {
        return ResolutionStrategy.manual;
      }

      return localTimestamp.isAfter(remoteTimestamp)
          ? ResolutionStrategy.useLocal
          : ResolutionStrategy.useRemote;
    }

    // Check conflict severity
    final severity = _calculateConflictSeverity(conflict);
    if (severity > 0.7) {
      return ResolutionStrategy.manual;
    }

    // Default to using local changes
    return ResolutionStrategy.useLocal;
  }

  /// Check if two data objects can be automatically merged
  bool _canAutoMerge(
    Map<String, dynamic>? local,
    Map<String, dynamic>? remote,
  ) {
    if (local == null || remote == null) return false;

    // Check for conflicting field changes
    final conflictingFields = <String>[];

    for (final key in local.keys) {
      if (remote.containsKey(key) && local[key] != remote[key]) {
        // Check if this is a mergeable field type
        if (!_isMergeableField(key, local[key], remote[key])) {
          conflictingFields.add(key);
        }
      }
    }

    // Can auto-merge if no conflicting fields or only minor conflicts
    return conflictingFields.length <= 2;
  }

  /// Check if a field can be automatically merged
  bool _isMergeableField(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
  ) {
    // Timestamps can be resolved by taking the latest
    if (fieldName.contains('timestamp') || fieldName.contains('time')) {
      return true;
    }

    // Counters can be merged by taking the maximum
    if (fieldName.contains('count') || fieldName.contains('total')) {
      return localValue is num && remoteValue is num;
    }

    // Arrays can often be merged
    if (localValue is List && remoteValue is List) {
      return true;
    }

    // Objects can be recursively merged
    if (localValue is Map && remoteValue is Map) {
      return true;
    }

    return false;
  }

  /// Merge two data objects intelligently
  Future<Map<String, dynamic>> _mergeData(
    Map<String, dynamic>? local,
    Map<String, dynamic>? remote,
  ) async {
    if (local == null) return remote ?? {};
    if (remote == null) return local;

    final merged = Map<String, dynamic>.from(local);

    for (final entry in remote.entries) {
      final key = entry.key;
      final remoteValue = entry.value;

      if (!merged.containsKey(key)) {
        // New field from remote
        merged[key] = remoteValue;
      } else {
        final localValue = merged[key];

        if (localValue == remoteValue) {
          // No conflict
          continue;
        }

        // Merge based on field type
        merged[key] = await _mergeFieldValues(key, localValue, remoteValue);
      }
    }

    return merged;
  }

  /// Merge individual field values
  Future<dynamic> _mergeFieldValues(
    String fieldName,
    dynamic localValue,
    dynamic remoteValue,
  ) async {
    // Timestamp fields - use the latest
    if (fieldName.contains('timestamp') || fieldName.contains('time')) {
      if (localValue is int && remoteValue is int) {
        return localValue > remoteValue ? localValue : remoteValue;
      }
      if (localValue is String && remoteValue is String) {
        try {
          final localTime = DateTime.parse(localValue);
          final remoteTime = DateTime.parse(remoteValue);
          return localTime.isAfter(remoteTime) ? localValue : remoteValue;
        } catch (e) {
          return remoteValue; // Fallback to remote
        }
      }
    }

    // Numeric fields - use maximum for counters, average for measurements
    if (localValue is num && remoteValue is num) {
      if (fieldName.contains('count') || fieldName.contains('total')) {
        return localValue > remoteValue ? localValue : remoteValue;
      }
      // For other numeric fields, take the average
      return (localValue + remoteValue) / 2;
    }

    // Array fields - merge arrays
    if (localValue is List && remoteValue is List) {
      final merged = List.from(localValue);
      for (final item in remoteValue) {
        if (!merged.contains(item)) {
          merged.add(item);
        }
      }
      return merged;
    }

    // Object fields - recursive merge
    if (localValue is Map && remoteValue is Map) {
      return await _mergeData(
        localValue.cast<String, dynamic>(),
        remoteValue.cast<String, dynamic>(),
      );
    }

    // String fields - prefer non-empty values
    if (localValue is String && remoteValue is String) {
      if (localValue.isEmpty) return remoteValue;
      if (remoteValue.isEmpty) return localValue;
      // Both non-empty - prefer remote (server wins)
      return remoteValue;
    }

    // Default - prefer remote value
    return remoteValue;
  }

  /// Extract timestamp from data object
  DateTime? _extractTimestamp(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Common timestamp field names
    final timestampFields = [
      'updated_at',
      'modified_at',
      'timestamp',
      'last_modified',
      'created_at',
    ];

    for (final field in timestampFields) {
      if (data.containsKey(field)) {
        final value = data[field];
        if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            continue;
          }
        }
      }
    }

    return null;
  }

  /// Check if local changes are significant enough to preserve
  bool _hasSignificantChanges(Map<String, dynamic> data) {
    // Check for user-generated content
    final userContentFields = ['content', 'message', 'notes', 'description'];
    for (final field in userContentFields) {
      if (data.containsKey(field) && data[field] != null) {
        final value = data[field].toString();
        if (value.trim().isNotEmpty) {
          return true;
        }
      }
    }

    // Check for recent modifications
    final timestamp = _extractTimestamp(data);
    if (timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age.inHours < 24) {
        return true;
      }
    }

    return false;
  }

  /// Calculate conflict severity (0.0 = no conflict, 1.0 = severe conflict)
  double _calculateConflictSeverity(SyncConflict conflict) {
    if (conflict.localData == null || conflict.remoteData == null) {
      return 1.0; // Deletion conflicts are severe
    }

    final local = conflict.localData!;
    final remote = conflict.remoteData!;

    int totalFields = 0;
    int conflictingFields = 0;

    final allKeys = {...local.keys, ...remote.keys};

    for (final key in allKeys) {
      totalFields++;

      final localValue = local[key];
      final remoteValue = remote[key];

      if (localValue != remoteValue) {
        conflictingFields++;
      }
    }

    return totalFields > 0 ? conflictingFields / totalFields : 0.0;
  }

  /// Migrate data to new schema
  Future<Map<String, dynamic>> _migrateToNewSchema(
    Map<String, dynamic> oldData,
    Map<String, dynamic> schemaTemplate,
  ) async {
    final migrated = <String, dynamic>{};

    // Copy compatible fields
    for (final entry in schemaTemplate.entries) {
      final key = entry.key;
      final templateValue = entry.value;

      if (oldData.containsKey(key)) {
        // Field exists in old data
        migrated[key] = oldData[key];
      } else {
        // New field - use default value from template
        migrated[key] = templateValue;
      }
    }

    // Handle deprecated fields (store in metadata)
    final deprecatedFields = <String, dynamic>{};
    for (final entry in oldData.entries) {
      if (!schemaTemplate.containsKey(entry.key)) {
        deprecatedFields[entry.key] = entry.value;
      }
    }

    if (deprecatedFields.isNotEmpty) {
      migrated['_deprecated_fields'] = deprecatedFields;
    }

    return migrated;
  }
}

/// Represents a synchronization conflict
class SyncConflict {
  final String recordId;
  final String tableName;
  final ConflictType type;
  final Map<String, dynamic>? localData;
  final Map<String, dynamic>? remoteData;
  final DateTime detectedAt;
  final String? description;

  SyncConflict({
    required this.recordId,
    required this.tableName,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.detectedAt,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'table_name': tableName,
      'type': type.toString(),
      'local_data': localData,
      'remote_data': remoteData,
      'detected_at': detectedAt.toIso8601String(),
      'description': description,
    };
  }
}

/// Types of synchronization conflicts
enum ConflictType {
  dataModified, // Both local and remote data were modified
  recordDeleted, // Record was deleted on one side, modified on other
  versionMismatch, // Version numbers don't match
  schemaChange, // Data schema has changed
}

/// Resolution for a synchronization conflict
class ConflictResolution {
  final ResolutionStrategy strategy;
  final Map<String, dynamic>? resolvedData;
  final String reason;
  final bool requiresUserInput;
  final DateTime resolvedAt;

  ConflictResolution({
    required this.strategy,
    required this.resolvedData,
    required this.reason,
    this.requiresUserInput = false,
  }) : resolvedAt = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'strategy': strategy.toString(),
      'resolved_data': resolvedData,
      'reason': reason,
      'requires_user_input': requiresUserInput,
      'resolved_at': resolvedAt.toIso8601String(),
    };
  }
}

/// Strategies for resolving conflicts
enum ResolutionStrategy {
  useLocal, // Use the local version
  useRemote, // Use the remote version
  merge, // Merge local and remote changes
  manual, // Requires manual user intervention
}

