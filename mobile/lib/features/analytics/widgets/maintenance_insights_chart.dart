import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AIVONITY Maintenance Insights Chart Widget
/// Displays maintenance patterns and category breakdowns
class MaintenanceInsightsChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const MaintenanceInsightsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
          // Monthly Maintenance Trend
          _buildMonthlyTrend(context),

          const SizedBox(height: 24),

          // Category Breakdown
          _buildCategoryBreakdown(context),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrend(BuildContext context) {
    final monthlyData =
        data['monthlyMaintenance'] as List<Map<String, dynamic>>;
    final maxCount = monthlyData
        .map((item) => item['count'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Maintenance Trend',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: monthlyData.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final month = item['month'] as String;
              final count = item['count'] as int;
              final height = (count / maxCount) * 100;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bar
                      AnimatedContainer(
                            duration: Duration(milliseconds: 800 + index * 100),
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha:0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                count.toString(),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          )
                          .animate(delay: Duration(milliseconds: index * 200))
                          .slideY(begin: 1.0, duration: 600.ms)
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 8),

                      // Month Label
                      Text(
                        month,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha:0.7),
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
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    final categoryData =
        data['categoryBreakdown'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Issue Categories',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        ...categoryData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final category = item['category'] as String;
          final percentage = item['percentage'] as int;
          final color = _getCategoryColor(category);

          return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Category Indicator
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Category Name
                    Expanded(
                      flex: 2,
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Progress Bar
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: color.withValues(alpha:0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Percentage
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: index * 150))
              .fadeIn(duration: 600.ms)
              .slideX(begin: 0.3);
        }),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'engine':
        return Colors.red;
      case 'brakes':
        return Colors.orange;
      case 'electrical':
        return Colors.blue;
      case 'transmission':
        return Colors.purple;
      case 'other':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }
}

