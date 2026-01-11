import 'package:flutter/material.dart';
import '../theme.dart';

/// Advanced Adventure-themed Notification System
/// Provides modern, interactive notification components with adventure styling

/// Adventure notification types with different priority levels
enum AdventureNotificationType {
  summit, // High priority - urgent alerts
  trail, // Medium priority - important updates
  camp, // Low priority - informational
  weather, // Weather-related notifications
  equipment, // Equipment maintenance alerts
  achievement, // Achievement and milestone notifications
}

/// Adventure notification component with modern styling
class AdventureNotification extends StatelessWidget {
  final String title;
  final String message;
  final AdventureNotificationType type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final IconData? icon;
  final DateTime? timestamp;
  final bool isRead;

  const AdventureNotification({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onTap,
    this.onDismiss,
    this.icon,
    this.timestamp,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData defaultIcon;

    switch (type) {
      case AdventureNotificationType.summit:
        backgroundColor = AivonityTheme.accentSummitOrange.withValues(alpha:0.1);
        borderColor = AivonityTheme.accentSummitOrange;
        iconColor = AivonityTheme.accentSummitOrange;
        defaultIcon = Icons.priority_high;
        break;
      case AdventureNotificationType.trail:
        backgroundColor = AivonityTheme.primaryAlpineBlue.withValues(alpha:0.1);
        borderColor = AivonityTheme.primaryAlpineBlue;
        iconColor = AivonityTheme.primaryAlpineBlue;
        defaultIcon = Icons.travel_explore;
        break;
      case AdventureNotificationType.camp:
        backgroundColor = AivonityTheme.accentPineGreen.withValues(alpha:0.1);
        borderColor = AivonityTheme.accentPineGreen;
        iconColor = AivonityTheme.accentPineGreen;
        defaultIcon = Icons.info;
        break;
      case AdventureNotificationType.weather:
        backgroundColor = AivonityTheme.accentSunsetCoral.withValues(alpha:0.1);
        borderColor = AivonityTheme.accentSunsetCoral;
        iconColor = AivonityTheme.accentSunsetCoral;
        defaultIcon = Icons.water_drop;
        break;
      case AdventureNotificationType.equipment:
        backgroundColor = AivonityTheme.accentMountainGray.withValues(alpha:0.1);
        borderColor = AivonityTheme.accentMountainGray;
        iconColor = AivonityTheme.accentMountainGray;
        defaultIcon = Icons.construction;
        break;
      case AdventureNotificationType.achievement:
        backgroundColor = AivonityTheme.accentSummitOrange.withValues(alpha:0.1);
        borderColor = AivonityTheme.accentSummitOrange;
        iconColor = AivonityTheme.accentSummitOrange;
        defaultIcon = Icons.emoji_events;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, backgroundColor.withValues(alpha:0.5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha:0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adventure icon with gradient background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withValues(alpha:0.2),
                        iconColor.withValues(alpha:0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iconColor.withValues(alpha:0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon ?? defaultIcon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: iconColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: colorScheme.onSurfaceVariant.withValues(alpha:
                                0.7,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(timestamp!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha:
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Dismiss button
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurfaceVariant.withValues(alpha:0.7),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Adventure notification list with modern animations
class AdventureNotificationList extends StatelessWidget {
  final List<AdventureNotification> notifications;
  final VoidCallback? onMarkAllRead;

  const AdventureNotificationList({
    super.key,
    required this.notifications,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Header with mark all read button
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AivonityTheme.primaryAlpineBlue.withValues(alpha:0.1),
                AivonityTheme.primaryBlueLight.withValues(alpha:0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AivonityTheme.primaryAlpineBlue.withValues(alpha:0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: AivonityTheme.primaryAlpineBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Adventure Updates',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AivonityTheme.primaryAlpineBlue,
                  ),
                ),
              ),
              if (onMarkAllRead != null)
                TextButton(
                  onPressed: onMarkAllRead,
                  child: Text(
                    'Mark all read',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AivonityTheme.primaryAlpineBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Notification list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutQuart,
                child: notifications[index],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AivonityTheme.primaryAlpineBlue.withValues(alpha:0.1),
                  AivonityTheme.primaryAlpineBlue.withValues(alpha:0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.explore_off,
              size: 64,
              color: AivonityTheme.primaryAlpineBlue.withValues(alpha:0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Adventure Updates',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! New adventure notifications will appear here.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Adventure notification service widget
class AdventureNotificationService extends InheritedWidget {
  final List<AdventureNotification> notifications;
  final Function(AdventureNotification) addNotification;
  final Function(String) removeNotification;
  final VoidCallback markAllAsRead;

  const AdventureNotificationService({
    super.key,
    required super.child,
    required this.notifications,
    required this.addNotification,
    required this.removeNotification,
    required this.markAllAsRead,
  });

  static AdventureNotificationService? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdventureNotificationService>();
  }

  @override
  bool updateShouldNotify(AdventureNotificationService oldWidget) {
    return notifications != oldWidget.notifications;
  }
}

/// Adventure notification bell with badge
class AdventureNotificationBell extends StatelessWidget {
  final int notificationCount;
  final VoidCallback? onTap;

  const AdventureNotificationBell({
    super.key,
    this.notificationCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(
            Icons.notifications_outlined,
            size: 24,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AivonityTheme.accentSummitOrange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                notificationCount > 99 ? '99+' : notificationCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: notificationCount > 99 ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

