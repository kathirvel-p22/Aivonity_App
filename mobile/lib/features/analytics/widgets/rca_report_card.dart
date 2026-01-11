import 'package:flutter/material.dart';

import '../models/rca_report.dart';

/// AIVONITY RCA Report Card Widget
/// Displays RCA report summary with status and severity indicators
class RCAReportCard extends StatelessWidget {
  final RCAReport report;
  final VoidCallback onTap;

  const RCAReportCard({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getSeverityColor(report.severity).withValues(alpha:0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Severity Indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getSeverityColor(report.severity),
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 12),

                // Title
                Expanded(
                  child: Text(
                    report.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                // Status Badge
                _buildStatusBadge(context),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha:0.7),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Metadata Row
            Row(
              children: [
                // Category
                _buildMetadataChip(
                  context,
                  report.category,
                  Icons.category,
                  Colors.blue,
                ),

                const SizedBox(width: 12),

                // Severity
                _buildMetadataChip(
                  context,
                  report.severity.displayName,
                  Icons.priority_high,
                  _getSeverityColor(report.severity),
                ),

                const Spacer(),

                // Date
                Text(
                  _formatDate(report.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Indicators
            _buildProgressIndicators(context),

            // Resolution Time (if resolved)
            if (report.resolvedAt != null) ...[
              const SizedBox(height: 12),
              _buildResolutionTime(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = _getStatusColor(report.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        report.status.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildMetadataChip(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicators(BuildContext context) {
    return Column(
      children: [
        // Symptoms Progress
        _buildProgressItem(
          context,
          'Symptoms Identified',
          report.symptoms.length,
          report.symptoms.length,
          Colors.orange,
        ),

        const SizedBox(height: 8),

        // Root Causes Progress
        _buildProgressItem(
          context,
          'Root Causes Found',
          report.rootCauses.length,
          report.symptoms.length,
          Colors.red,
        ),

        const SizedBox(height: 8),

        // Corrective Actions Progress
        _buildProgressItem(
          context,
          'Actions Completed',
          report.correctiveActions.length,
          report.recommendations.length,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildProgressItem(
    BuildContext context,
    String label,
    int completed,
    int total,
    Color color,
  ) {
    final progress = total > 0 ? completed / total : 0.0;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha:0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$completed/$total',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildResolutionTime(BuildContext context) {
    final resolutionTime = report.resolvedAt!.difference(report.createdAt);
    final days = resolutionTime.inDays;
    final hours = resolutionTime.inHours % 24;

    String timeText;
    if (days > 0) {
      timeText = '${days}d ${hours}h';
    } else {
      timeText = '${hours}h';
    }

    return Row(
      children: [
        const Icon(Icons.schedule, size: 16, color: Colors.green),
        const SizedBox(width: 4),
        Text(
          'Resolved in $timeText',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Color _getSeverityColor(RCASeverity severity) {
    switch (severity) {
      case RCASeverity.low:
        return Colors.green;
      case RCASeverity.medium:
        return Colors.orange;
      case RCASeverity.high:
        return Colors.red;
      case RCASeverity.critical:
        return Colors.purple;
    }
  }

  Color _getStatusColor(RCAStatus status) {
    switch (status) {
      case RCAStatus.open:
        return Colors.red;
      case RCAStatus.inProgress:
        return Colors.orange;
      case RCAStatus.resolved:
        return Colors.green;
      case RCAStatus.closed:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

