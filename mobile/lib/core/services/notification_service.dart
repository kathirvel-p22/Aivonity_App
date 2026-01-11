import 'package:flutter/foundation.dart';

/// AIVONITY Notification Service
/// Simplified notification service without external dependencies
class NotificationService extends ChangeNotifier {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  bool _isInitialized = false;
  bool _permissionGranted = false;
  final List<NotificationMessage> _notifications = [];
  NotificationSettings _settings = const NotificationSettings();

  /// Initialize notification service
  static Future<void> initialize() async {
    try {
      await instance._initializeService();
      instance._isInitialized = true;
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;
  List<NotificationMessage> get notifications =>
      List.unmodifiable(_notifications);
  NotificationSettings get settings => _settings;

  Future<void> _initializeService() async {
    // Simulate initialization
    await Future.delayed(const Duration(milliseconds: 500));

    // Request permission
    await requestPermission();
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      // Simulate permission request
      await Future.delayed(const Duration(seconds: 1));
      _permissionGranted = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
      return false;
    }
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationCategory category = NotificationCategory.general,
  }) async {
    if (!_permissionGranted) {
      debugPrint('Notification permission not granted');
      return;
    }

    try {
      final notification = NotificationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        payload: payload,
        priority: priority,
        category: category,
        timestamp: DateTime.now(),
      );

      _notifications.insert(0, notification);

      // Keep only last 50 notifications
      if (_notifications.length > 50) {
        _notifications.removeRange(50, _notifications.length);
      }

      // Simulate showing system notification
      await _showSystemNotification(notification);

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Show vehicle health alert
  Future<void> showHealthAlert({
    required String title,
    required String message,
    required HealthAlertSeverity severity,
  }) async {
    final priority = _getPriorityFromSeverity(severity);

    await showNotification(
      title: title,
      body: message,
      priority: priority,
      category: NotificationCategory.health,
      payload: 'health_alert',
    );
  }

  /// Show maintenance reminder
  Future<void> showMaintenanceReminder({
    required String title,
    required String message,
    DateTime? scheduledDate,
  }) async {
    await showNotification(
      title: title,
      body: message,
      priority: NotificationPriority.normal,
      category: NotificationCategory.maintenance,
      payload: 'maintenance_reminder',
    );
  }

  /// Show service booking confirmation
  Future<void> showBookingConfirmation({
    required String serviceCenterName,
    required DateTime appointmentTime,
    required String serviceType,
  }) async {
    const title = 'Booking Confirmed';
    final body =
        'Your $serviceType appointment at $serviceCenterName is confirmed for ${_formatDateTime(appointmentTime)}';

    await showNotification(
      title: title,
      body: body,
      priority: NotificationPriority.high,
      category: NotificationCategory.booking,
      payload: 'booking_confirmation',
    );
  }

  /// Schedule notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationCategory category = NotificationCategory.general,
  }) async {
    if (!_permissionGranted) {
      debugPrint('Notification permission not granted');
      return;
    }

    try {
      // In a real implementation, this would schedule with the system
      debugPrint(
        'Scheduled notification: $title for ${_formatDateTime(scheduledTime)}',
      );

      // For demo purposes, show immediately if scheduled time is in the past
      if (scheduledTime.isBefore(DateTime.now())) {
        await showNotification(
          title: title,
          body: body,
          payload: payload,
          priority: priority,
          category: category,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(String notificationId) async {
    try {
      _notifications.removeWhere(
        (notification) => notification.id == notificationId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      _notifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  /// Update notification settings
  Future<void> updateSettings(NotificationSettings settings) async {
    try {
      _settings = settings;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update notification settings: $e');
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    try {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  /// Get unread notification count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  /// Clear old notifications
  void clearOldNotifications({Duration? olderThan}) {
    try {
      final cutoffTime = DateTime.now().subtract(
        olderThan ?? const Duration(days: 7),
      );
      _notifications.removeWhere(
        (notification) => notification.timestamp.isBefore(cutoffTime),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear old notifications: $e');
    }
  }

  // Helper methods

  Future<void> _showSystemNotification(NotificationMessage notification) async {
    // Simulate showing system notification
    await Future.delayed(const Duration(milliseconds: 100));

    // In a real implementation, this would use platform channels
    // to show actual system notifications
    debugPrint(
      'System notification: ${notification.title} - ${notification.body}',
    );
  }

  NotificationPriority _getPriorityFromSeverity(HealthAlertSeverity severity) {
    switch (severity) {
      case HealthAlertSeverity.low:
        return NotificationPriority.low;
      case HealthAlertSeverity.medium:
        return NotificationPriority.normal;
      case HealthAlertSeverity.high:
        return NotificationPriority.high;
      case HealthAlertSeverity.critical:
        return NotificationPriority.urgent;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Handle background message (for Firebase compatibility)
  static Future<void> handleBackgroundMessage(
    Map<String, dynamic> message,
  ) async {
    debugPrint('Background message received: $message');
    // Handle background notification
  }
}

/// Notification Message Model
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final String? payload;
  final NotificationPriority priority;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;

  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    required this.priority,
    required this.category,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationMessage copyWith({
    String? id,
    String? title,
    String? body,
    String? payload,
    NotificationPriority? priority,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Notification Settings Model
class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool healthAlertsEnabled;
  final bool maintenanceRemindersEnabled;
  final bool bookingNotificationsEnabled;
  final bool quietHoursEnabled;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;

  const NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.healthAlertsEnabled = true,
    this.maintenanceRemindersEnabled = true,
    this.bookingNotificationsEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });
}

/// Notification Priority Enum
enum NotificationPriority { low, normal, high, urgent }

/// Notification Category Enum
enum NotificationCategory {
  general,
  health,
  maintenance,
  booking,
  security,
  system,
}

/// Health Alert Severity Enum
enum HealthAlertSeverity { low, medium, high, critical }

/// Time of Day Helper Class
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

