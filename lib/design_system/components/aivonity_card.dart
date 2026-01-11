import 'package:flutter/material.dart';

/// Custom card component with AIVONITY design system styling
class AivonityCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final Color? borderColor;

  const AivonityCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: margin ?? const EdgeInsets.all(8.0),
      child: Material(
        elevation: elevation ?? 2.0,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        color: backgroundColor ?? colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: showBorder
                ? BoxDecoration(
                    border: Border.all(
                      color:
                          borderColor ?? colorScheme.outline.withValues(alpha:0.2),
                      width: 1,
                    ),
                    borderRadius: borderRadius ?? BorderRadius.circular(16),
                  )
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Specialized card for dashboard metrics
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AivonityCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? colorScheme.primary, size: 24),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Status card with color-coded indicators
class StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final StatusType statusType;
  final String? description;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.title,
    required this.status,
    required this.statusType,
    this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    IconData statusIcon;

    switch (statusType) {
      case StatusType.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case StatusType.warning:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case StatusType.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case StatusType.info:
        statusColor = colorScheme.primary;
        statusIcon = Icons.info;
        break;
    }

    return AivonityCard(
      onTap: onTap,
      showBorder: true,
      borderColor: statusColor.withValues(alpha:0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusType { success, warning, error, info }

