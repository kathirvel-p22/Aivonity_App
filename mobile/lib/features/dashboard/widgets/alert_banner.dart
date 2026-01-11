import 'package:flutter/material.dart';

/// AIVONITY Alert Banner
/// Animated banner for displaying important alerts
class AlertBanner extends StatefulWidget {
  final String severity;
  final String title;
  final String message;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AlertBanner({
    super.key,
    required this.severity,
    required this.title,
    required this.message,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse animation for critical alerts
    if (widget.severity == 'critical' || widget.severity == 'high') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertConfig = _getAlertConfig(widget.severity);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    alertConfig.color,
                    alertConfig.color.withValues(alpha:0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: alertConfig.color.withValues(alpha:0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Alert icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      alertConfig.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Alert content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.severity.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Action buttons
                  Column(
                    children: [
                      if (widget.onTap != null)
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),

                      if (widget.onDismiss != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  AlertConfig _getAlertConfig(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AlertConfig(color: const Color(0xFFDC2626), icon: Icons.error);
      case 'high':
        return AlertConfig(color: const Color(0xFFEA580C), icon: Icons.warning);
      case 'medium':
        return AlertConfig(color: const Color(0xFFF59E0B), icon: Icons.info);
      case 'low':
        return AlertConfig(
          color: const Color(0xFF3B82F6),
          icon: Icons.notifications,
        );
      default:
        return AlertConfig(
          color: const Color(0xFF6B7280),
          icon: Icons.info_outline,
        );
    }
  }
}

/// Alert configuration data
class AlertConfig {
  final Color color;
  final IconData icon;

  AlertConfig({required this.color, required this.icon});
}

