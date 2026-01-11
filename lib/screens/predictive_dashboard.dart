import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/predictive_analytics.dart';
import '../services/predictive_analytics_service.dart';
import '../widgets/maintenance_predictions_widget.dart';

class PredictiveDashboard extends StatefulWidget {
  final String vehicleId;

  const PredictiveDashboard({super.key, required this.vehicleId});

  @override
  State<PredictiveDashboard> createState() => _PredictiveDashboardState();
}

class _PredictiveDashboardState extends State<PredictiveDashboard> {
  late final PredictiveAnalyticsService _predictiveService;
  List<MaintenancePrediction> _predictions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _predictiveService = GetIt.instance<PredictiveAnalyticsService>();
    _loadPredictiveData();
  }

  Future<void> _loadPredictiveData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final predictions = await _predictiveService.getMaintenancePredictions(
        widget.vehicleId,
      );
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load predictive analytics data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictive Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPredictiveData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildPredictionsSummary(),
                  MaintenancePredictionsWidget(
                    predictions: _predictions,
                    onPredictionTap: _showPredictionDetails,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPredictiveData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsSummary() {
    final criticalCount = _predictions
        .where((p) => p.priority == MaintenancePriority.critical)
        .length;
    final highCount = _predictions
        .where((p) => p.priority == MaintenancePriority.high)
        .length;
    final totalCost = _predictions.fold(0.0, (sum, p) => sum + p.estimatedCost);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predictions Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Critical',
                  criticalCount.toString(),
                  Colors.red,
                ),
                _buildSummaryItem(
                  'High Priority',
                  highCount.toString(),
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'Total Cost',
                  '\$${totalCost.toStringAsFixed(0)}',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showPredictionDetails(MaintenancePrediction prediction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prediction.componentName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predicted Failure: ${prediction.predictedFailureDate.toString().split(' ')[0]}',
            ),
            Text(
              'Confidence: ${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
            ),
            Text(
              'Estimated Cost: \$${prediction.estimatedCost.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            Text('Action: ${prediction.recommendedAction}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

