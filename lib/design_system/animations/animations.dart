import 'package:flutter/material.dart';

/// Animation constants and utilities for AIVONITY design system
class AivonityAnimations {
  // Duration constants
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Curve constants
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;

  // Page transition animations
  static Route<T> slideTransition<T>(Widget page, {bool fromRight = true}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: fromRight ? begin : -begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: easeInOut)),
        );

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: medium,
    );
  }

  static Route<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: easeInOut)),
          child: child,
        );
      },
      transitionDuration: medium,
    );
  }
}

/// Animated container with hover and tap effects
class AnimatedInteractiveContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double hoverScale;
  final double tapScale;

  const AnimatedInteractiveContainer({
    super.key,
    required this.child,
    this.onTap,
    this.duration = AivonityAnimations.fast,
    this.hoverScale = 1.02,
    this.tapScale = 0.98,
  });

  @override
  State<AnimatedInteractiveContainer> createState() =>
      _AnimatedInteractiveContainerState();
}

class _AnimatedInteractiveContainerState
    extends State<AnimatedInteractiveContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateScale() {
    double targetScale = 1.0;
    if (_isTapped) {
      targetScale = widget.tapScale;
    } else if (_isHovered) {
      targetScale = widget.hoverScale;
    }

    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: targetScale,
    ).animate(_controller);

    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _updateScale();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _updateScale();
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isTapped = true);
          _updateScale();
        },
        onTapUp: (_) {
          setState(() => _isTapped = false);
          _updateScale();
          widget.onTap?.call();
        },
        onTapCancel: () {
          setState(() => _isTapped = false);
          _updateScale();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

