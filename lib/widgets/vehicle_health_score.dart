import 'package:flutter/material.dart';
import 'dart:math' as math;

class VehicleHealthScore extends StatefulWidget {
  final double healthScore;
  final bool isOnline;
  final DateTime? lastUpdate;
  final String vehicleId;

  const VehicleHealthScore({
    super.key,
    required this.healthScore,
    required this.isOnline,
    this.lastUpdate,
    required this.vehicleId,
  });

  @override
  State<VehicleHealthScore> createState() => _VehicleHealthScoreState();
}

class _VehicleHealthScoreState extends State<VehicleHealthScore>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scoreController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scoreAnimation;

  double _displayedScore = 0.0;

  @override
  void initState() {
    super.initState();

    // Pulse animation for online indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Score animation
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(begin: 0.0, end: widget.healthScore)
        .animate(
          CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
        );

    _scoreAnimation.addListener(() {
      setState(() {
        _displayedScore = _scoreAnimation.value;
      });
    });

    // Start animations
    if (widget.isOnline) {
      _pulseController.repeat(reverse: true);
    }
    _scoreController.forward();
  }

  @override
  void didUpdateWidget(VehicleHealthScore oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update pulse animation based on online status
    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }

    // Animate score changes
    if (widget.healthScore != oldWidget.healthScore) {
      _scoreAnimation =
          Tween<double>(
            begin: _displayedScore,
            end: widget.healthScore,
          ).animate(
            CurvedAnimation(
              parent: _scoreController,
              curve: Curves.easeOutCubic,
            ),
          );
      _scoreController.reset();
      _scoreController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vehicle Health',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildOnlineIndicator(),
              ],
            ),
            const SizedBox(height: 20),

            // Health Score Circle
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: HealthScoreCirclePainter(
                      score: _displayedScore,
                      isOnline: widget.isOnline,
                    ),
                  ),

                  // Score text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(_displayedScore * 100).toInt()}',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 48,
                              color: _getScoreColor(_displayedScore),
                            ),
                      ),
                      Text(
                        'HEALTH SCORE',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status text
            Text(
              _getHealthStatusText(_displayedScore),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _getScoreColor(_displayedScore),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Last update
            if (widget.lastUpdate != null)
              Text(
                'Last updated: ${_formatLastUpdate(widget.lastUpdate!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),

            const SizedBox(height: 16),

            // Vehicle ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ID: ${widget.vehicleId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isOnline ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isOnline ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isOnline ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getHealthStatusText(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.8) return 'Good';
    if (score >= 0.6) return 'Fair';
    if (score >= 0.4) return 'Poor';
    return 'Critical';
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scoreController.dispose();
    super.dispose();
  }
}

class HealthScoreCirclePainter extends CustomPainter {
  final double score;
  final bool isOnline;

  HealthScoreCirclePainter({required this.score, required this.isOnline});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = _getScoreColor(score)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * score;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect when online
    if (isOnline && score > 0) {
      final glowPaint = Paint()
        ..color = _getScoreColor(score).withValues(alpha:0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(HealthScoreCirclePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.isOnline != isOnline;
  }
}

