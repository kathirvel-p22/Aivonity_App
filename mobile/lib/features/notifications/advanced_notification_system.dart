import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Advanced Notification System with AI-powered prioritization and delivery
class AdvancedNotificationSystem extends StatefulWidget {
  const AdvancedNotificationSystem({super.key});

  @override
  State<AdvancedNotificationSystem> createState() =>
      _AdvancedNotificationSystemState();
}

class _AdvancedNotificationSystemState extends State<AdvancedNotificationSystem>
    with TickerProviderStateMixin {
  late AnimationController _notificationController;
  late Animation<double> _notificationAnimation;

  // Notification state
  List<SmartNotification> _notifications = [];
  final NotificationSettings _settings = NotificationSettings();
  Map<String, NotificationChannel> _channels = {};
  bool _isProcessing = false;

  // AI-powered features
  Timer? _aiProcessingTimer;
  final List<NotificationPattern> _learnedPatterns = [];
  final Map<String, double> _userPreferences = {};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeNotifications();
    _startAIProcessing();
  }

  void _setupAnimations() {
    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _notificationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _notificationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _initializeNotifications() {
    // Initialize notification channels
    _channels = {
      'maintenance': NotificationChannel(
        id: 'maintenance',
        name: 'Maintenance Alerts',
        icon: Icons.build,
        color: Colors.orange,
        priority: NotificationPriority.high,
        enabled: true,
      ),
      'safety': NotificationChannel(
        id: 'safety',
        name: 'Safety Alerts',
        icon: Icons.security,
        color: Colors.red,
        priority: NotificationPriority.critical,
        enabled: true,
      ),
      'fuel': NotificationChannel(
        id: 'fuel',
        name: 'Fuel & Efficiency',
        icon: Icons.local_gas_station,
        color: Colors.green,
        priority: NotificationPriority.medium,
        enabled: true,
      ),
      'navigation': NotificationChannel(
        id: 'navigation',
        name: 'Navigation Updates',
        icon: Icons.navigation,
        color: Colors.blue,
        priority: NotificationPriority.medium,
        enabled: true,
      ),
      'promotional': NotificationChannel(
        id: 'promotional',
        name: 'Service Offers',
        icon: Icons.local_offer,
        color: Colors.purple,
        priority: NotificationPriority.low,
        enabled: false,
      ),
    };

    // Generate sample notifications
    _notifications = [
      SmartNotification(
        id: 'notif_1',
        title: 'Oil Change Due',
        message: 'Your vehicle needs an oil change in 500 miles',
        channelId: 'maintenance',
        priority: NotificationPriority.high,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        actions: ['Schedule Service', 'Dismiss'],
        aiPriority: 0.9,
        category: NotificationCategory.maintenance,
        metadata: {'dueIn': 500, 'type': 'oil_change'},
      ),
      SmartNotification(
        id: 'notif_2',
        title: 'Fuel Efficiency Improved!',
        message: 'Great job! Your fuel efficiency increased by 8% this week',
        channelId: 'fuel',
        priority: NotificationPriority.medium,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        actions: ['View Details', 'Share Achievement'],
        aiPriority: 0.7,
        category: NotificationCategory.achievement,
        metadata: {'improvement': 8.0, 'period': 'week'},
      ),
      SmartNotification(
        id: 'notif_3',
        title: 'Traffic Alert',
        message:
            'Heavy traffic ahead on your route. Consider alternative path.',
        channelId: 'navigation',
        priority: NotificationPriority.medium,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        actions: ['Show Alternative', 'Continue'],
        aiPriority: 0.8,
        category: NotificationCategory.navigation,
        metadata: {'delay': 25, 'alternativeSavings': 12},
      ),
      SmartNotification(
        id: 'notif_4',
        title: 'Safety Reminder',
        message: 'Remember to check tire pressure before long drives',
        channelId: 'safety',
        priority: NotificationPriority.low,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        actions: ['Check Now', 'Remind Later'],
        aiPriority: 0.6,
        category: NotificationCategory.safety,
        metadata: {'reminderType': 'tire_pressure'},
      ),
    ];

    // Sort by AI priority and timestamp
    _sortNotifications();
  }

  void _startAIProcessing() {
    _aiProcessingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _processNotificationsWithAI();
      }
    });
  }

  void _processNotificationsWithAI() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate AI processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          // Update notification priorities based on AI analysis
          for (final notification in _notifications) {
            // Simulate AI adjusting priorities based on user behavior
            final randomAdjustment = (Random().nextDouble() - 0.5) * 0.2;
            notification.aiPriority =
                (notification.aiPriority + randomAdjustment).clamp(0.0, 1.0);
          }

          _sortNotifications();
          _isProcessing = false;
        });
      }
    });
  }

  void _sortNotifications() {
    _notifications.sort((a, b) {
      // Sort by AI priority first, then by timestamp
      final priorityCompare = b.aiPriority.compareTo(a.aiPriority);
      if (priorityCompare != 0) return priorityCompare;
      return b.timestamp.compareTo(a.timestamp);
    });
  }

  @override
  void dispose() {
    _notificationController.dispose();
    _aiProcessingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Notifications'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Notification Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildNotificationSummary(),
          Expanded(
            child: _buildNotificationList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _markAllAsRead,
        tooltip: 'Mark All as Read',
        child: const Icon(Icons.done_all),
      ),
    );
  }

  Widget _buildNotificationSummary() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final highPriorityCount = _notifications
        .where(
          (n) =>
              n.priority == NotificationPriority.high ||
              n.priority == NotificationPriority.critical,
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Unread',
              unreadCount.toString(),
              Icons.notifications,
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'High Priority',
              highPriorityCount.toString(),
              Icons.warning,
              Colors.red,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'AI Optimized',
              '${(_notifications.length * 0.8).round()}',
              Icons.auto_awesome,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNotificationList() {
    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(SmartNotification notification) {
    final channel = _channels[notification.channelId];
    final isUnread = !notification.isRead;

    return AnimatedBuilder(
      animation: _notificationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isUnread ? 1.0 + (_notificationAnimation.value * 0.02) : 1.0,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isUnread ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _getPriorityColor(notification.priority)
                    .withValues(alpha: isUnread ? 0.5 : 0.2),
                width: isUnread ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => _markAsRead(notification.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (channel != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: channel.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              channel.icon,
                              color: channel.color,
                              size: 20,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isUnread
                                      ? Colors.black
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(notification.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(notification.priority),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    if (notification.actions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: notification.actions.map((action) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: OutlinedButton(
                              onPressed: () => _executeNotificationAction(
                                notification.id,
                                action,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                action,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(notification.priority)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notification.priority.name.toUpperCase(),
                            style: TextStyle(
                              color: _getPriorityColor(notification.priority),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Priority: ${(notification.aiPriority * 100).round()}%',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Channels',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._channels.values.map(
                      (channel) => SwitchListTile(
                        title: Text(channel.name),
                        subtitle: Text('${channel.priority.name} priority'),
                        secondary: Icon(channel.icon, color: channel.color),
                        value: channel.enabled,
                        onChanged: (value) => _toggleChannel(channel.id, value),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'General Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('AI Optimization'),
                      subtitle: const Text('Let AI prioritize notifications'),
                      value: _settings.aiOptimization,
                      onChanged: (value) =>
                          setState(() => _settings.aiOptimization = value),
                    ),
                    SwitchListTile(
                      title: const Text('Quiet Hours'),
                      subtitle:
                          const Text('Reduce notifications during sleep hours'),
                      value: _settings.quietHours,
                      onChanged: (value) =>
                          setState(() => _settings.quietHours = value),
                    ),
                    SwitchListTile(
                      title: const Text('Emergency Alerts'),
                      subtitle:
                          const Text('Always show critical safety alerts'),
                      value: _settings.emergencyAlerts,
                      onChanged: (value) =>
                          setState(() => _settings.emergencyAlerts = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final notification =
          _notifications.firstWhere((n) => n.id == notificationId);
      notification.isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (final notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _executeNotificationAction(String notificationId, String action) {
    // Handle notification actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Executed: $action')),
    );
  }

  void _toggleChannel(String channelId, bool enabled) {
    setState(() {
      _channels[channelId]!.enabled = enabled;
    });
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Colors.red;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.medium:
        return Colors.yellow;
      case NotificationPriority.low:
        return Colors.blue;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Data Models
enum NotificationPriority { critical, high, medium, low }

enum NotificationCategory {
  maintenance,
  safety,
  fuel,
  navigation,
  achievement,
  promotional
}

class NotificationChannel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final NotificationPriority priority;
  bool enabled;

  NotificationChannel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.priority,
    required this.enabled,
  });
}

class SmartNotification {
  final String id;
  final String title;
  final String message;
  final String channelId;
  final NotificationPriority priority;
  final DateTime timestamp;
  final List<String> actions;
  double aiPriority;
  final NotificationCategory category;
  final Map<String, dynamic> metadata;
  bool isRead;

  SmartNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.channelId,
    required this.priority,
    required this.timestamp,
    required this.actions,
    required this.aiPriority,
    required this.category,
    required this.metadata,
    this.isRead = false,
  });
}

class NotificationSettings {
  bool aiOptimization = true;
  bool quietHours = false;
  bool emergencyAlerts = true;
  TimeOfDay quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay quietEnd = const TimeOfDay(hour: 7, minute: 0);
}

class NotificationPattern {
  final String id;
  final String pattern;
  final NotificationCategory category;
  final double frequency;
  final DateTime lastSeen;

  const NotificationPattern({
    required this.id,
    required this.pattern,
    required this.category,
    required this.frequency,
    required this.lastSeen,
  });
}

