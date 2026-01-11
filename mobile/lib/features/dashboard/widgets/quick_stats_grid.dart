import 'package:flutter/material.dart';

/// Quick Stat Model
class QuickStat {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double trend;

  const QuickStat({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.trend = 0.0,
  });
}

/// AIVONITY Quick Stats Grid
/// Animated grid of key vehicle metrics
class QuickStatsGrid extends StatelessWidget {
  final List<QuickStat> stats;

  const QuickStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return QuickStatCard(stat: stat, index: index);
      },
    );
  }
}

/// Individual stat card with animations
class QuickStatCard extends StatefulWidget {
  final QuickStat stat;
  final int index;

  const QuickStatCard({super.key, required this.stat, required this.index});

  @override
  State<QuickStatCard> createState() => _QuickStatCardState();
}

class _QuickStatCardState extends State<QuickStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _hoverController.forward();
      },
      onTapUp: (_) {
        _hoverController.reverse();
      },
      onTapCancel: () {
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.stat.color.withValues(alpha: 0.1),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
                border: Border.all(
                  color: widget.stat.color.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and trend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.stat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.stat.icon,
                          color: widget.stat.color,
                          size: 24,
                        ),
                      ),
                      if (widget.stat.trend != 0)
                        _buildTrendIndicator(widget.stat.trend),
                    ],
                  ),

                  const Spacer(),

                  // Value
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.stat.value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          widget.stat.unit,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    widget.stat.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendIndicator(double trend) {
    final isPositive = trend > 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

