import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/vehicle_model.dart';

/// AIVONITY Vehicle Health Card
/// Animated card displaying vehicle health with innovative design
class VehicleHealthCard extends StatefulWidget {
  final VehicleModel vehicle;
  final VoidCallback? onTap;

  const VehicleHealthCard({super.key, required this.vehicle, this.onTap});

  @override
  State<VehicleHealthCard> createState() => _VehicleHealthCardState();
}

class _VehicleHealthCardState extends State<VehicleHealthCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = AppTheme.getHealthScoreColor(
      widget.vehicle.health.overallScore,
    );

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: healthColor.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: healthColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CustomPaint(
                          painter: _VehiclePatternPainter(
                            color: healthColor.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              // Vehicle Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: healthColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: healthColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Vehicle Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.vehicle.make} ${widget.vehicle.model}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${widget.vehicle.year}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              // Health Score Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: healthColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(widget.vehicle.health.overallScore * 100).toInt()}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Health Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Health Score',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    _getHealthStatus(
                                      widget.vehicle.health.overallScore,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: healthColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Animated Progress Bar
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor:
                                      widget.vehicle.health.overallScore,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          healthColor.withValues(alpha: 0.7),
                                          healthColor,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Quick Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickStat(
                                  icon: Icons.speed,
                                  label: 'Mileage',
                                  value:
                                      '${widget.vehicle.mileage.toStringAsFixed(0)} km',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickStat(
                                  icon: Icons.build,
                                  label: 'Service',
                                  value: _getServiceStatus(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Pulse Effect for Critical Health
                    if (widget.vehicle.health.overallScore < 0.3)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  String _getHealthStatus(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.7) return 'Good';
    if (score >= 0.5) return 'Fair';
    if (score >= 0.3) return 'Poor';
    return 'Critical';
  }

  String _getServiceStatus() {
    // Calculate next service due based on maintenance history and mileage
    final lastService = widget.vehicle.maintenanceHistory.isNotEmpty
        ? widget.vehicle.maintenanceHistory.last
        : null;

    if (lastService != null) {
      final milesSinceService =
          widget.vehicle.mileage - lastService.mileageAtService;
      const serviceInterval = 5000; // Assume 5000 km service interval

      if (milesSinceService >= serviceInterval) {
        return 'Overdue';
      } else if (milesSinceService >= serviceInterval * 0.9) {
        return 'Due Soon';
      } else {
        final milesUntilService = serviceInterval - milesSinceService;
        return '${milesUntilService}km';
      }
    }
    return 'Up to date';
  }
}

/// Custom painter for vehicle card background pattern
class _VehiclePatternPainter extends CustomPainter {
  final Color color;

  _VehiclePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw geometric pattern
    final path = Path();

    // Create a subtle geometric pattern
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        final x = (size.width / 4) * i - 20;
        final y = (size.height / 2) * j - 10;

        path.addOval(Rect.fromCircle(center: Offset(x, y), radius: 2));
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

