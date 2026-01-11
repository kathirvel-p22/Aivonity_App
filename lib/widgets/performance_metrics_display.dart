import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/analytics.dart';

class PerformanceMetricsDisplay extends StatelessWidget {
  final PerformanceMetrics metrics;
  final TrendAnalysis? trendAnalysis;

  const PerformanceMetricsDisplay({
    super.key,
    required this.metrics,
    this.trendAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildMetricsGrid(context),
          if (trendAnalysis != null) ...[
            const SizedBox(height: 24),
            _buildTrendSummary(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Vehicle ID: ${metrics.vehicleId}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(metrics.timestamp),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              DateFormat('HH:mm').format(metrics.timestamp),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          context,
          'Fuel Efficiency',
          '${metrics.fuelEfficiency.toStringAsFixed(1)} MPG',
          Icons.local_gas_station,
          Colors.blue,
        ),
        _buildMetricCard(
          context,
          'Average Speed',
          '${metrics.averageSpeed.toStringAsFixed(1)} mph',
          Icons.speed,
          Colors.green,
        ),
        _buildMetricCard(
          context,
          'Total Distance',
          _formatDistance(metrics.totalDistance),
          Icons.route,
          Colors.orange,
        ),
        _buildMetricCard(
          context,
          'Engine Health',
          '${(metrics.engineHealth * 100).toStringAsFixed(0)}%',
          Icons.engineering,
          _getHealthColor(metrics.engineHealth),
        ),
        _buildMetricCard(
          context,
          'Battery Health',
          '${(metrics.batteryHealth * 100).toStringAsFixed(0)}%',
          Icons.battery_full,
          _getHealthColor(metrics.batteryHealth),
        ),
        _buildMetricCard(
          context,
          'Maintenance Score',
          '${(metrics.maintenanceScore * 100).toStringAsFixed(0)}%',
          Icons.build,
          _getHealthColor(metrics.maintenanceScore),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (title == 'Engine Health' ||
                    title == 'Battery Health' ||
                    title == 'Maintenance Score')
                  _buildHealthIndicator(
                    title == 'Engine Health'
                        ? metrics.engineHealth
                        : title == 'Battery Health'
                        ? metrics.batteryHealth
                        : metrics.maintenanceScore,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(double healthValue) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getHealthColor(healthValue),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTrendSummary(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTrendIcon(trendAnalysis!.overallTrend),
                  color: _getTrendColor(trendAnalysis!.overallTrend),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trend Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Trend: ${_getTrendText(trendAnalysis!.overallTrend)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Confidence: ${(trendAnalysis!.trendConfidence * 100).toStringAsFixed(0)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: trendAnalysis!.trendConfidence,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTrendColor(trendAnalysis!.overallTrend),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(double healthValue) {
    if (healthValue >= 0.8) return Colors.green;
    if (healthValue >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return Icons.trending_up;
      case TrendDirection.down:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return Colors.green;
      case TrendDirection.down:
        return Colors.red;
      case TrendDirection.stable:
        return Colors.orange;
    }
  }

  String _getTrendText(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return 'Improving';
      case TrendDirection.down:
        return 'Declining';
      case TrendDirection.stable:
        return 'Stable';
    }
  }

  String _formatDistance(int distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)}K mi';
    }
    return '$distance mi';
  }
}

