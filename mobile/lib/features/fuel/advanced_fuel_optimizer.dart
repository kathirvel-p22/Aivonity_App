import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Advanced Fuel Optimization System with AI-powered efficiency analysis
class AdvancedFuelOptimizer extends StatefulWidget {
  const AdvancedFuelOptimizer({super.key});

  @override
  State<AdvancedFuelOptimizer> createState() => _AdvancedFuelOptimizerState();
}

class _AdvancedFuelOptimizerState extends State<AdvancedFuelOptimizer>
    with TickerProviderStateMixin {
  late AnimationController _fuelController;
  late Animation<double> _fuelAnimation;

  // Fuel data
  FuelAnalytics _analytics = const FuelAnalytics();
  List<FuelEntry> _fuelHistory = [];
  List<FuelStation> _nearbyStations = [];
  FuelOptimizationPlan _currentPlan = const FuelOptimizationPlan();

  // Real-time monitoring
  Timer? _monitoringTimer;
  double _currentEfficiency = 0.0;
  double _instantFuelConsumption = 0.0;

  // AI optimization
  Map<String, FuelPattern> _drivingPatterns = {};
  List<FuelPrediction> _predictions = [];
  bool _isOptimizing = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeFuelData();
    _startMonitoring();
  }

  void _setupAnimations() {
    _fuelController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fuelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fuelController,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _initializeFuelData() {
    // Initialize fuel history
    _fuelHistory = [
      FuelEntry(
        id: 'fuel_1',
        date: DateTime.now().subtract(const Duration(days: 30)),
        gallons: 12.5,
        pricePerGallon: 3.45,
        totalCost: 43.13,
        mileage: 320,
        location: 'Shell Station - Downtown',
        fuelType: FuelType.regular,
        octaneRating: 87,
      ),
      FuelEntry(
        id: 'fuel_2',
        date: DateTime.now().subtract(const Duration(days: 15)),
        gallons: 11.8,
        pricePerGallon: 3.52,
        totalCost: 41.54,
        mileage: 305,
        location: 'BP Station - Highway',
        fuelType: FuelType.regular,
        octaneRating: 87,
      ),
      FuelEntry(
        id: 'fuel_3',
        date: DateTime.now().subtract(const Duration(days: 7)),
        gallons: 13.2,
        pricePerGallon: 3.48,
        totalCost: 45.94,
        mileage: 340,
        location: 'Exxon Station - Mall',
        fuelType: FuelType.regular,
        octaneRating: 87,
      ),
    ];

    // Calculate analytics
    _calculateAnalytics();

    // Initialize nearby stations
    _nearbyStations = [
      FuelStation(
        id: 'station_1',
        name: 'Shell',
        address: '123 Main St, Downtown',
        distance: 0.8,
        price: 3.45,
        fuelTypes: [FuelType.regular, FuelType.premium],
        rating: 4.2,
        amenities: ['Car Wash', 'Convenience Store'],
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      FuelStation(
        id: 'station_2',
        name: 'BP',
        address: '456 Highway Ave',
        distance: 1.2,
        price: 3.42,
        fuelTypes: [FuelType.regular, FuelType.diesel],
        rating: 4.5,
        amenities: ['ATM', 'Restrooms'],
        lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      FuelStation(
        id: 'station_3',
        name: 'Exxon',
        address: '789 Commerce Blvd',
        distance: 2.1,
        price: 3.51,
        fuelTypes: [FuelType.regular, FuelType.premium, FuelType.diesel],
        rating: 3.8,
        amenities: ['Deli', 'Car Wash', 'ATM'],
        lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];

    // Initialize driving patterns
    _drivingPatterns = {
      'city': const FuelPattern(
        id: 'city',
        name: 'City Driving',
        description: 'Stop-and-go traffic patterns',
        averageEfficiency: 28.5,
        optimalSpeed: 35,
        frequency: 0.6,
        recommendations: [
          'Avoid rush hour',
          'Use cruise control',
          'Maintain steady speed',
        ],
      ),
      'highway': const FuelPattern(
        id: 'highway',
        name: 'Highway Driving',
        description: 'Long distance highway travel',
        averageEfficiency: 32.1,
        optimalSpeed: 65,
        frequency: 0.3,
        recommendations: [
          'Maintain highway speeds',
          'Reduce wind resistance',
          'Plan routes',
        ],
      ),
      'mixed': const FuelPattern(
        id: 'mixed',
        name: 'Mixed Driving',
        description: 'Combination of city and highway',
        averageEfficiency: 30.2,
        optimalSpeed: 50,
        frequency: 0.1,
        recommendations: [
          'Alternate driving styles',
          'Monitor fuel consumption',
          'Adjust driving habits',
        ],
      ),
    };

    // Generate predictions
    _generatePredictions();
  }

  void _calculateAnalytics() {
    if (_fuelHistory.isEmpty) return;

    final totalGallons =
        _fuelHistory.fold<double>(0, (sum, entry) => sum + entry.gallons);
    final totalCost =
        _fuelHistory.fold<double>(0, (sum, entry) => sum + entry.totalCost);
    final totalMileage =
        _fuelHistory.fold<double>(0, (sum, entry) => sum + entry.mileage);

    _analytics = FuelAnalytics(
      averageEfficiency: totalMileage / totalGallons,
      totalFuelCost: totalCost,
      totalGallons: totalGallons,
      totalMileage: totalMileage,
      averagePricePerGallon: totalCost / totalGallons,
      fuelCostPerMile: totalCost / totalMileage,
      bestEfficiency: _fuelHistory.isNotEmpty
          ? _fuelHistory.map((e) => e.mileage / e.gallons).reduce(max)
          : 0.0,
      worstEfficiency: _fuelHistory.isNotEmpty
          ? _fuelHistory.map((e) => e.mileage / e.gallons).reduce(min)
          : 0.0,
      efficiencyTrend: 0.05, // Mock trend
      monthlyBudget: 200.0,
      monthlyUsage: totalCost * 2, // Approximate monthly usage
    );
  }

  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _updateRealTimeData();
      }
    });
  }

  void _updateRealTimeData() {
    setState(() {
      // Simulate real-time fuel efficiency changes
      final baseEfficiency = 30.0;
      final variation = (Random().nextDouble() - 0.5) * 10;
      _currentEfficiency = max(15.0, min(45.0, baseEfficiency + variation));

      // Simulate instant consumption
      _instantFuelConsumption =
          _currentEfficiency * (Random().nextDouble() * 0.5 + 0.5);
    });
  }

  void _generatePredictions() {
    _predictions = [
      FuelPrediction(
        id: 'pred_1',
        type: PredictionType.fuelLevel,
        description: 'Fuel level will be low in 45 miles',
        confidence: 0.85,
        estimatedTime: DateTime.now().add(const Duration(hours: 1)),
        recommendedAction: 'Plan fuel stop at next station',
        savings: 5.20,
      ),
      FuelPrediction(
        id: 'pred_2',
        type: PredictionType.efficiency,
        description: 'Efficiency could improve by 8% with route optimization',
        confidence: 0.72,
        estimatedTime: DateTime.now().add(const Duration(minutes: 30)),
        recommendedAction: 'Take suggested alternate route',
        savings: 12.50,
      ),
      FuelPrediction(
        id: 'pred_3',
        type: PredictionType.cost,
        description: 'Fuel prices expected to rise 5% in next 2 days',
        confidence: 0.65,
        estimatedTime: DateTime.now().add(const Duration(days: 2)),
        recommendedAction: 'Fill up tank now if possible',
        savings: 8.75,
      ),
    ];
  }

  @override
  void dispose() {
    _fuelController.dispose();
    _monitoringTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Optimizer'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isOptimizing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddFuelEntry,
            tooltip: 'Add Fuel Entry',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'stations':
                  _showNearbyStations();
                  break;
                case 'patterns':
                  _showDrivingPatterns();
                  break;
                case 'export':
                  _exportFuelData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stations',
                child: Text('Nearby Stations'),
              ),
              const PopupMenuItem(
                value: 'patterns',
                child: Text('Driving Patterns'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Data'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real-time efficiency display
            _buildRealTimeEfficiency(),

            const SizedBox(height: 24),

            // Fuel analytics overview
            _buildAnalyticsOverview(),

            const SizedBox(height: 24),

            // AI predictions
            _buildPredictions(),

            const SizedBox(height: 24),

            // Fuel history
            _buildFuelHistory(),

            const SizedBox(height: 24),

            // Optimization plan
            _buildOptimizationPlan(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startOptimization,
        tooltip: 'Start AI Optimization',
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }

  Widget _buildRealTimeEfficiency() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.speed,
                    size: 32,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Efficiency',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${_currentEfficiency.toStringAsFixed(1)} MPG',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Instant: ${_instantFuelConsumption.toStringAsFixed(2)} gal/hr',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: _currentEfficiency / 40.0, // Assuming 40 MPG is max
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getEfficiencyColor(_currentEfficiency),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEfficiencyMetric(
                    'Average',
                    '${_analytics.averageEfficiency.toStringAsFixed(1)} MPG',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildEfficiencyMetric(
                    'Best',
                    '${_analytics.bestEfficiency.toStringAsFixed(1)} MPG',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildEfficiencyMetric(
                    'Savings',
                    '\$${_analytics.monthlyBudget - _analytics.monthlyUsage > 0 ? (_analytics.monthlyBudget - _analytics.monthlyUsage).toStringAsFixed(0) : "0"}',
                    Icons.savings,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fuel Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem(
                    'Total Cost',
                    '\$${_analytics.totalFuelCost.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Gallons Used',
                    _analytics.totalGallons.toStringAsFixed(1),
                    Icons.local_gas_station,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Miles Driven',
                    _analytics.totalMileage.toStringAsFixed(0),
                    Icons.directions_car,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _analytics.efficiencyTrend >= 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _analytics.efficiencyTrend >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: _analytics.efficiencyTrend >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Efficiency trend: ${(_analytics.efficiencyTrend * 100).toStringAsFixed(1)}% ${_analytics.efficiencyTrend >= 0 ? "improvement" : "decline"}',
                      style: TextStyle(
                        color: _analytics.efficiencyTrend >= 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPredictions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'AI Predictions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Smart',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._predictions
                .map((prediction) => _buildPredictionItem(prediction)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(FuelPrediction prediction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  _getPredictionColor(prediction.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPredictionIcon(prediction.type),
              color: _getPredictionColor(prediction.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prediction.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prediction.recommendedAction,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Save \$${prediction.savings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(prediction.confidence * 100).toInt()}% confident',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () => _applyPrediction(prediction),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fuel History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._fuelHistory.take(3).map((entry) => _buildFuelEntry(entry)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _showFullHistory,
              icon: const Icon(Icons.history),
              label: const Text('View All History'),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelEntry(FuelEntry entry) {
    final efficiency = entry.mileage / entry.gallons;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_gas_station,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.location,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${entry.date.month}/${entry.date.day}/${entry.date.year} • ${entry.gallons.toStringAsFixed(1)} gal',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${entry.totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${efficiency.toStringAsFixed(1)} MPG',
                style: TextStyle(
                  fontSize: 12,
                  color: _getEfficiencyColor(efficiency),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationPlan() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optimization Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentPlan.recommendations.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Tap the AI button to generate personalized fuel optimization recommendations',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ] else ...[
              ..._currentPlan.recommendations
                  .map((rec) => _buildRecommendation(rec)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _applyOptimizationPlan,
                      icon: const Icon(Icons.check),
                      label: const Text('Apply All'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(OptimizationRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getRecommendationIcon(rec.type),
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  rec.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (rec.potentialSavings > 0)
                  Text(
                    'Potential savings: \$${rec.potentialSavings.toStringAsFixed(2)}/month',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Checkbox(
            value: rec.isApplied,
            onChanged: (value) => _toggleRecommendation(rec.id, value ?? false),
          ),
        ],
      ),
    );
  }

  void _showAddFuelEntry() {
    // Implementation for adding fuel entry
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add fuel entry feature coming soon!')),
    );
  }

  void _showNearbyStations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nearby Fuel Stations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _nearbyStations.length,
                  itemBuilder: (context, index) {
                    final station = _nearbyStations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_gas_station,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          station.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Text(
                          '${station.distance.toStringAsFixed(1)} miles • \$${station.price.toStringAsFixed(2)}/gal',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            Text(station.rating.toStringAsFixed(1)),
                          ],
                        ),
                        onTap: () => _navigateToStation(station),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDrivingPatterns() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Driving Patterns',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: _drivingPatterns.values.map((pattern) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  pattern.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(pattern.frequency * 100).toInt()}% of trips',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pattern.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${pattern.averageEfficiency.toStringAsFixed(1)} MPG',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const Text(
                                        'Avg Efficiency',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${pattern.optimalSpeed} MPH',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const Text(
                                        'Optimal Speed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Recommendations:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...pattern.recommendations.map(
                              (rec) => Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, bottom: 4),
                                child: Row(
                                  children: [
                                    const Text(
                                      '• ',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Expanded(
                                      child: Text(
                                        rec,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullHistory() {
    // Implementation for full fuel history
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full fuel history feature coming soon!')),
    );
  }

  void _exportFuelData() {
    // Implementation for data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export feature coming soon!')),
    );
  }

  void _startOptimization() {
    setState(() => _isOptimizing = true);

    // Simulate AI optimization process
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isOptimizing = false;
          _currentPlan = FuelOptimizationPlan(
            recommendations: [
              OptimizationRecommendation(
                id: 'rec_1',
                type: RecommendationType.driving,
                title: 'Optimize Driving Habits',
                description:
                    'Maintain steady speeds and avoid sudden acceleration',
                potentialSavings: 15.50,
                isApplied: false,
              ),
              OptimizationRecommendation(
                id: 'rec_2',
                type: RecommendationType.maintenance,
                title: 'Regular Maintenance',
                description:
                    'Keep tires properly inflated and oil changed regularly',
                potentialSavings: 8.75,
                isApplied: false,
              ),
              OptimizationRecommendation(
                id: 'rec_3',
                type: RecommendationType.routing,
                title: 'Smart Route Planning',
                description:
                    'Use navigation apps to find fuel-efficient routes',
                potentialSavings: 12.25,
                isApplied: false,
              ),
              OptimizationRecommendation(
                id: 'rec_4',
                type: RecommendationType.fuel,
                title: 'Fuel Station Selection',
                description:
                    'Choose stations with competitive prices and good ratings',
                potentialSavings: 6.80,
                isApplied: false,
              ),
            ],
          );
        });
      }
    });
  }

  void _applyPrediction(FuelPrediction prediction) {
    // Implementation for applying prediction
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied: ${prediction.recommendedAction}')),
    );
  }

  void _navigateToStation(FuelStation station) {
    // Implementation for navigation to station
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to ${station.name}')),
    );
  }

  void _applyOptimizationPlan() {
    // Implementation for applying optimization plan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Optimization plan applied!')),
    );
  }

  void _toggleRecommendation(String id, bool applied) {
    setState(() {
      final rec = _currentPlan.recommendations.firstWhere((r) => r.id == id);
      rec.isApplied = applied;
    });
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 35) return Colors.green;
    if (efficiency >= 25) return Colors.yellow;
    return Colors.red;
  }

  Color _getPredictionColor(PredictionType type) {
    switch (type) {
      case PredictionType.fuelLevel:
        return Colors.orange;
      case PredictionType.efficiency:
        return Colors.blue;
      case PredictionType.cost:
        return Colors.red;
    }
  }

  IconData _getPredictionIcon(PredictionType type) {
    switch (type) {
      case PredictionType.fuelLevel:
        return Icons.local_gas_station;
      case PredictionType.efficiency:
        return Icons.speed;
      case PredictionType.cost:
        return Icons.attach_money;
    }
  }

  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.driving:
        return Icons.drive_eta;
      case RecommendationType.maintenance:
        return Icons.build;
      case RecommendationType.routing:
        return Icons.navigation;
      case RecommendationType.fuel:
        return Icons.local_gas_station;
    }
  }
}

// Data Models
enum FuelType { regular, premium, diesel }

enum PredictionType { fuelLevel, efficiency, cost }

enum RecommendationType { driving, maintenance, routing, fuel }

class FuelAnalytics {
  final double averageEfficiency;
  final double totalFuelCost;
  final double totalGallons;
  final double totalMileage;
  final double averagePricePerGallon;
  final double fuelCostPerMile;
  final double bestEfficiency;
  final double worstEfficiency;
  final double efficiencyTrend;
  final double monthlyBudget;
  final double monthlyUsage;

  const FuelAnalytics({
    this.averageEfficiency = 0.0,
    this.totalFuelCost = 0.0,
    this.totalGallons = 0.0,
    this.totalMileage = 0.0,
    this.averagePricePerGallon = 0.0,
    this.fuelCostPerMile = 0.0,
    this.bestEfficiency = 0.0,
    this.worstEfficiency = 0.0,
    this.efficiencyTrend = 0.0,
    this.monthlyBudget = 0.0,
    this.monthlyUsage = 0.0,
  });
}

class FuelEntry {
  final String id;
  final DateTime date;
  final double gallons;
  final double pricePerGallon;
  final double totalCost;
  final double mileage;
  final String location;
  final FuelType fuelType;
  final int octaneRating;

  const FuelEntry({
    required this.id,
    required this.date,
    required this.gallons,
    required this.pricePerGallon,
    required this.totalCost,
    required this.mileage,
    required this.location,
    required this.fuelType,
    required this.octaneRating,
  });
}

class FuelStation {
  final String id;
  final String name;
  final String address;
  final double distance;
  final double price;
  final List<FuelType> fuelTypes;
  final double rating;
  final List<String> amenities;
  final DateTime lastUpdated;

  const FuelStation({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.price,
    required this.fuelTypes,
    required this.rating,
    required this.amenities,
    required this.lastUpdated,
  });
}

class FuelPattern {
  final String id;
  final String name;
  final String description;
  final double averageEfficiency;
  final int optimalSpeed;
  final double frequency;
  final List<String> recommendations;

  const FuelPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.averageEfficiency,
    required this.optimalSpeed,
    required this.frequency,
    required this.recommendations,
  });
}

class FuelPrediction {
  final String id;
  final PredictionType type;
  final String description;
  final double confidence;
  final DateTime estimatedTime;
  final String recommendedAction;
  final double savings;

  const FuelPrediction({
    required this.id,
    required this.type,
    required this.description,
    required this.confidence,
    required this.estimatedTime,
    required this.recommendedAction,
    required this.savings,
  });
}

class FuelOptimizationPlan {
  final List<OptimizationRecommendation> recommendations;

  const FuelOptimizationPlan({
    this.recommendations = const [],
  });
}

class OptimizationRecommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final double potentialSavings;
  bool isApplied;

  OptimizationRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.isApplied,
  });
}

