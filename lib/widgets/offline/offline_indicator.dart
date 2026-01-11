import 'package:flutter/material.dart';
import '../../services/offline/offline_manager.dart';
import '../../design_system/design_system.dart';

/// Widget that shows offline/online status
class OfflineIndicator extends StatelessWidget {
  final bool showWhenOnline;
  final EdgeInsetsGeometry? padding;

  const OfflineIndicator({
    super.key,
    this.showWhenOnline = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OfflineManager(),
      builder: (context, child) {
        final offlineManager = OfflineManager();

        if (offlineManager.isOnline && !showWhenOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: padding ?? AivonitySpacing.paddingMD,
          child: AivonityCard(
            backgroundColor: offlineManager.isOffline
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  offlineManager.isOffline ? Icons.wifi_off : Icons.wifi,
                  color: offlineManager.isOffline
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                AivonitySpacing.hGapSM,
                Text(
                  offlineManager.isOffline ? 'Offline Mode' : 'Online',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: offlineManager.isOffline
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Banner that shows when app is offline
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OfflineManager(),
      builder: (context, child) {
        final offlineManager = OfflineManager();

        if (offlineManager.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: AivonitySpacing.paddingMD,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
              AivonitySpacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You\'re offline',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Some features may be limited. Data will sync when connection is restored.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget that shows offline capabilities for a feature
class OfflineCapabilityIndicator extends StatelessWidget {
  final String featureName;
  final List<String> requiredActions;

  const OfflineCapabilityIndicator({
    super.key,
    required this.featureName,
    this.requiredActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OfflineManager(),
      builder: (context, child) {
        final offlineManager = OfflineManager();

        if (offlineManager.isOnline) {
          return const SizedBox.shrink();
        }

        final isAvailable = offlineManager.isFeatureAvailableOffline(
          featureName,
        );
        final availableActions = requiredActions
            .where(
              (action) =>
                  offlineManager.isActionAvailableOffline(featureName, action),
            )
            .toList();

        if (!isAvailable) {
          return AivonityCard(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.offline_bolt,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                AivonitySpacing.hGapMD,
                Expanded(
                  child: Text(
                    'This feature is not available offline',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (availableActions.length < requiredActions.length) {
          return AivonityCard(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    AivonitySpacing.hGapMD,
                    Expanded(
                      child: Text(
                        'Limited functionality offline',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                AivonitySpacing.vGapSM,
                Text(
                  'Available: ${availableActions.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Status widget showing offline data freshness
class OfflineDataStatus extends StatelessWidget {
  final DateTime? lastUpdate;
  final String dataType;

  const OfflineDataStatus({super.key, this.lastUpdate, required this.dataType});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OfflineManager(),
      builder: (context, child) {
        final offlineManager = OfflineManager();

        if (offlineManager.isOnline) {
          return const SizedBox.shrink();
        }

        final freshness = _calculateDataFreshness();
        final color = _getFreshnessColor(context, freshness);

        return Container(
          padding: AivonitySpacing.paddingSM,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha:0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getFreshnessIcon(freshness), color: color, size: 16),
              AivonitySpacing.hGapSM,
              Text(
                _getFreshnessText(freshness),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DataFreshness _calculateDataFreshness() {
    if (lastUpdate == null) return DataFreshness.unknown;

    final age = DateTime.now().difference(lastUpdate!);

    if (age.inMinutes < 30) return DataFreshness.fresh;
    if (age.inHours < 6) return DataFreshness.recent;
    if (age.inDays < 1) return DataFreshness.stale;
    return DataFreshness.old;
  }

  Color _getFreshnessColor(BuildContext context, DataFreshness freshness) {
    switch (freshness) {
      case DataFreshness.fresh:
        return Colors.green;
      case DataFreshness.recent:
        return Colors.orange;
      case DataFreshness.stale:
        return Colors.red;
      case DataFreshness.old:
        return Colors.grey;
      case DataFreshness.unknown:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  IconData _getFreshnessIcon(DataFreshness freshness) {
    switch (freshness) {
      case DataFreshness.fresh:
        return Icons.check_circle;
      case DataFreshness.recent:
        return Icons.schedule;
      case DataFreshness.stale:
        return Icons.warning;
      case DataFreshness.old:
        return Icons.error;
      case DataFreshness.unknown:
        return Icons.help;
    }
  }

  String _getFreshnessText(DataFreshness freshness) {
    if (lastUpdate == null) return 'Data age unknown';

    final age = DateTime.now().difference(lastUpdate!);

    switch (freshness) {
      case DataFreshness.fresh:
        return 'Updated ${age.inMinutes}m ago';
      case DataFreshness.recent:
        return 'Updated ${age.inHours}h ago';
      case DataFreshness.stale:
        return 'Updated ${age.inDays}d ago';
      case DataFreshness.old:
        return 'Updated ${age.inDays}d ago';
      case DataFreshness.unknown:
        return 'Data age unknown';
    }
  }
}

enum DataFreshness { fresh, recent, stale, old, unknown }

