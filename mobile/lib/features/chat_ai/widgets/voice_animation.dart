import 'package:flutter/material.dart';
import 'dart:math' as math;

/// AIVONITY Voice Animation Widget
/// Animated microphone with sound wave visualization
class VoiceAnimation extends StatelessWidget {
  final AnimationController controller;

  const VoiceAnimation({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: VoiceWavePainter(
            animation: controller.value,
            color: Colors.white,
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 24),
        );
      },
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final double animation;
  final Color color;

  VoiceWavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha:0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw concentric circles with animated radius
    for (int i = 1; i <= 3; i++) {
      final radius =
          (size.width / 2) *
          (0.3 + 0.3 * i + 0.2 * math.sin(animation * 2 * math.pi + i));

      paint.color = color.withValues(alpha:0.4 - i * 0.1);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(VoiceWavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

