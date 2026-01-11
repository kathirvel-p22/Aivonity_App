import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/predictive_analytics.dart';
import '../models/analytics.dart' show TimePeriod;
import '../services/predictive_analytics_service.dart';
import '../widgets/maintenance_predictions_widget.dart';

class PredictiveAnalyticsDashboard extends StatefulWidget {
  final String vehicleId;

  const PredictiveAnalyticsDashboard({super.key, required this.vehicleId});

  @override
  State<PredictiveAnalyticsDashboard> createState() =>
      _PredictiveAnalyticsDashboardState();
}

class _PredictiveAnalyticsDashboardState
    extends State<PredictiveAnalyticsDashboard>
    with TickerProviderStateMixin {
  late final PredictiveAnalyticsService _predictiveService;
  late final TabController _tabController;
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  List<MaintenancePrediction> _predictions = [];
  List<PredictiveInsight> _insights = [];
  MaintenanceSchedule? _schedule;
  List<PredictionModel> _models = [];
  bool _isLoading = true;
  String? _error;

  // Premium gradient colors
  static const List<Color> _primaryGradient = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
  ];

  static const List<Color> _successGradient = [
    Color(0xFF11998e),
    Color(0xFF38ef7d),
  ];

  static const List<Color> _warningGradient = [
    Color(0xFFf093fb),
    Color(0xFFf5576c),
  ];

  static const List<Color> _infoGradient = [
    Color(0xFF4facfe),
    Color(0xFF00f2fe),
  ];

  @override
  void initState() {
    super.initState();
    _predictiveService = GetIt.instance<PredictiveAnalyticsService>();
    _tabController = TabController(length: 4, vsync: this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _loadPredictiveData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPredictiveData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _predictiveService.getMaintenancePredictions(widget.vehicleId),
        _predictiveService.generateMaintenanceSchedule(
          widget.vehicleId,
          TimePeriod.month,
        ),
        _predictiveService.getAvailableModels(),
        _predictiveService.generateInsights(widget.vehicleId, []),
      ]);

      setState(() {
        _predictions = futures[0] as List<MaintenancePrediction>;
        _schedule = futures[1] as MaintenanceSchedule;
        _models = futures[2] as List<PredictionModel>;
        _insights = futures[3] as List<PredictiveInsight>;
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryGradient[0].withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildAnimatedAppBar(innerBoxIsScrolled),
          ],
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: _isLoading
                ? _buildLoadingIndicator()
                : _error != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPredictionsTab(),
                      _buildScheduleTab(),
                      _buildInsightsTab(),
                      _buildModelsTab(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      forceElevated: innerBoxIsScrolled,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Predictive Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _primaryGradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              const Positioned(
                right: 20,
                bottom: 60,
                child: Icon(Icons.auto_graph, size: 80, color: Colors.white24),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadPredictiveData,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.build_outlined), text: 'Predictions'),
          Tab(icon: Icon(Icons.schedule_outlined), text: 'Schedule'),
          Tab(icon: Icon(Icons.lightbulb_outlined), text: 'Insights'),
          Tab(icon: Icon(Icons.model_training), text: 'Models'),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _primaryGradient),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGradient[0].withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing vehicle data...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _warningGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Data',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildGradientButton(
              label: 'Retry',
              icon: Icons.refresh,
              gradient: _primaryGradient,
              onPressed: _loadPredictiveData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPredictionsSummary(),
          const SizedBox(height: 16),
          MaintenancePredictionsWidget(
            predictions: _predictions,
            onPredictionTap: _showPredictionDetails,
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: _primaryGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.summarize,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Predictions Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Critical',
                    criticalCount.toString(),
                    Icons.warning_rounded,
                    _warningGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'High Priority',
                    highCount.toString(),
                    Icons.priority_high_rounded,
                    [Colors.orange, Colors.deepOrange],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Cost',
                    '\$${totalCost.toStringAsFixed(0)}',
                    Icons.attach_money,
                    _successGradient,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    List<Color> gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient[0].withValues(alpha: 0.15),
            gradient[1].withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gradient[0].withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: gradient[0], size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: gradient[0],
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (_schedule == null) {
      return _buildEmptyState(
        icon: Icons.schedule_outlined,
        title: 'No Schedule Available',
        message: 'Maintenance schedule will appear here',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScheduleHeader(),
          const SizedBox(height: 16),
          ..._schedule!.scheduledItems.map((item) => _buildScheduleItem(item)),
        ],
      ),
    );
  }

  Widget _buildScheduleHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_infoGradient[0], _infoGradient[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _infoGradient[0].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Maintenance Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Period',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      _getPeriodDisplayName(_schedule!.period),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Estimated Cost',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '\$${_schedule!.totalEstimatedCost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(ScheduledMaintenance item) {
    final priorityColor = _getPriorityColor(item.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.isPreventive ? Icons.shield_outlined : Icons.build_outlined,
            color: priorityColor,
          ),
        ),
        title: Text(
          item.componentName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(item.description),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${item.estimatedCost.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: priorityColor,
              ),
            ),
            Text(
              '${item.estimatedDuration} min',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    if (_insights.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lightbulb_outline,
        title: 'No Insights Yet',
        message: 'Predictive insights will appear here',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _successGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Predictive Insights',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._insights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(PredictiveInsight insight) {
    final iconData = _getInsightIcon(insight.type);
    final gradient = _getInsightGradient(insight.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
            if (insight.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recommendations:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              ...insight.recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: gradient[0]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModelsTab() {
    if (_models.isEmpty) {
      return _buildEmptyState(
        icon: Icons.model_training,
        title: 'No Models Available',
        message: 'Prediction models will appear here',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _infoGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.model_training,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Prediction Models',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._models.map((model) => _buildModelCard(model)),
        ],
      ),
    );
  }

  Widget _buildModelCard(PredictionModel model) {
    final statusColor = _getModelStatusColor(model.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    model.modelName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    model.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildModelStat(
                  'Accuracy',
                  '${(model.accuracy * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(width: 24),
                _buildModelStat('Type', model.type.name),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showPredictionDetails(MaintenancePrediction prediction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              prediction.componentName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Predicted Failure',
              prediction.predictedFailureDate.toString().split(' ')[0],
            ),
            _buildDetailRow(
              'Confidence',
              '${(prediction.confidenceScore * 100).toStringAsFixed(1)}%',
            ),
            _buildDetailRow(
              'Estimated Cost',
              '\$${prediction.estimatedCost.toStringAsFixed(0)}',
            ),
            _buildDetailRow('Action', prediction.recommendedAction),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _buildGradientButton(
                label: 'Close',
                icon: Icons.close,
                gradient: _primaryGradient,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Colors.green;
      case MaintenancePriority.medium:
        return Colors.orange;
      case MaintenancePriority.high:
        return Colors.deepOrange;
      case MaintenancePriority.critical:
        return Colors.red;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.costOptimization:
        return Icons.savings;
      case InsightType.performanceImprovement:
        return Icons.trending_up;
      case InsightType.riskMitigation:
        return Icons.security;
      case InsightType.efficiencyEnhancement:
        return Icons.eco;
    }
  }

  List<Color> _getInsightGradient(InsightType type) {
    switch (type) {
      case InsightType.costOptimization:
        return _successGradient;
      case InsightType.performanceImprovement:
        return _infoGradient;
      case InsightType.riskMitigation:
        return _warningGradient;
      case InsightType.efficiencyEnhancement:
        return [Colors.teal, Colors.cyan];
    }
  }

  Color _getModelStatusColor(ModelStatus status) {
    switch (status) {
      case ModelStatus.active:
        return Colors.green;
      case ModelStatus.training:
        return Colors.orange;
      case ModelStatus.deprecated:
        return Colors.grey;
      case ModelStatus.error:
        return Colors.red;
    }
  }

  String _getPeriodDisplayName(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return 'Day';
      case TimePeriod.week:
        return 'Week';
      case TimePeriod.month:
        return 'Month';
      case TimePeriod.quarter:
        return 'Quarter';
      case TimePeriod.year:
        return 'Year';
    }
  }
}

