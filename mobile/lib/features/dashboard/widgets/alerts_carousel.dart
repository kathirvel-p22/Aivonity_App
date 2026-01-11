import 'package:flutter/material.dart';

import '../../../data/models/vehicle_model.dart';

/// AIVONITY Alerts Carousel
/// Animated carousel displaying vehicle alerts with swipe gestures
class AlertsCarousel extends StatefulWidget {
  final List<HealthAlert> alerts;
  final Function(HealthAlert) onAlertTap;

  const AlertsCarousel({
    super.key,
    required this.alerts,
    required this.onAlertTap,
  });

  @override
  State<AlertsCarousel> createState() => _AlertsCarouselState();
}

class _AlertsCarouselState extends State<AlertsCarousel>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _pulseController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Alerts Carousel
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.alerts.length,
            itemBuilder: (context, index) {
              final alert = widget.alerts[index];
              final isActive = index == _currentIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: isActive ? 0 : 8,
                ),
                child: AlertCard(
                  alert: alert,
                  isActive: isActive,
                  onTap: () => widget.onAlertTap(alert),
                  pulseController: _pulseController,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Page Indicators
        if (widget.alerts.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.alerts.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentIndex ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AlertCard extends StatefulWidget {
  final HealthAlert alert;
  final bool isActive;
  final VoidCallback onTap;
  final AnimationController pulseController;

  const AlertCard({
    super.key,
    required this.alert,
    required this.isActive,
    required this.onTap,
    required this.pulseController,
  });

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_tapController);
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = _getAlertColor(widget.alert.severity);
    final isCritical = widget.alert.severity == HealthAlertSeverity.critical;

    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    alertColor.withValues(alpha: 0.1),
                    alertColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: alertColor.withValues(alpha: 0.3),
                  width: widget.isActive ? 2 : 1,
                ),
                boxShadow: [
                  if (widget.isActive)
                    BoxShadow(
                      color: alertColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Background Pattern
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: _AlertPatternPainter(
                          color: alertColor.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Alert Icon
                        AnimatedBuilder(
                          animation: widget.pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isCritical
                                  ? 1.0 + (widget.pulseController.value * 0.1)
                                  : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: alertColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getAlertIcon(widget.alert.severity),
                                  color: alertColor,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 12),

                        // Alert Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Title
                              Text(
                                widget.alert.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: alertColor,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              // Description
                              Text(
                                widget.alert.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      )
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              // Timestamp
                              Text(
                                _formatTimestamp(widget.alert.timestamp),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      )
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                              ),
                            ],
                          ),
                        ),

                        // Severity Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: alertColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.alert.severity.name.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Critical Alert Pulse Border
                  if (isCritical)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: widget.pulseController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(
                                  alpha: widget.pulseController.value * 0.5,
                                ),
                                width: 2,
                              ),
                            ),
                          );
                        },
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

  Color _getAlertColor(HealthAlertSeverity severity) {
    switch (severity) {
      case HealthAlertSeverity.critical:
        return Colors.red;
      case HealthAlertSeverity.high:
        return Colors.orange;
      case HealthAlertSeverity.medium:
        return Colors.yellow.shade700;
      case HealthAlertSeverity.low:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(HealthAlertSeverity severity) {
    switch (severity) {
      case HealthAlertSeverity.critical:
        return Icons.error;
      case HealthAlertSeverity.high:
        return Icons.warning;
      case HealthAlertSeverity.medium:
        return Icons.info;
      case HealthAlertSeverity.low:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Custom painter for alert card background pattern
class _AlertPatternPainter extends CustomPainter {
  final Color color;

  _AlertPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw warning pattern
    final path = Path();

    // Zigzag pattern
    const zigzagHeight = 8.0;
    const zigzagWidth = 16.0;

    path.moveTo(0, size.height - zigzagHeight);

    for (double x = 0; x < size.width; x += zigzagWidth) {
      path.lineTo(x + zigzagWidth / 2, size.height);
      path.lineTo(x + zigzagWidth, size.height - zigzagHeight);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

