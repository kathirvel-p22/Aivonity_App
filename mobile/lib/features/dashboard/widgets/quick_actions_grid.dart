import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AIVONITY Quick Actions Grid
/// Animated grid of quick action buttons with innovative design
class QuickActionsGrid extends StatelessWidget {
  final Function(String) onActionTap;

  const QuickActionsGrid({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final actions = _getQuickActions();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return QuickActionButton(
                action: action,
                onTap: () => onActionTap(action.id),
              )
              .animate(delay: Duration(milliseconds: 100 + (index * 50)))
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3)
              .then()
              .shimmer(
                delay: Duration(milliseconds: 1000 + (index * 200)),
                duration: 1000.ms,
              );
        },
      ),
    );
  }

  List<QuickAction> _getQuickActions() {
    return [
      const QuickAction(
        id: 'add_vehicle',
        title: 'Add Vehicle',
        icon: Icons.add_circle_outline,
        color: Colors.blue,
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
      ),
      const QuickAction(
        id: 'emergency',
        title: 'Emergency',
        icon: Icons.emergency,
        color: Colors.red,
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
      ),
      const QuickAction(
        id: 'find_service',
        title: 'Find Service',
        icon: Icons.build_circle_outlined,
        color: Colors.orange,
        gradient: LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        ),
      ),
      const QuickAction(
        id: 'chat',
        title: 'AI Chat',
        icon: Icons.chat_bubble_outline,
        color: Colors.purple,
        gradient: LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
      ),
      const QuickAction(
        id: 'reports',
        title: 'Reports',
        icon: Icons.analytics_outlined,
        color: Colors.green,
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
      ),
      const QuickAction(
        id: 'settings',
        title: 'Settings',
        icon: Icons.settings_outlined,
        color: Colors.grey,
        gradient: LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
        ),
      ),
    ];
  }
}

class QuickActionButton extends StatefulWidget {
  final QuickAction action;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.action,
    required this.onTap,
  });

  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
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
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.action.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.action.color.withValues(alpha:0.3),
                      blurRadius: _isPressed ? 8 : 12,
                      offset: Offset(0, _isPressed ? 2 : 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                          painter: _ActionPatternPainter(
                            color: Colors.white.withValues(alpha:0.1),
                          ),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with glow effect
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.action.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Title
                          Text(
                            widget.action.title,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Ripple Effect
                    if (_isPressed)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child:
                              Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha:0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 100.ms)
                                  .then()
                                  .fadeOut(duration: 200.ms),
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
}

/// Custom painter for action button background pattern
class _ActionPatternPainter extends CustomPainter {
  final Color color;

  _ActionPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw geometric lines
    final path = Path();

    // Diagonal lines
    path.moveTo(0, size.height * 0.3);
    path.lineTo(size.width * 0.7, 0);

    path.moveTo(size.width * 0.3, size.height);
    path.lineTo(size.width, size.height * 0.3);

    canvas.drawPath(path, paint);

    // Small circles
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      2,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      1.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Quick action data model
class QuickAction {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  const QuickAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

