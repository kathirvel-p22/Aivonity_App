import 'package:flutter/material.dart';
import '../models/analytics.dart';

class KPIMetricsDashboard extends StatelessWidget {
  final List<KPIMetric> metrics;
  final Function(KPIMetric)? onMetricTap;

  const KPIMetricsDashboard({
    super.key,
    required this.metrics,
    this.onMetricTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Performance Indicators',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              return KPIMetricCard(
                metric: metrics[index],
                onTap: () => onMetricTap?.call(metrics[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class KPIMetricCard extends StatelessWidget {
  final KPIMetric metric;
  final VoidCallback? onTap;

  const KPIMetricCard({super.key, required this.metric, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      metric.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildTrendIcon(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatValue(metric.currentValue),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getTrendColor(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    metric.unit,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(_getTrendIcon(), size: 16, color: _getTrendColor()),
                  const SizedBox(width: 4),
                  Text(
                    '${metric.changePercentage.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getTrendColor(),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                metric.description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _getTrendColor().withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(_getTrendIcon(), size: 16, color: _getTrendColor()),
    );
  }

  IconData _getTrendIcon() {
    switch (metric.trend) {
      case KPITrend.improving:
        return Icons.trending_up;
      case KPITrend.declining:
        return Icons.trending_down;
      case KPITrend.stable:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor() {
    switch (metric.trend) {
      case KPITrend.improving:
        return Colors.green;
      case KPITrend.declining:
        return Colors.red;
      case KPITrend.stable:
        return Colors.orange;
    }
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }
}

