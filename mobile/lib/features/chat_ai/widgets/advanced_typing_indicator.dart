import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Advanced Typing Indicator Widget
/// Sophisticated typing indicator with multiple animation styles and AI thinking states
class AdvancedTypingIndicator extends StatefulWidget {
  final TypingIndicatorStyle style;
  final String? customMessage;
  final bool showAvatar;
  final Duration animationDuration;
  final Color? primaryColor;
  final Color? backgroundColor;

  const AdvancedTypingIndicator({
    super.key,
    this.style = TypingIndicatorStyle.dots,
    this.customMessage,
    this.showAvatar = true,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  State<AdvancedTypingIndicator> createState() =>
      _AdvancedTypingIndicatorState();
}

class _AdvancedTypingIndicatorState extends State<AdvancedTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _fadeController;

  late Animation<double> _primaryAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _thinkingMessages = [
    'AI is thinking...',
    'Processing your request...',
    'Analyzing vehicle data...',
    'Generating response...',
    'Almost ready...',
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _startMessageRotation();
  }

  void _setupAnimations() {
    _primaryController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _primaryAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _primaryController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.linear,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimations() {
    _primaryController.repeat();
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _fadeController.forward();
  }

  void _startMessageRotation() {
    if (widget.style == TypingIndicatorStyle.thinking) {
      Future.delayed(const Duration(seconds: 2), _rotateMessage);
    }
  }

  void _rotateMessage() {
    if (mounted) {
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % _thinkingMessages.length;
      });
      Future.delayed(const Duration(seconds: 2), _rotateMessage);
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.showAvatar) ...[
              _buildAvatar(),
              const SizedBox(width: 8),
            ],
            _buildTypingBubble(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.primaryColor ??
                      Theme.of(context).colorScheme.secondary,
                  (widget.primaryColor ??
                          Theme.of(context).colorScheme.secondary)
                      .withValues(alpha: 0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.primaryColor ??
                          Theme.of(context).colorScheme.secondary)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: const Radius.circular(4),
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildTypingContent(),
    );
  }

  Widget _buildTypingContent() {
    switch (widget.style) {
      case TypingIndicatorStyle.dots:
        return _buildDotsIndicator();
      case TypingIndicatorStyle.wave:
        return _buildWaveIndicator();
      case TypingIndicatorStyle.pulse:
        return _buildPulseIndicator();
      case TypingIndicatorStyle.thinking:
        return _buildThinkingIndicator();
      case TypingIndicatorStyle.bars:
        return _buildBarsIndicator();
    }
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _primaryAnimation,
          builder: (context, child) {
            final delay = index * 0.2;
            final animationValue = (_primaryAnimation.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * math.sin(animationValue * 2 * math.pi));

            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: (widget.primaryColor ??
                            Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.3 + (0.7 * scale)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildWaveIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            final waveValue = math.sin(_waveAnimation.value + (index * 0.5));
            final height = 4 + (8 * (waveValue + 1) / 2);

            return Container(
              margin: EdgeInsets.only(right: index < 4 ? 3 : 0),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: widget.primaryColor ??
                    Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildPulseIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12 * _pulseAnimation.value,
              height: 12 * _pulseAnimation.value,
              decoration: BoxDecoration(
                color: (widget.primaryColor ??
                        Theme.of(context).colorScheme.primary)
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI is typing...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThinkingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _primaryAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _primaryAnimation.value * 2 * math.pi,
              child: Icon(
                Icons.psychology,
                size: 16,
                color: widget.primaryColor ??
                    Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.customMessage ?? _thinkingMessages[_currentMessageIndex],
            key: ValueKey(_currentMessageIndex),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarsIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _primaryAnimation,
          builder: (context, child) {
            final delay = index * 0.15;
            final animationValue = (_primaryAnimation.value + delay) % 1.0;
            final height = 4 + (12 * math.sin(animationValue * math.pi));

            return Container(
              margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: widget.primaryColor ??
                    Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Typing Indicator Styles
enum TypingIndicatorStyle {
  dots,
  wave,
  pulse,
  thinking,
  bars,
}

/// Smart Typing Indicator
/// Automatically switches between different styles based on context
class SmartTypingIndicator extends StatefulWidget {
  final bool showAvatar;
  final Duration switchInterval;
  final List<TypingIndicatorStyle> styles;

  const SmartTypingIndicator({
    super.key,
    this.showAvatar = true,
    this.switchInterval = const Duration(seconds: 3),
    this.styles = const [
      TypingIndicatorStyle.dots,
      TypingIndicatorStyle.wave,
      TypingIndicatorStyle.thinking,
    ],
  });

  @override
  State<SmartTypingIndicator> createState() => _SmartTypingIndicatorState();
}

class _SmartTypingIndicatorState extends State<SmartTypingIndicator> {
  int _currentStyleIndex = 0;

  @override
  void initState() {
    super.initState();
    _startStyleSwitching();
  }

  void _startStyleSwitching() {
    if (widget.styles.length > 1) {
      Future.delayed(widget.switchInterval, _switchStyle);
    }
  }

  void _switchStyle() {
    if (mounted) {
      setState(() {
        _currentStyleIndex = (_currentStyleIndex + 1) % widget.styles.length;
      });
      Future.delayed(widget.switchInterval, _switchStyle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: AdvancedTypingIndicator(
        key: ValueKey(_currentStyleIndex),
        style: widget.styles[_currentStyleIndex],
        showAvatar: widget.showAvatar,
      ),
    );
  }
}

/// Contextual Typing Indicator
/// Shows different indicators based on the type of processing
class ContextualTypingIndicator extends StatelessWidget {
  final TypingContext context;
  final bool showAvatar;

  const ContextualTypingIndicator({
    super.key,
    required this.context,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    switch (this.context) {
      case TypingContext.thinking:
        return AdvancedTypingIndicator(
          style: TypingIndicatorStyle.thinking,
          customMessage: 'Analyzing your request...',
          showAvatar: showAvatar,
        );
      case TypingContext.processing:
        return AdvancedTypingIndicator(
          style: TypingIndicatorStyle.wave,
          customMessage: 'Processing vehicle data...',
          showAvatar: showAvatar,
        );
      case TypingContext.searching:
        return AdvancedTypingIndicator(
          style: TypingIndicatorStyle.bars,
          customMessage: 'Searching database...',
          showAvatar: showAvatar,
        );
      case TypingContext.generating:
        return AdvancedTypingIndicator(
          style: TypingIndicatorStyle.pulse,
          customMessage: 'Generating response...',
          showAvatar: showAvatar,
        );
      case TypingContext.typing:
        return AdvancedTypingIndicator(
          style: TypingIndicatorStyle.dots,
          showAvatar: showAvatar,
        );
    }
  }
}

/// Typing Context Types
enum TypingContext {
  typing,
  thinking,
  processing,
  searching,
  generating,
}
