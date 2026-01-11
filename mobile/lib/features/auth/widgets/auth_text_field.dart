import 'package:flutter/material.dart';

/// AIVONITY Custom Text Field for Authentication
/// Advanced text field with modern design and animations
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late Animation<Color?> _colorAnimation;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _focusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: Theme.of(context).colorScheme.primary,
    ).animate(_animationController);

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            return Text(
              widget.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _hasError
                    ? Theme.of(context).colorScheme.error
                    : _colorAnimation.value,
                fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Text Field
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasError
                      ? Theme.of(context).colorScheme.error
                      : _colorAnimation.value ?? Colors.grey.shade400,
                  width: _isFocused ? 2 : 1,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha:0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                enabled: widget.enabled,
                onChanged: widget.onChanged,
                validator: (value) {
                  final error = widget.validator?.call(value);
                  setState(() {
                    _hasError = error != null;
                  });
                  return error;
                },
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: _hasError
                              ? Theme.of(context).colorScheme.error
                              : _colorAnimation.value,
                        )
                      : null,
                  suffixIcon: widget.suffixIcon,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

