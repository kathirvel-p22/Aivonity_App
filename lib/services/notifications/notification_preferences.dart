import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'fcm_service.dart';
import 'multi_channel_service.dart';

/// Service for managing notification preferences and settings
class NotificationPreferencesService extends ChangeNotifier {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  NotificationPreferences? _preferences;
  bool _isInitialized = false;

  /// Get current preferences
  NotificationPreferences get preferences =>
      _preferences ?? NotificationPreferences.defaultPreferences();

  /// Initialize preferences service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadPreferences();
    _isInitialized = true;
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences newPreferences) async {
    _preferences = newPreferences;
    await _savePreferences();
    notifyListeners();
  }

  /// Update category preferences
  Future<void> updateCategoryPreferences(
    String categoryId,
    CategoryNotificationPreferences categoryPrefs,
  ) async {
    final currentPrefs = preferences;
    final updatedCategoryPrefs =
        Map<String, CategoryNotificationPreferences>.from(
          currentPrefs.categoryPreferences,
        );
    updatedCategoryPrefs[categoryId] = categoryPrefs;

    final updatedPrefs = NotificationPreferences(
      categoryPreferences: updatedCategoryPrefs,
      quietHoursEnabled: currentPrefs.quietHoursEnabled,
      quietHoursStart: currentPrefs.quietHoursStart,
      quietHoursEnd: currentPrefs.quietHoursEnd,
      quietDays: currentPrefs.quietDays,
      doNotDisturbEnabled: currentPrefs.doNotDisturbEnabled,
      batchingEnabled: currentPrefs.batchingEnabled,
      batchingInterval: currentPrefs.batchingInterval,
      maxNotificationsPerHour: currentPrefs.maxNotificationsPerHour,
    );

    await updatePreferences(updatedPrefs);
  }

  /// Update quiet hours settings
  Future<void> updateQuietHours({
    required bool enabled,
    required int startHour,
    required int endHour,
    List<int>? quietDays,
  }) async {
    final currentPrefs = preferences;
    final updatedPrefs = NotificationPreferences(
      categoryPreferences: currentPrefs.categoryPreferences,
      quietHoursEnabled: enabled,
      quietHoursStart: startHour,
      quietHoursEnd: endHour,
      quietDays: quietDays ?? currentPrefs.quietDays,
      doNotDisturbEnabled: currentPrefs.doNotDisturbEnabled,
      batchingEnabled: currentPrefs.batchingEnabled,
      batchingInterval: currentPrefs.batchingInterval,
      maxNotificationsPerHour: currentPrefs.maxNotificationsPerHour,
    );

    await updatePreferences(updatedPrefs);
  }

  /// Update do not disturb settings
  Future<void> updateDoNotDisturb(bool enabled) async {
    final currentPrefs = preferences;
    final updatedPrefs = NotificationPreferences(
      categoryPreferences: currentPrefs.categoryPreferences,
      quietHoursEnabled: currentPrefs.quietHoursEnabled,
      quietHoursStart: currentPrefs.quietHoursStart,
      quietHoursEnd: currentPrefs.quietHoursEnd,
      quietDays: currentPrefs.quietDays,
      doNotDisturbEnabled: enabled,
      batchingEnabled: currentPrefs.batchingEnabled,
      batchingInterval: currentPrefs.batchingInterval,
      maxNotificationsPerHour: currentPrefs.maxNotificationsPerHour,
    );

    await updatePreferences(updatedPrefs);
  }

  /// Update notification batching settings
  Future<void> updateBatchingSettings({
    required bool enabled,
    required Duration interval,
  }) async {
    final currentPrefs = preferences;
    final updatedPrefs = NotificationPreferences(
      categoryPreferences: currentPrefs.categoryPreferences,
      quietHoursEnabled: currentPrefs.quietHoursEnabled,
      quietHoursStart: currentPrefs.quietHoursStart,
      quietHoursEnd: currentPrefs.quietHoursEnd,
      quietDays: currentPrefs.quietDays,
      doNotDisturbEnabled: currentPrefs.doNotDisturbEnabled,
      batchingEnabled: enabled,
      batchingInterval: interval,
      maxNotificationsPerHour: currentPrefs.maxNotificationsPerHour,
    );

    await updatePreferences(updatedPrefs);
  }

  /// Update frequency controls
  Future<void> updateFrequencyControls(int maxPerHour) async {
    final currentPrefs = preferences;
    final updatedPrefs = NotificationPreferences(
      categoryPreferences: currentPrefs.categoryPreferences,
      quietHoursEnabled: currentPrefs.quietHoursEnabled,
      quietHoursStart: currentPrefs.quietHoursStart,
      quietHoursEnd: currentPrefs.quietHoursEnd,
      quietDays: currentPrefs.quietDays,
      doNotDisturbEnabled: currentPrefs.doNotDisturbEnabled,
      batchingEnabled: currentPrefs.batchingEnabled,
      batchingInterval: currentPrefs.batchingInterval,
      maxNotificationsPerHour: maxPerHour,
    );

    await updatePreferences(updatedPrefs);
  }

  /// Check if notifications should be delivered now
  bool shouldDeliverNotification(NotificationCategory category) {
    final prefs = preferences;
    final now = DateTime.now();

    // Check do not disturb
    if (prefs.doNotDisturbEnabled) {
      return false;
    }

    // Check quiet hours
    if (prefs.quietHoursEnabled) {
      if (_isInQuietHours(now, prefs)) {
        // Only allow critical notifications during quiet hours
        return category.priority == NotificationPriority.high;
      }
    }

    // Check quiet days
    if (prefs.quietDays.contains(now.weekday)) {
      return category.priority == NotificationPriority.high;
    }

    // Check frequency limits
    if (!_isWithinFrequencyLimits(category)) {
      return false;
    }

    return true;
  }

  /// Get allowed channels for a category
  List<CommunicationChannel> getAllowedChannels(NotificationCategory category) {
    final categoryPrefs = preferences.categoryPreferences[category.id];
    if (categoryPrefs == null) return [];

    final channels = <CommunicationChannel>[];

    if (categoryPrefs.enablePush) channels.add(CommunicationChannel.push);
    if (categoryPrefs.enableEmail) channels.add(CommunicationChannel.email);
    if (categoryPrefs.enableSms) channels.add(CommunicationChannel.sms);
    if (categoryPrefs.enableInApp) channels.add(CommunicationChannel.inApp);

    return channels;
  }

  /// Reset preferences to default
  Future<void> resetToDefaults() async {
    await updatePreferences(NotificationPreferences.defaultPreferences());
  }

  /// Export preferences
  Map<String, dynamic> exportPreferences() {
    return preferences.toJson();
  }

  /// Import preferences
  Future<void> importPreferences(Map<String, dynamic> preferencesJson) async {
    try {
      final importedPrefs = NotificationPreferences.fromJson(preferencesJson);
      await updatePreferences(importedPrefs);
    } catch (e) {
      debugPrint('Failed to import preferences: $e');
      throw ArgumentError('Invalid preferences format');
    }
  }

  // Private methods

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString('notification_preferences');

      if (preferencesJson != null) {
        final decoded = json.decode(preferencesJson) as Map<String, dynamic>;
        _preferences = NotificationPreferences.fromJson(decoded);
      } else {
        _preferences = NotificationPreferences.defaultPreferences();
      }
    } catch (e) {
      debugPrint('Failed to load preferences: $e');
      _preferences = NotificationPreferences.defaultPreferences();
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = json.encode(_preferences!.toJson());
      await prefs.setString('notification_preferences', preferencesJson);
    } catch (e) {
      debugPrint('Failed to save preferences: $e');
    }
  }

  bool _isInQuietHours(DateTime now, NotificationPreferences prefs) {
    final currentHour = now.hour;

    if (prefs.quietHoursStart <= prefs.quietHoursEnd) {
      // Same day quiet hours (e.g., 22:00 to 08:00 next day)
      return currentHour >= prefs.quietHoursStart &&
          currentHour < prefs.quietHoursEnd;
    } else {
      // Overnight quiet hours (e.g., 22:00 to 08:00 next day)
      return currentHour >= prefs.quietHoursStart ||
          currentHour < prefs.quietHoursEnd;
    }
  }

  bool _isWithinFrequencyLimits(NotificationCategory category) {
    // This would check against stored notification history
    // For now, always return true
    return true;
  }
}

/// Enhanced notification preferences with advanced controls
class NotificationPreferences {
  final Map<String, CategoryNotificationPreferences> categoryPreferences;
  final bool quietHoursEnabled;
  final int quietHoursStart; // Hour of day (0-23)
  final int quietHoursEnd; // Hour of day (0-23)
  final List<int> quietDays; // Days of week (1-7, Monday = 1)
  final bool doNotDisturbEnabled;
  final bool batchingEnabled;
  final Duration batchingInterval;
  final int maxNotificationsPerHour;

  NotificationPreferences({
    required this.categoryPreferences,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22, // 10 PM
    this.quietHoursEnd = 8, // 8 AM
    this.quietDays = const [],
    this.doNotDisturbEnabled = false,
    this.batchingEnabled = false,
    this.batchingInterval = const Duration(minutes: 30),
    this.maxNotificationsPerHour = 10,
  });

  factory NotificationPreferences.defaultPreferences() {
    return NotificationPreferences(
      categoryPreferences: {
        'critical': CategoryNotificationPreferences(
          enablePush: true,
          enableEmail: true,
          enableSms: true,
          enableInApp: true,
        ),
        'maintenance': CategoryNotificationPreferences(
          enablePush: true,
          enableEmail: true,
          enableSms: false,
          enableInApp: true,
        ),
        'performance': CategoryNotificationPreferences(
          enablePush: true,
          enableEmail: false,
          enableSms: false,
          enableInApp: true,
        ),
        'social': CategoryNotificationPreferences(
          enablePush: true,
          enableEmail: false,
          enableSms: false,
          enableInApp: true,
        ),
        'system': CategoryNotificationPreferences(
          enablePush: false,
          enableEmail: false,
          enableSms: false,
          enableInApp: true,
        ),
        'marketing': CategoryNotificationPreferences(
          enablePush: false,
          enableEmail: false,
          enableSms: false,
          enableInApp: false,
        ),
      },
      quietHoursEnabled: true,
      quietHoursStart: 22,
      quietHoursEnd: 8,
      batchingEnabled: true,
      batchingInterval: Duration(minutes: 30),
      maxNotificationsPerHour: 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_preferences': categoryPreferences.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'quiet_days': quietDays,
      'do_not_disturb_enabled': doNotDisturbEnabled,
      'batching_enabled': batchingEnabled,
      'batching_interval_minutes': batchingInterval.inMinutes,
      'max_notifications_per_hour': maxNotificationsPerHour,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final categoryPrefsJson =
        json['category_preferences'] as Map<String, dynamic>? ?? {};
    final categoryPrefs = categoryPrefsJson.map(
      (k, v) => MapEntry(
        k,
        CategoryNotificationPreferences.fromJson(v as Map<String, dynamic>),
      ),
    );

    return NotificationPreferences(
      categoryPreferences: categoryPrefs,
      quietHoursEnabled: json['quiet_hours_enabled'] ?? false,
      quietHoursStart: json['quiet_hours_start'] ?? 22,
      quietHoursEnd: json['quiet_hours_end'] ?? 8,
      quietDays: List<int>.from(json['quiet_days'] ?? []),
      doNotDisturbEnabled: json['do_not_disturb_enabled'] ?? false,
      batchingEnabled: json['batching_enabled'] ?? false,
      batchingInterval: Duration(
        minutes: json['batching_interval_minutes'] ?? 30,
      ),
      maxNotificationsPerHour: json['max_notifications_per_hour'] ?? 10,
    );
  }
}

/// Enhanced category notification preferences
class CategoryNotificationPreferences {
  final bool enablePush;
  final bool enableEmail;
  final bool enableSms;
  final bool enableInApp;
  final NotificationSound? customSound;
  final List<int>? customVibrationPattern;
  final bool respectQuietHours;
  final int priority; // 1-5, higher = more important

  CategoryNotificationPreferences({
    this.enablePush = true,
    this.enableEmail = false,
    this.enableSms = false,
    this.enableInApp = true,
    this.customSound,
    this.customVibrationPattern,
    this.respectQuietHours = true,
    this.priority = 3,
  });

  Map<String, dynamic> toJson() {
    return {
      'enable_push': enablePush,
      'enable_email': enableEmail,
      'enable_sms': enableSms,
      'enable_in_app': enableInApp,
      'custom_sound': customSound?.toJson(),
      'custom_vibration_pattern': customVibrationPattern,
      'respect_quiet_hours': respectQuietHours,
      'priority': priority,
    };
  }

  factory CategoryNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return CategoryNotificationPreferences(
      enablePush: json['enable_push'] ?? true,
      enableEmail: json['enable_email'] ?? false,
      enableSms: json['enable_sms'] ?? false,
      enableInApp: json['enable_in_app'] ?? true,
      customSound: json['custom_sound'] != null
          ? NotificationSound.fromJson(json['custom_sound'])
          : null,
      customVibrationPattern: json['custom_vibration_pattern'] != null
          ? List<int>.from(json['custom_vibration_pattern'])
          : null,
      respectQuietHours: json['respect_quiet_hours'] ?? true,
      priority: json['priority'] ?? 3,
    );
  }
}

/// Custom notification sound configuration
class NotificationSound {
  final String name;
  final String? filePath;
  final bool isDefault;

  NotificationSound({
    required this.name,
    this.filePath,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'file_path': filePath, 'is_default': isDefault};
  }

  factory NotificationSound.fromJson(Map<String, dynamic> json) {
    return NotificationSound(
      name: json['name'],
      filePath: json['file_path'],
      isDefault: json['is_default'] ?? false,
    );
  }
}

/// Notification frequency manager
class NotificationFrequencyManager {
  static final NotificationFrequencyManager _instance =
      NotificationFrequencyManager._internal();
  factory NotificationFrequencyManager() => _instance;
  NotificationFrequencyManager._internal();

  final Map<String, List<DateTime>> _notificationHistory = {};

  /// Record a notification delivery
  void recordNotification(String categoryId) {
    final now = DateTime.now();
    _notificationHistory[categoryId] ??= [];
    _notificationHistory[categoryId]!.add(now);

    // Clean up old entries (keep only last 24 hours)
    final cutoff = now.subtract(const Duration(hours: 24));
    _notificationHistory[categoryId]!.removeWhere(
      (time) => time.isBefore(cutoff),
    );
  }

  /// Check if category is within frequency limits
  bool isWithinLimits(String categoryId, int maxPerHour) {
    final history = _notificationHistory[categoryId] ?? [];
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    final recentNotifications = history
        .where((time) => time.isAfter(oneHourAgo))
        .length;
    return recentNotifications < maxPerHour;
  }

  /// Get notification count for category in time period
  int getNotificationCount(String categoryId, Duration period) {
    final history = _notificationHistory[categoryId] ?? [];
    final now = DateTime.now();
    final cutoff = now.subtract(period);

    return history.where((time) => time.isAfter(cutoff)).length;
  }

  /// Clear history for category
  void clearHistory(String categoryId) {
    _notificationHistory.remove(categoryId);
  }

  /// Clear all history
  void clearAllHistory() {
    _notificationHistory.clear();
  }
}

/// Notification batching manager
class NotificationBatchingManager {
  static final NotificationBatchingManager _instance =
      NotificationBatchingManager._internal();
  factory NotificationBatchingManager() => _instance;
  NotificationBatchingManager._internal();

  final Map<String, List<BatchedNotification>> _batchedNotifications = {};
  Timer? _batchTimer;

  /// Add notification to batch
  void addToBatch(
    String categoryId,
    String title,
    String message,
    Map<String, dynamic>? data,
  ) {
    _batchedNotifications[categoryId] ??= [];
    _batchedNotifications[categoryId]!.add(
      BatchedNotification(
        title: title,
        message: message,
        data: data ?? {},
        timestamp: DateTime.now(),
      ),
    );

    _scheduleBatchDelivery();
  }

  /// Process batched notifications
  Future<void> processBatches() async {
    for (final entry in _batchedNotifications.entries) {
      final categoryId = entry.key;
      final notifications = entry.value;

      if (notifications.isNotEmpty) {
        await _deliverBatchedNotifications(categoryId, notifications);
        notifications.clear();
      }
    }
  }

  void _scheduleBatchDelivery() {
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(minutes: 30), () {
      processBatches();
    });
  }

  Future<void> _deliverBatchedNotifications(
    String categoryId,
    List<BatchedNotification> notifications,
  ) async {
    if (notifications.length == 1) {
      // Single notification - deliver as is
      final notification = notifications.first;
      // Deliver notification
    } else {
      // Multiple notifications - create summary
      final summary = _createBatchSummary(categoryId, notifications);
      // Deliver summary notification
    }
  }

  String _createBatchSummary(
    String categoryId,
    List<BatchedNotification> notifications,
  ) {
    switch (categoryId) {
      case 'maintenance':
        return 'You have ${notifications.length} maintenance updates';
      case 'performance':
        return 'You have ${notifications.length} performance updates';
      case 'social':
        return 'You have ${notifications.length} new messages';
      default:
        return 'You have ${notifications.length} new notifications';
    }
  }
}

/// Batched notification model
class BatchedNotification {
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  BatchedNotification({
    required this.title,
    required this.message,
    required this.data,
    required this.timestamp,
  });
}

