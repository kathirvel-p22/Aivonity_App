import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../widgets/rca_report_card.dart';
import '../widgets/maintenance_insights_chart.dart';
import '../widgets/trend_analysis_widget.dart';
import '../providers/analytics_provider.dart';
import '../models/rca_report.dart';

/// AIVONITY RCA Reports Screen
/// Advanced analytics and root cause analysis interface
class RCAReportsScreen extends ConsumerStatefulWidget {
  final String? vehicleId;

  const RCAReportsScreen({
    super.key,
    this.vehicleId,
  });

  @override
  ConsumerState<RCAReportsScreen> createState() => _RCAReportsScreenState();
}

class _RCAReportsScreenState extends ConsumerState<RCAReportsScreen>
    with TickerProviderStateMixin, LoggingMixin {
  late TabController _tabController;
  String _selectedTimeRange = '30D';
  String _selectedCategory = 'All';

  final List<String> _timeRanges = ['7D', '30D', '90D', '1Y'];
  final List<String> _categories = [
    'All',
    'Engine',
    'Transmission',
    'Brakes',
    'Electrical',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load analytics data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).loadRCAReports(
            vehicleId: widget.vehicleId,
            timeRange: _selectedTimeRange,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filters
          _buildFilters(),

          // Tab Bar
          _buildTabBar(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsTab(analyticsState),
                _buildInsightsTab(analyticsState),
                _buildTrendsTab(analyticsState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: Text(
        'Analytics & Reports',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _exportReports,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareReports,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Time Range Filter
          Row(
            children: [
              Text(
                'Time Range:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _timeRanges.map((range) {
                      final isSelected = _selectedTimeRange == range;
                      return GestureDetector(
                        onTap: () => _onTimeRangeChanged(range),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            range,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Category Filter
          Row(
            children: [
              Text(
                'Category:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: Container(),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _onCategoryChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: const [
          Tab(text: 'Reports'),
          Tab(text: 'Insights'),
          Tab(text: 'Trends'),
        ],
      ),
    );
  }

  Widget _buildReportsTab(AsyncValue<AnalyticsData> analyticsState) {
    return analyticsState.when(
      data: (data) => _buildReportsList(data.rcaReports),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildReportsList(List<RCAReport> reports) {
    if (reports.isEmpty) {
      return _buildEmptyState('No reports available for the selected period');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return RCAReportCard(
          report: report,
          onTap: () => _viewReportDetails(report),
        );
      },
    );
  }

  Widget _buildInsightsTab(AsyncValue<AnalyticsData> analyticsState) {
    return analyticsState.when(
      data: (data) => _buildInsightsContent(data),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildInsightsContent(AnalyticsData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics
          _buildKeyMetrics(data),

          const SizedBox(height: 24),

          // Maintenance Insights Chart
          Text(
            'Maintenance Patterns',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          MaintenanceInsightsChart(
            data: data.maintenanceData,
          ),

          const SizedBox(height: 24),

          // Recommendations
          _buildRecommendations(data.recommendations),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(AsyncValue<AnalyticsData> analyticsState) {
    return analyticsState.when(
      data: (data) => _buildTrendsContent(data),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTrendsContent(AnalyticsData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Analysis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TrendAnalysisWidget(
            trendData: data.trendData,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(AnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Key Insights',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Total Issues',
                  data.totalIssues.toString(),
                  Icons.warning,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Resolved',
                  data.resolvedIssues.toString(),
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Avg Resolution',
                  '${data.avgResolutionTime}h',
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecommendations(List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...recommendations.map((recommendation) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load analytics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.refresh(analyticsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Event Handlers
  void _onTimeRangeChanged(String range) {
    setState(() {
      _selectedTimeRange = range;
    });

    ref.read(analyticsProvider.notifier).loadRCAReports(
          vehicleId: widget.vehicleId,
          timeRange: range,
        );
  }

  void _onCategoryChanged(String category) {
    ref.read(analyticsProvider.notifier).filterByCategory(category);
  }

  void _viewReportDetails(RCAReport report) {
    Navigator.of(context).pushNamed(
      '/rca-report-details',
      arguments: report,
    );
  }

  void _exportReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting reports...'),
      ),
    );

    // In a real app, this would export to PDF or other formats
    ref.read(analyticsProvider.notifier).exportReports();
  }

  void _shareReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing reports...'),
      ),
    );

    // In a real app, this would share via email or other methods
    ref.read(analyticsProvider.notifier).shareReports();
  }
}

