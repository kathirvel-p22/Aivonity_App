import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';
import '../widgets/interactive_line_chart.dart';
import '../widgets/kpi_metrics_dashboard.dart';
import '../widgets/performance_metrics_display.dart';

class AnalyticsDashboard extends StatefulWidget {
  final String vehicleId;

  const AnalyticsDashboard({super.key, required this.vehicleId});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with TickerProviderStateMixin {
  late final AnalyticsService _analyticsService;
  late final TabController _tabController;

  PerformanceMetrics? _currentMetrics;
  TrendAnalysis? _trendAnalysis;
  List<KPIMetric> _kpiMetrics = [];
  ChartData? _chartData;
  TimePeriod _selectedPeriod = TimePeriod.week;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyticsService = GetIt.instance<AnalyticsService>();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _analyticsService.getPerformanceMetrics(
          widget.vehicleId,
          _selectedPeriod,
        ),
        _analyticsService.getTrendAnalysis(widget.vehicleId, _selectedPeriod),
        _analyticsService.getKPIMetrics(widget.vehicleId),
        _analyticsService.getChartData(
          widget.vehicleId,
          ChartType.line,
          _selectedPeriod,
        ),
      ]);

      setState(() {
        _currentMetrics = futures[0] as PerformanceMetrics;
        _trendAnalysis = futures[1] as TrendAnalysis;
        _kpiMetrics = futures[2] as List<KPIMetric>;
        _chartData = futures[3] as ChartData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load analytics data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<TimePeriod>(
            icon: const Icon(Icons.date_range),
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadAnalyticsData();
            },
            itemBuilder: (context) => TimePeriod.values.map((period) {
              return PopupMenuItem(
                value: period,
                child: Row(
                  children: [
                    if (period == _selectedPeriod)
                      const Icon(Icons.check, size: 16),
                    if (period == _selectedPeriod) const SizedBox(width: 8),
                    Text(_getPeriodDisplayName(period)),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.analytics), text: 'KPIs'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildKPITab(),
              ],
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
            onPressed: _loadAnalyticsData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_currentMetrics != null)
            PerformanceMetricsDisplay(
              metrics: _currentMetrics!,
              trendAnalysis: _trendAnalysis,
            ),
          const SizedBox(height: 16),
          if (_chartData != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: InteractiveLineChart(
                chartData: _chartData!,
                height: 300,
                onPointTap: (dataPoint) {
                  if (dataPoint != null) {
                    _showDataPointDetails(dataPoint);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_chartData != null) ...[
            Card(
              margin: const EdgeInsets.all(16),
              child: InteractiveLineChart(
                chartData: _chartData!,
                height: 400,
                onPointTap: (dataPoint) {
                  if (dataPoint != null) {
                    _showDataPointDetails(dataPoint);
                  }
                },
              ),
            ),
            _buildTrendInsights(),
          ],
        ],
      ),
    );
  }

  Widget _buildKPITab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          KPIMetricsDashboard(
            metrics: _kpiMetrics,
            onMetricTap: (metric) {
              _showKPIDetails(metric);
            },
          ),
          _buildKPIComparison(),
        ],
      ),
    );
  }

  Widget _buildTrendInsights() {
    if (_trendAnalysis == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Insights',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInsightRow(
              'Fuel Efficiency Trend',
              _trendAnalysis!.fuelEfficiencyTrend.isNotEmpty
                  ? _calculateTrendDirection(
                      _trendAnalysis!.fuelEfficiencyTrend,
                    )
                  : 'No data',
              Icons.local_gas_station,
            ),
            _buildInsightRow(
              'Performance Trend',
              _trendAnalysis!.performanceTrend.isNotEmpty
                  ? _calculateTrendDirection(_trendAnalysis!.performanceTrend)
                  : 'No data',
              Icons.speed,
            ),
            _buildInsightRow(
              'Maintenance Cost Trend',
              _trendAnalysis!.maintenanceCostTrend.isNotEmpty
                  ? _calculateTrendDirection(
                      _trendAnalysis!.maintenanceCostTrend,
                    )
                  : 'No data',
              Icons.build,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String title, String trend, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            trend,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: _getTrendTextColor(trend),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIComparison() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._kpiMetrics.map((metric) => _buildKPISummaryRow(metric)),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISummaryRow(KPIMetric metric) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              metric.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Row(
            children: [
              Text(
                '${metric.currentValue.toStringAsFixed(1)} ${metric.unit}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getKPITrendColor(metric.trend).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${metric.changePercentage > 0 ? '+' : ''}${metric.changePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getKPITrendColor(metric.trend),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDataPointDetails(DataPoint dataPoint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Point Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Value: ${dataPoint.value.toStringAsFixed(2)}'),
            Text('Date: ${dataPoint.timestamp.toString().split(' ')[0]}'),
            if (dataPoint.label != null) Text('Label: ${dataPoint.label}'),
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

  void _showKPIDetails(KPIMetric metric) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(metric.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: ${metric.currentValue} ${metric.unit}'),
            Text('Previous: ${metric.previousValue} ${metric.unit}'),
            Text('Change: ${metric.changePercentage.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            Text(
              metric.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
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

  String _calculateTrendDirection(List<DataPoint> data) {
    if (data.length < 2) return 'Insufficient data';

    final first = data.first.value;
    final last = data.last.value;
    final change = ((last - first) / first) * 100;

    if (change > 5) return 'Improving';
    if (change < -5) return 'Declining';
    return 'Stable';
  }

  Color _getTrendTextColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getKPITrendColor(KPITrend trend) {
    switch (trend) {
      case KPITrend.improving:
        return Colors.green;
      case KPITrend.declining:
        return Colors.red;
      case KPITrend.stable:
        return Colors.orange;
    }
  }
}

