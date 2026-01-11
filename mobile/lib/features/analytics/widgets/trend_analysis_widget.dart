import 'package:flutter/material.dart';

/// AIVONITY Trend Analysis Widget
/// Displays trend analysis charts and insights
class TrendAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic> trendData;

  const TrendAnalysisWidget({super.key, required this.trendData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Issue Frequency Trend
        _buildIssueFrequencyTrend(context),

        const SizedBox(height: 24),

        // Resolution Time by Category
        _buildResolutionTimeTrend(context),
      ],
    );
  }

  Widget _buildIssueFrequencyTrend(BuildContext context) {
    final frequencyData =
        trendData['issueFrequency'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issue Frequency Trend',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: LineChartPainter(
                data: frequencyData,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Container(),
            ),
          ),

          const SizedBox(height: 16),

          // Week Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: frequencyData.map((item) {
              return Text(
                item['week'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionTimeTrend(BuildContext context) {
    final resolutionData =
        trendData['resolutionTime'] as List<Map<String, dynamic>>;
    final maxHours = resolutionData
        .map((item) => item['avgHours'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average Resolution Time by Category',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          ...resolutionData.map((item) {
            final category = item['category'] as String;
            final avgHours = item['avgHours'] as int;
            final progress = avgHours / maxHours;
            final color = _getCategoryColor(category);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${avgHours}h',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
      default:
        return Colors.teal;
    }
  }
}

/// Custom painter for line chart
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color color;

  LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (data.isEmpty) return;

    final maxIssues = data
        .map((item) => item['issues'] as int)
        .reduce((a, b) => a > b ? a : b);

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final issues = data[i]['issues'] as int;
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (issues / maxIssues) * size.height;

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw line
    canvas.drawPath(path, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Draw area under curve
    final areaPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final areaPath = Path.from(path);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    canvas.drawPath(areaPath, areaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

