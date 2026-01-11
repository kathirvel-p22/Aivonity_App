import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// AIVONITY Health Score Card
/// Animated circular progress indicator with health score
class HealthScoreCard extends StatefulWidget {
  final double score;
  final double? trend;
  final VoidCallback? onTap;

  const HealthScoreCard({
    super.key,
    required this.score,
    this.trend,
    this.onTap,
  });

  @override
  State<HealthScoreCard> createState() => _HealthScoreCardState();
}

class _HealthScoreCardState extends State<HealthScoreCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.score).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _progressController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _getHealthGradient(widget.score),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _getHealthColor(widget.score).withValues(alpha:0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehicle Health',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getHealthStatus(widget.score),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (widget.trend != null)
                        _buildTrendIndicator(widget.trend!),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Circular Progress
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 12,
                            backgroundColor: Colors.white.withValues(alpha:0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha:0.1),
                            ),
                          ),
                        ),

                        // Animated progress
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: _progressAnimation.value,
                                strokeWidth: 12,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            );
                          },
                        ),

                        // Score text
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(_progressAnimation.value * 100).toInt()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'SCORE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha:0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
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
    final isNeutral = trend == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNeutral
                ? Icons.remove
                : isPositive
                ? Icons.trending_up
                : Icons.trending_down,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isNeutral
                ? '0%'
                : '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(double score) {
    return AppTheme.getHealthScoreColor(score);
  }

  LinearGradient _getHealthGradient(double score) {
    final color = _getHealthColor(score);
    return LinearGradient(
      colors: [color, color.withValues(alpha:0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _getHealthStatus(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.7) return 'Good';
    if (score >= 0.5) return 'Fair';
    if (score >= 0.3) return 'Poor';
    return 'Critical';
  }
}

