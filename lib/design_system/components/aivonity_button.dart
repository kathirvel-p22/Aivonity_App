import 'package:flutter/material.dart';

/// Custom button component with AIVONITY design system styling
class AivonityButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AivonityButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;
    double fontSize;
    double iconSize;

    switch (size) {
      case ButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        fontSize = 14;
        iconSize = 16;
        break;
      case ButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        fontSize = 16;
        iconSize = 20;
        break;
      case ButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
        fontSize = 18;
        iconSize = 24;
        break;
    }

    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ],
    );

    if (isFullWidth) {
      buttonChild = SizedBox(width: double.infinity, child: buttonChild);
    }

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
      case ButtonType.tertiary:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        );
    }
  }
}

enum ButtonType { primary, secondary, tertiary }

enum ButtonSize { small, medium, large }
