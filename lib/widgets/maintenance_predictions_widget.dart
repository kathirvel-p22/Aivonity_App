import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/predictive_analytics.dart';

class MaintenancePredictionsWidget extends StatelessWidget {
  final List<MaintenancePrediction> predictions;
  final Function(MaintenancePrediction)? onPredictionTap;

  const MaintenancePredictionsWidget({
    super.key,
    required this.predictions,
    this.onPredictionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Maintenance Predictions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${predictions.length} items',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: predictions.length,
            itemBuilder: (context, index) {
              return MaintenancePredictionCard(
                prediction: predictions[index],
                onTap: () => onPredictionTap?.call(predictions[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MaintenancePredictionCard extends StatelessWidget {
  final MaintenancePrediction prediction;
  final VoidCallback? onTap;

  const MaintenancePredictionCard({
    super.key,
    required this.prediction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getPriorityColor().withValues(alpha:0.3), width: 1),
      ),
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
                      prediction.componentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${prediction.daysUntilMaintenance} days until maintenance',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(prediction.predictedFailureDate)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confidence',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.grey[300],
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: prediction.confidenceScore,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: _getConfidenceColor(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Est. Cost',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${prediction.estimatedCost.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Action',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prediction.recommendedAction,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor().withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriorityIcon(), size: 12, color: _getPriorityColor()),
          const SizedBox(width: 4),
          Text(
            _getPriorityText(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getPriorityColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (prediction.priority) {
      case MaintenancePriority.low:
        return Colors.green;
      case MaintenancePriority.medium:
        return Colors.orange;
      case MaintenancePriority.high:
        return Colors.red;
      case MaintenancePriority.critical:
        return Colors.red[900]!;
    }
  }

  IconData _getPriorityIcon() {
    switch (prediction.priority) {
      case MaintenancePriority.low:
        return Icons.info;
      case MaintenancePriority.medium:
        return Icons.warning;
      case MaintenancePriority.high:
        return Icons.error;
      case MaintenancePriority.critical:
        return Icons.dangerous;
    }
  }

  String _getPriorityText() {
    switch (prediction.priority) {
      case MaintenancePriority.low:
        return 'Low';
      case MaintenancePriority.medium:
        return 'Medium';
      case MaintenancePriority.high:
        return 'High';
      case MaintenancePriority.critical:
        return 'Critical';
    }
  }

  Color _getConfidenceColor() {
    if (prediction.confidenceScore >= 0.8) return Colors.green;
    if (prediction.confidenceScore >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

