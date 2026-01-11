import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'fcm_service.dart';

/// In-app notification center for managing and displaying notifications
class NotificationCenter extends ChangeNotifier {
  static final NotificationCenter _instance = NotificationCenter._internal();
  factory NotificationCenter() => _instance;
  NotificationCenter._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final FCMService _fcmService = FCMService();

  final List<InAppNotification> _notifications = [];
  final StreamController<InAppNotification> _notificationStreamController =
      StreamController<InAppNotification>.broadcast();

  bool _isInitialized = false;
  int _unreadCount = 0;

  // Getters
  List<InAppNotification> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  Stream<InAppNotification> get notificationStream =>
      _notificationStreamController.stream;

  /// Initialize notification center
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadNotifications();
    _setupFCMListener();

    _isInitialized = true;
  }

  /// Add notification to center
  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationCategory category,
    Map<String, dynamic>? data,
    String? imageUrl,
    List<NotificationAction>? actions,
  }) async {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      category: category,
      timestamp: DateTime.now(),
      isRead: false,
      data: data ?? {},
      imageUrl: imageUrl,
      actions: actions ?? [],
    );

    _notifications.insert(0, notification);
    _updateUnreadCount();

    // Store in database
    await _storeNotification(notification);

    // Notify listeners
    _notificationStreamController.add(notification);
    notifyListeners();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _updateUnreadCount();

      // Update in database
      await _updateNotificationReadStatus(notificationId, true);

      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    bool hasChanges = false;

    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _updateUnreadCount();
      await _markAllNotificationsAsRead();
      notifyListeners();
    }
  }

  /// Remove notification
  Future<void> removeNotification(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications.removeAt(index);
      _updateUnreadCount();

      // Remove from database
      await _deleteNotification(notificationId);

      notifyListeners();
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    _updateUnreadCount();

    // Clear from database
    await _clearAllNotifications();

    notifyListeners();
  }

  /// Get notifications by category
  List<InAppNotification> getNotificationsByCategory(String categoryId) {
    return _notifications.where((n) => n.category.id == categoryId).toList();
  }

  /// Get unread notifications
  List<InAppNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Execute notification action
  Future<void> executeAction(String notificationId, String actionId) async {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw ArgumentError('Notification not found'),
    );

    final action = notification.actions.firstWhere(
      (a) => a.id == actionId,
      orElse: () => throw ArgumentError('Action not found'),
    );

    try {
      await action.onPressed();

      // Mark notification as read after action
      await markAsRead(notificationId);

      // Track action execution
      await _trackActionExecution(notificationId, actionId);
    } catch (e) {
      debugPrint('Failed to execute notification action: $e');
    }
  }

  /// Get notification statistics
  NotificationCenterStats getStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: now.weekday - 1));

    final todayNotifications = _notifications
        .where((n) => n.timestamp.isAfter(today))
        .length;

    final weekNotifications = _notifications
        .where((n) => n.timestamp.isAfter(thisWeek))
        .length;

    final categoryStats = <String, int>{};
    for (final notification in _notifications) {
      categoryStats[notification.category.id] =
          (categoryStats[notification.category.id] ?? 0) + 1;
    }

    return NotificationCenterStats(
      totalNotifications: _notifications.length,
      unreadNotifications: _unreadCount,
      todayNotifications: todayNotifications,
      weekNotifications: weekNotifications,
      categoryStats: categoryStats,
    );
  }

  // Private methods

  Future<void> _loadNotifications() async {
    try {
      // Load notifications from database
      // This would query the notifications table
      // For now, we'll start with empty list
      _updateUnreadCount();
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    }
  }

  void _setupFCMListener() {
    _fcmService.messageStream.listen((message) {
      // Convert FCM message to in-app notification
      addNotification(
        title: message.title,
        message: message.body,
        category: message.category,
        data: message.data,
        imageUrl: message.imageUrl,
      );
    });
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> _storeNotification(InAppNotification notification) async {
    // Store notification in database
    try {
      // Implementation would insert into notifications table
    } catch (e) {
      debugPrint('Failed to store notification: $e');
    }
  }

  Future<void> _updateNotificationReadStatus(String id, bool isRead) async {
    // Update read status in database
    try {
      // Implementation would update notifications table
    } catch (e) {
      debugPrint('Failed to update notification read status: $e');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    // Mark all notifications as read in database
    try {
      // Implementation would update all notifications
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    // Delete notification from database
    try {
      // Implementation would delete from notifications table
    } catch (e) {
      debugPrint('Failed to delete notification: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    // Clear all notifications from database
    try {
      // Implementation would clear notifications table
    } catch (e) {
      debugPrint('Failed to clear all notifications: $e');
    }
  }

  Future<void> _trackActionExecution(
    String notificationId,
    String actionId,
  ) async {
    // Track action execution for analytics
    debugPrint('Action executed: $actionId on notification $notificationId');
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
}

/// In-app notification model
class InAppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final List<NotificationAction> actions;

  InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    required this.isRead,
    required this.data,
    this.imageUrl,
    required this.actions,
  });

  InAppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
    String? imageUrl,
    List<NotificationAction>? actions,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category_id': category.id,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'data': data,
      'image_url': imageUrl,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }
}

/// Notification action
class NotificationAction {
  final String id;
  final String label;
  final IconData? icon;
  final bool isPrimary;
  final Future<void> Function() onPressed;

  NotificationAction({
    required this.id,
    required this.label,
    this.icon,
    this.isPrimary = false,
    required this.onPressed,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'is_primary': isPrimary};
  }
}

/// Notification center statistics
class NotificationCenterStats {
  final int totalNotifications;
  final int unreadNotifications;
  final int todayNotifications;
  final int weekNotifications;
  final Map<String, int> categoryStats;

  NotificationCenterStats({
    required this.totalNotifications,
    required this.unreadNotifications,
    required this.todayNotifications,
    required this.weekNotifications,
    required this.categoryStats,
  });

  double get readRate => totalNotifications > 0
      ? (totalNotifications - unreadNotifications) / totalNotifications
      : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'total_notifications': totalNotifications,
      'unread_notifications': unreadNotifications,
      'today_notifications': todayNotifications,
      'week_notifications': weekNotifications,
      'category_stats': categoryStats,
      'read_rate': readRate,
    };
  }
}
