import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// AIVONITY Health Ring Chart
/// Multi-ring animated chart showing component health
class HealthRingChart extends StatefulWidget {
  final double engineHealth;
  final double batteryHealth;
  final double transmissionHealth;
  final double brakesHealth;

  const HealthRingChart({
    super.key,
    required this.engineHealth,
    required this.batteryHealth,
    required this.transmissionHealth,
    required this.brakesHealth,
  });

  @override
  State<HealthRingChart> createState() => _HealthRingChartState();
}

class _HealthRingChartState extends State<HealthRingChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _ringAnimations;

  final List<ComponentData> _components = [];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize component data
    _components.addAll([
      ComponentData(
        name: 'Engine',
        value: widget.engineHealth,
        color: Colors.red,
        icon: Icons.settings,
      ),
      ComponentData(
        name: 'Battery',
        value: widget.batteryHealth,
        color: Colors.green,
        icon: Icons.battery_full,
      ),
      ComponentData(
        name: 'Transmission',
        value: widget.transmissionHealth,
        color: Colors.blue,
        icon: Icons.speed,
      ),
      ComponentData(
        name: 'Brakes',
        value: widget.brakesHealth,
        color: Colors.orange,
        icon: Icons.disc_full,
      ),
    ]);

    // Create staggered animations for each ring
    _ringAnimations = _components.asMap().entries.map((entry) {
      final index = entry.key;
      final delay = index * 0.2;

      return Tween<double>(begin: 0.0, end: entry.value.value).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, delay + 0.8, curve: Curves.easeOutCubic),
        ),
      );
    }).toList();

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart title
        Text(
          'Component Health',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 20),

        // Ring chart
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated rings
              ...List.generate(_components.length, (index) {
                return AnimatedBuilder(
                  animation: _ringAnimations[index],
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(200, 200),
                      painter: HealthRingPainter(
                        progress: _ringAnimations[index].value,
                        color: _components[index].color,
                        ringIndex: index,
                        totalRings: _components.length,
                      ),
                    );
                  },
                );
              }),

              // Center content
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Health',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: _components.asMap().entries.map((entry) {
        final index = entry.key;
        final component = entry.value;

        return AnimatedBuilder(
              animation: _ringAnimations[index],
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: component.color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: component.color.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(component.icon, color: component.color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        component.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: component.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(_ringAnimations[index].value * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: component.color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
            .animate(delay: Duration(milliseconds: 300 * index))
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.3);
      }).toList(),
    );
  }
}

/// Component data model
class ComponentData {
  final String name;
  final double value;
  final Color color;
  final IconData icon;

  ComponentData({
    required this.name,
    required this.value,
    required this.color,
    required this.icon,
  });
}

/// Custom painter for health rings
class HealthRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int ringIndex;
  final int totalRings;

  HealthRingPainter({
    required this.progress,
    required this.color,
    required this.ringIndex,
    required this.totalRings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 8.0;
    const spacing = 4.0;

    // Calculate radius for this ring
    final maxRadius = (size.width - strokeWidth) / 2;
    final radiusStep = (maxRadius - 40) / totalRings;
    final radius = maxRadius - (ringIndex * (radiusStep + spacing));

    // Background arc
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha:0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Add glow effect for high values
    if (progress > 0.8) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha:0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is HealthRingPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.color != color ||
            oldDelegate.ringIndex != ringIndex);
  }
}

