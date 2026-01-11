import 'package:flutter/material.dart';
import 'dart:math' as math;

/// AIVONITY Real-time Gauge Widget
/// Animated circular gauge for displaying real-time sensor values
class RealTimeGauge extends StatefulWidget {
  final String title;
  final double value;
  final double maxValue;
  final String unit;
  final Color color;
  final double? warningThreshold;
  final double? criticalThreshold;

  const RealTimeGauge({
    super.key,
    required this.title,
    required this.value,
    required this.maxValue,
    required this.unit,
    required this.color,
    this.warningThreshold,
    this.criticalThreshold,
  });

  @override
  State<RealTimeGauge> createState() => _RealTimeGaugeState();
}

class _RealTimeGaugeState extends State<RealTimeGauge>
    with TickerProviderStateMixin {
  late AnimationController _valueController;
  late AnimationController _pulseController;
  late Animation<double> _valueAnimation;

  double _previousValue = 0;

  @override
  void initState() {
    super.initState();

    _valueController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _valueAnimation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _valueController, curve: Curves.easeOutCubic),
    );

    _valueController.forward();

    // Start pulse animation if value is in warning/critical range
    _checkPulseAnimation();
  }

  @override
  void didUpdateWidget(RealTimeGauge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _valueAnimation =
          Tween<double>(begin: _previousValue, end: widget.value).animate(
        CurvedAnimation(
          parent: _valueController,
          curve: Curves.easeOutCubic,
        ),
      );

      _valueController.reset();
      _valueController.forward();

      _checkPulseAnimation();
    }
  }

  void _checkPulseAnimation() {
    final isCritical = widget.criticalThreshold != null &&
        widget.value >= widget.criticalThreshold!;
    final isWarning = widget.warningThreshold != null &&
        widget.value >= widget.warningThreshold!;

    if (isCritical || isWarning) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
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
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Gauge
          SizedBox(
            width: 100,
            height: 100,
            child: AnimatedBuilder(
              animation: Listenable.merge([_valueAnimation, _pulseController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _GaugePainter(
                    value: _valueAnimation.value,
                    maxValue: widget.maxValue,
                    color: _getCurrentColor(),
                    warningThreshold: widget.warningThreshold,
                    criticalThreshold: widget.criticalThreshold,
                    pulseValue: _pulseController.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _valueAnimation.value.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getCurrentColor(),
                                  ),
                        ),
                        Text(
                          widget.unit,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Status Indicator
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final status = _getStatus();
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color _getCurrentColor() {
    if (widget.criticalThreshold != null &&
        widget.value >= widget.criticalThreshold!) {
      return Colors.red;
    }
    if (widget.warningThreshold != null &&
        widget.value >= widget.warningThreshold!) {
      return Colors.orange;
    }
    return widget.color;
  }

  String _getStatus() {
    if (widget.criticalThreshold != null &&
        widget.value >= widget.criticalThreshold!) {
      return 'CRITICAL';
    }
    if (widget.warningThreshold != null &&
        widget.value >= widget.warningThreshold!) {
      return 'WARNING';
    }
    return 'NORMAL';
  }

  Color _getStatusColor() {
    if (widget.criticalThreshold != null &&
        widget.value >= widget.criticalThreshold!) {
      return Colors.red;
    }
    if (widget.warningThreshold != null &&
        widget.value >= widget.warningThreshold!) {
      return Colors.orange;
    }
    return Colors.green;
  }
}

/// Custom painter for the gauge
class _GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;
  final double? warningThreshold;
  final double? criticalThreshold;
  final double pulseValue;

  _GaugePainter({
    required this.value,
    required this.maxValue,
    required this.color,
    this.warningThreshold,
    this.criticalThreshold,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );

    // Warning threshold arc
    if (warningThreshold != null) {
      final warningAngle = (warningThreshold! / maxValue) * math.pi * 1.5;
      final warningPaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.75 + warningAngle,
        math.pi * 1.5 - warningAngle,
        false,
        warningPaint,
      );
    }

    // Critical threshold arc
    if (criticalThreshold != null) {
      final criticalAngle = (criticalThreshold! / maxValue) * math.pi * 1.5;
      final criticalPaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.75 + criticalAngle,
        math.pi * 1.5 - criticalAngle,
        false,
        criticalPaint,
      );
    }

    // Value arc
    final valueAngle = (value / maxValue) * math.pi * 1.5;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Add pulse effect for critical/warning values
    if ((criticalThreshold != null && value >= criticalThreshold!) ||
        (warningThreshold != null && value >= warningThreshold!)) {
      valuePaint.strokeWidth = 8 + (pulseValue * 4);
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      valueAngle,
      false,
      valuePaint,
    );

    // Center dot
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

