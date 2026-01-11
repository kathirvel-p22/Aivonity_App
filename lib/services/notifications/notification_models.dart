/// Notification message model
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final List<NotificationAction>? actionButtons;
  final String? deepLink;
  final bool isRead;
  final String? vehicleId;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.timestamp,
    required this.data,
    this.imageUrl,
    this.actionButtons,
    this.deepLink,
    this.isRead = false,
    this.vehicleId,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      category: NotificationCategory.values.firstWhere(
        (cat) => cat.toString() == json['category'],
        orElse: () => NotificationCategory.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (pri) => pri.toString() == json['priority'],
        orElse: () => NotificationPriority.default_,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      imageUrl: json['image_url'],
      deepLink: json['deep_link'],
      isRead: json['is_read'] == 1,
      vehicleId: json['vehicle_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category.toString(),
      'priority': priority.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'data': data,
      'image_url': imageUrl,
      'deep_link': deepLink,
      'is_read': isRead ? 1 : 0,
      'vehicle_id': vehicleId,
    };
  }
}

/// Notification action button
class NotificationAction {
  final String id;
  final String title;
  final String? icon;

  NotificationAction({
    required this.id,
    required this.title,
    this.icon,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'],
      title: json['title'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
    };
  }
}

/// Notification categories
enum NotificationCategory {
  maintenance,
  security,
  performance,
  general,
}

/// Notification priority levels
enum NotificationPriority {
  min,
  low,
  default_,
  high,
  max,
}

/// Notification configuration for categories
class NotificationConfig {
  final NotificationPriority priority;
  final String sound;
  final List<int> vibrationPattern;
  final int ledColor;
  final String channelId;
  final String channelName;
  final String channelDescription;

  NotificationConfig({
    required this.priority,
    required this.sound,
    required this.vibrationPattern,
    required this.ledColor,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
  });
}

/// Notification statistics
class NotificationStats {
  final int totalNotifications;
  final int readNotifications;
  final int unreadNotifications;
  final int todayNotifications;
  final double readRate;

  NotificationStats({
    required this.totalNotifications,
    required this.readNotifications,
    required this.unreadNotifications,
    required this.todayNotifications,
    required this.readRate,
  });
}
