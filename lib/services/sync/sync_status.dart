/// Synchronization status enumeration
enum SyncStatus {
  /// No sync operation in progress
  idle,

  /// Sync operation is currently running
  syncing,

  /// Sync completed successfully
  completed,

  /// Sync failed with error
  error,

  /// Sync paused (e.g., due to network issues)
  paused,

  /// Waiting for network connection
  waitingForNetwork,

  /// Resolving conflicts
  resolvingConflicts,
}

extension SyncStatusExtension on SyncStatus {
  /// Human-readable description of the sync status
  String get description {
    switch (this) {
      case SyncStatus.idle:
        return 'Ready to sync';
      case SyncStatus.syncing:
        return 'Syncing data...';
      case SyncStatus.completed:
        return 'Sync completed';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.paused:
        return 'Sync paused';
      case SyncStatus.waitingForNetwork:
        return 'Waiting for network';
      case SyncStatus.resolvingConflicts:
        return 'Resolving conflicts';
    }
  }

  /// Whether the sync status indicates an active operation
  bool get isActive {
    switch (this) {
      case SyncStatus.syncing:
      case SyncStatus.resolvingConflicts:
        return true;
      default:
        return false;
    }
  }

  /// Whether the sync status indicates an error state
  bool get isError {
    return this == SyncStatus.error;
  }

  /// Whether the sync status indicates completion
  bool get isCompleted {
    return this == SyncStatus.completed;
  }

  /// Icon to display for this sync status
  String get iconName {
    switch (this) {
      case SyncStatus.idle:
        return 'sync';
      case SyncStatus.syncing:
        return 'sync';
      case SyncStatus.completed:
        return 'check_circle';
      case SyncStatus.error:
        return 'error';
      case SyncStatus.paused:
        return 'pause_circle';
      case SyncStatus.waitingForNetwork:
        return 'wifi_off';
      case SyncStatus.resolvingConflicts:
        return 'merge_type';
    }
  }
}

/// Detailed sync progress information
class SyncProgress {
  final int totalItems;
  final int completedItems;
  final int failedItems;
  final String? currentOperation;
  final DateTime startTime;
  final DateTime? estimatedCompletion;
  final List<String> recentErrors;

  SyncProgress({
    required this.totalItems,
    required this.completedItems,
    required this.failedItems,
    this.currentOperation,
    required this.startTime,
    this.estimatedCompletion,
    this.recentErrors = const [],
  });

  /// Progress percentage (0.0 to 1.0)
  double get progress {
    if (totalItems == 0) return 1.0;
    return (completedItems + failedItems) / totalItems;
  }

  /// Remaining items to process
  int get remainingItems => totalItems - completedItems - failedItems;

  /// Whether sync is complete
  bool get isComplete => remainingItems == 0;

  /// Success rate (0.0 to 1.0)
  double get successRate {
    final processedItems = completedItems + failedItems;
    if (processedItems == 0) return 1.0;
    return completedItems / processedItems;
  }

  /// Estimated time remaining
  Duration? get estimatedTimeRemaining {
    if (estimatedCompletion == null) return null;
    final remaining = estimatedCompletion!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Elapsed time since sync started
  Duration get elapsedTime => DateTime.now().difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'completed_items': completedItems,
      'failed_items': failedItems,
      'current_operation': currentOperation,
      'start_time': startTime.toIso8601String(),
      'estimated_completion': estimatedCompletion?.toIso8601String(),
      'recent_errors': recentErrors,
      'progress': progress,
      'remaining_items': remainingItems,
      'success_rate': successRate,
      'elapsed_time_ms': elapsedTime.inMilliseconds,
    };
  }
}

/// Sync operation details
class SyncOperation {
  final String id;
  final String type;
  final String tableName;
  final String recordId;
  final SyncOperationStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int retryCount;
  final int priority;

  SyncOperation({
    required this.id,
    required this.type,
    required this.tableName,
    required this.recordId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.retryCount = 0,
    this.priority = 1,
  });

  /// Duration of the operation (if completed)
  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  /// Whether the operation can be retried
  bool get canRetry => status == SyncOperationStatus.failed && retryCount < 3;

  /// Whether the operation is in progress
  bool get isInProgress => status == SyncOperationStatus.inProgress;

  /// Whether the operation completed successfully
  bool get isSuccessful => status == SyncOperationStatus.completed;

  /// Whether the operation failed
  bool get isFailed => status == SyncOperationStatus.failed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'table_name': tableName,
      'record_id': recordId,
      'status': status.toString(),
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'error_message': errorMessage,
      'retry_count': retryCount,
      'priority': priority,
      'duration_ms': duration?.inMilliseconds,
    };
  }
}

/// Status of individual sync operations
enum SyncOperationStatus { pending, inProgress, completed, failed, cancelled }

/// Sync health metrics
class SyncHealth {
  final double overallHealth; // 0.0 to 1.0
  final int pendingOperations;
  final int failedOperations;
  final DateTime? lastSuccessfulSync;
  final Duration? averageSyncTime;
  final List<String> healthIssues;
  final bool isOnline;

  SyncHealth({
    required this.overallHealth,
    required this.pendingOperations,
    required this.failedOperations,
    this.lastSuccessfulSync,
    this.averageSyncTime,
    this.healthIssues = const [],
    required this.isOnline,
  });

  /// Whether sync health is good (> 0.8)
  bool get isHealthy => overallHealth > 0.8;

  /// Whether sync health is poor (< 0.5)
  bool get isPoor => overallHealth < 0.5;

  /// Health status description
  String get healthDescription {
    if (overallHealth > 0.9) return 'Excellent';
    if (overallHealth > 0.8) return 'Good';
    if (overallHealth > 0.6) return 'Fair';
    if (overallHealth > 0.4) return 'Poor';
    return 'Critical';
  }

  /// Color code for health status
  String get healthColor {
    if (overallHealth > 0.8) return 'green';
    if (overallHealth > 0.6) return 'yellow';
    return 'red';
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_health': overallHealth,
      'pending_operations': pendingOperations,
      'failed_operations': failedOperations,
      'last_successful_sync': lastSuccessfulSync?.toIso8601String(),
      'average_sync_time_ms': averageSyncTime?.inMilliseconds,
      'health_issues': healthIssues,
      'is_online': isOnline,
      'health_description': healthDescription,
      'health_color': healthColor,
    };
  }
}

/// Sync configuration settings
class SyncConfig {
  final Duration syncInterval;
  final int maxRetries;
  final Duration retryDelay;
  final bool syncOnlyOnWifi;
  final bool syncInBackground;
  final List<String> priorityTables;
  final int batchSize;
  final Duration timeout;

  const SyncConfig({
    this.syncInterval = const Duration(minutes: 15),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 30),
    this.syncOnlyOnWifi = false,
    this.syncInBackground = true,
    this.priorityTables = const [],
    this.batchSize = 50,
    this.timeout = const Duration(minutes: 5),
  });

  /// Default sync configuration
  static const defaultConfig = SyncConfig();

  /// Conservative sync configuration (less frequent, smaller batches)
  static const conservativeConfig = SyncConfig(
    syncInterval: Duration(hours: 1),
    batchSize: 20,
    syncOnlyOnWifi: true,
  );

  /// Aggressive sync configuration (more frequent, larger batches)
  static const aggressiveConfig = SyncConfig(
    syncInterval: Duration(minutes: 5),
    batchSize: 100,
    maxRetries: 5,
  );

  Map<String, dynamic> toJson() {
    return {
      'sync_interval_ms': syncInterval.inMilliseconds,
      'max_retries': maxRetries,
      'retry_delay_ms': retryDelay.inMilliseconds,
      'sync_only_on_wifi': syncOnlyOnWifi,
      'sync_in_background': syncInBackground,
      'priority_tables': priorityTables,
      'batch_size': batchSize,
      'timeout_ms': timeout.inMilliseconds,
    };
  }
}

