import 'package:flutter/material.dart';
import 'dart:math' as math;

/// AIVONITY Animated Metric Card
/// Real-time animated gauge for vehicle metrics
class AnimatedMetricCard extends StatefulWidget {
  final String title;
  final double value;
  final double maxValue;
  final String unit;
  final Color color;
  final IconData icon;

  const AnimatedMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.maxValue,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  State<AnimatedMetricCard> createState() => _AnimatedMetricCardState();
}

class _AnimatedMetricCardState extends State<AnimatedMetricCard>
    with TickerProviderStateMixin {
  late AnimationController _valueController;
  late AnimationController _pulseController;
  late Animation<double> _valueAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _valueController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _valueAnimation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _valueController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _valueController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedMetricCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _valueAnimation = Tween<double>(begin: oldWidget.value, end: widget.value)
          .animate(
            CurvedAnimation(
              parent: _valueController,
              curve: Curves.easeOutCubic,
            ),
          );

      _valueController.reset();
      _valueController.forward();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: widget.color.withValues(alpha:0.1), width: 1),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Animated Gauge
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background arc
                CustomPaint(
                  size: const Size(120, 120),
                  painter: GaugePainter(
                    progress: 1.0,
                    color: widget.color.withValues(alpha:0.1),
                    strokeWidth: 8,
                  ),
                ),

                // Animated progress arc
                AnimatedBuilder(
                  animation: _valueAnimation,
                  builder: (context, child) {
                    final progress = _valueAnimation.value / widget.maxValue;
                    return CustomPaint(
                      size: const Size(120, 120),
                      painter: GaugePainter(
                        progress: progress.clamp(0.0, 1.0),
                        color: widget.color,
                        strokeWidth: 8,
                      ),
                    );
                  },
                ),

                // Center value
                AnimatedBuilder(
                  animation: _valueAnimation,
                  builder: (context, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _valueAnimation.value.toInt().toString(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.color,
                              ),
                        ),
                        Text(
                          widget.unit,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha:0.6),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    );
                  },
                ),

                // Pulse effect for active metrics
                if (widget.value > 0)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.color.withValues(alpha:0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress bar
          AnimatedBuilder(
            animation: _valueAnimation,
            builder: (context, child) {
              final progress = _valueAnimation.value / widget.maxValue;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha:0.6),
                        ),
                      ),
                      Text(
                        widget.maxValue.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha:0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: widget.color.withValues(alpha:0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                    minHeight: 4,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter for gauge arc
class GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  GaugePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arc from -135 degrees to +135 degrees (270 degrees total)
    const startAngle = -3 * math.pi / 4; // -135 degrees
    const totalAngle = 3 * math.pi / 2; // 270 degrees
    final sweepAngle = totalAngle * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is GaugePainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.color != color ||
            oldDelegate.strokeWidth != strokeWidth);
  }
}

