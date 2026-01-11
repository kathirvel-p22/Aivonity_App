import 'package:flutter/material.dart';
import '../services/alert_service.dart';

class EnhancedAlertWidget extends StatelessWidget {
  final EnhancedAlert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onDismiss;
  final VoidCallback? onSnooze;
  final bool showActions;

  const EnhancedAlertWidget({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.onDismiss,
    this.onSnooze,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: _getElevation(),
      color: _getBackgroundColor(),
      child: Column(
        children: [
          // Alert header
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: _getSeverityColor().withValues(alpha:0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                // Severity indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getSeverityColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // Alert icon
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getSeverityColor(),
                  child: Icon(_getAlertIcon(), color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),

                // Alert content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and severity
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getSeverityColor(),
                                  ),
                            ),
                          ),
                          _buildSeverityChip(),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message
                      Text(
                        alert.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Status indicators
                Column(
                  children: [
                    if (alert.acknowledged)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    if (alert.dismissed)
                      const Icon(Icons.cancel, color: Colors.grey, size: 20),
                    if (alert.snoozeUntil != null &&
                        alert.snoozeUntil!.isAfter(DateTime.now()))
                      const Icon(Icons.snooze, color: Colors.orange, size: 20),
                  ],
                ),
              ],
            ),
          ),

          // Alert details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metadata
                _buildMetadataRow(context),

                // Recommended actions
                if (alert.recommendedActions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildRecommendedActions(context),
                ],

                // Action buttons
                if (showActions && !alert.dismissed) ...[
                  const SizedBox(height: 8),
                  _buildActionButtons(context),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSeverityChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getSeverityColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        alert.severity.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    return Row(
      children: [
        // Category
        Icon(_getCategoryIcon(), size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          alert.category.name.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 16),

        // Timestamp
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          _formatTimestamp(alert.timestamp),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),

        // Vehicle ID
        if (alert.vehicleId != null) ...[
          const SizedBox(width: 16),
          Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            alert.vehicleId!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendedActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Actions:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        ...alert.recommendedActions.map(
          (action) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: _getSeverityColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    action,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Snooze button (not for critical alerts)
        if (alert.severity != AlertSeverity.critical &&
            !alert.acknowledged &&
            onSnooze != null)
          TextButton.icon(
            onPressed: onSnooze,
            icon: const Icon(Icons.snooze, size: 16),
            label: const Text('Snooze'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
          ),

        // Dismiss button
        if (!alert.acknowledged && onDismiss != null)
          TextButton.icon(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Dismiss'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),

        // Acknowledge button
        if (!alert.acknowledged && onAcknowledge != null)
          ElevatedButton.icon(
            onPressed: onAcknowledge,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Acknowledge'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getSeverityColor(),
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _getSeverityColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Colors.red.shade700;
      case AlertSeverity.high:
        return Colors.orange.shade700;
      case AlertSeverity.medium:
        return Colors.yellow.shade700;
      case AlertSeverity.low:
        return Colors.blue.shade600;
      case AlertSeverity.info:
        return Colors.grey.shade600;
    }
  }

  Color _getBackgroundColor() {
    if (alert.dismissed) return Colors.grey.shade100;
    if (alert.acknowledged) return Colors.green.shade50;
    return Colors.white;
  }

  double _getElevation() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return 8.0;
      case AlertSeverity.high:
        return 6.0;
      case AlertSeverity.medium:
        return 4.0;
      default:
        return 2.0;
    }
  }

  IconData _getAlertIcon() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.high:
        return Icons.warning;
      case AlertSeverity.medium:
        return Icons.info;
      case AlertSeverity.low:
        return Icons.notifications;
      case AlertSeverity.info:
        return Icons.info_outline;
    }
  }

  IconData _getCategoryIcon() {
    switch (alert.category) {
      case AlertCategory.engine:
        return Icons.engineering;
      case AlertCategory.battery:
        return Icons.battery_alert;
      case AlertCategory.fuel:
        return Icons.local_gas_station;
      case AlertCategory.temperature:
        return Icons.thermostat;
      case AlertCategory.pressure:
        return Icons.compress;
      case AlertCategory.diagnostic:
        return Icons.bug_report;
      case AlertCategory.security:
        return Icons.security;
      case AlertCategory.maintenance:
        return Icons.build;
      case AlertCategory.system:
        return Icons.settings;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

