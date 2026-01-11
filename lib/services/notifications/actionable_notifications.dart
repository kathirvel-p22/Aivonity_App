import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'fcm_service.dart';
import 'notification_center.dart';

/// Service for creating and managing actionable notifications
class ActionableNotificationService {
  static final ActionableNotificationService _instance =
      ActionableNotificationService._internal();
  factory ActionableNotificationService() => _instance;
  ActionableNotificationService._internal();

  final FCMService _fcmService = FCMService();
  final NotificationCenter _notificationCenter = NotificationCenter();

  final Map<String, NotificationActionHandler> _actionHandlers = {};
  final Map<String, DeepLinkHandler> _deepLinkHandlers = {};

  bool _isInitialized = false;

  /// Initialize actionable notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _setupDefaultActionHandlers();
    await _setupDefaultDeepLinkHandlers();
    _setupNotificationTapHandling();

    _isInitialized = true;
  }

  /// Send actionable notification
  Future<void> sendActionableNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationCategory category,
    required List<QuickAction> actions,
    String? deepLinkUrl,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    final actionableNotification = ActionableNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      message: message,
      category: category,
      actions: actions,
      deepLinkUrl: deepLinkUrl,
      data: data ?? {},
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    // Send via FCM with action buttons
    await _sendFCMActionableNotification(actionableNotification);

    // Add to notification center with actions
    await _addToNotificationCenter(actionableNotification);

    // Store for analytics
    await _storeNotificationRecord(actionableNotification);
  }

  /// Register action handler
  void registerActionHandler(
    String actionId,
    NotificationActionHandler handler,
  ) {
    _actionHandlers[actionId] = handler;
  }

  /// Register deep link handler
  void registerDeepLinkHandler(String pattern, DeepLinkHandler handler) {
    _deepLinkHandlers[pattern] = handler;
  }

  /// Execute notification action
  Future<ActionResult> executeAction(
    String notificationId,
    String actionId,
    Map<String, dynamic>? data,
  ) async {
    try {
      final handler = _actionHandlers[actionId];
      if (handler == null) {
        return ActionResult.error('Action handler not found: $actionId');
      }

      final result = await handler.execute(notificationId, data ?? {});

      // Track action execution
      await _trackActionExecution(notificationId, actionId, result.success);

      return result;
    } catch (e) {
      debugPrint('Failed to execute action $actionId: $e');
      return ActionResult.error('Action execution failed: $e');
    }
  }

  /// Handle deep link
  Future<DeepLinkResult> handleDeepLink(String url) async {
    try {
      for (final entry in _deepLinkHandlers.entries) {
        final pattern = entry.key;
        final handler = entry.value;

        if (_matchesPattern(url, pattern)) {
          final result = await handler.handle(url);

          // Track deep link usage
          await _trackDeepLinkUsage(url, result.success);

          return result;
        }
      }

      return DeepLinkResult.error('No handler found for URL: $url');
    } catch (e) {
      debugPrint('Failed to handle deep link $url: $e');
      return DeepLinkResult.error('Deep link handling failed: $e');
    }
  }

  /// Get notification analytics
  Future<NotificationAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // This would query the database for analytics data
    return NotificationAnalytics(
      totalNotifications: 0,
      totalActions: 0,
      totalDeepLinks: 0,
      actionClickRate: 0.0,
      deepLinkClickRate: 0.0,
      topActions: {},
      topDeepLinks: {},
    );
  }

  // Private methods

  Future<void> _setupDefaultActionHandlers() async {
    // Vehicle maintenance actions
    registerActionHandler('schedule_service', ScheduleServiceHandler());
    registerActionHandler('dismiss_alert', DismissAlertHandler());
    registerActionHandler('view_details', ViewDetailsHandler());
    registerActionHandler('call_service', CallServiceHandler());

    // Performance actions
    registerActionHandler('view_report', ViewReportHandler());
    registerActionHandler('share_data', ShareDataHandler());
    registerActionHandler('optimize_route', OptimizeRouteHandler());

    // Social actions
    registerActionHandler('reply_message', ReplyMessageHandler());
    registerActionHandler('mark_read', MarkReadHandler());
    registerActionHandler('open_chat', OpenChatHandler());

    // System actions
    registerActionHandler('update_app', UpdateAppHandler());
    registerActionHandler('sync_data', SyncDataHandler());
    registerActionHandler('backup_data', BackupDataHandler());
  }

  Future<void> _setupDefaultDeepLinkHandlers() async {
    // Vehicle screens
    registerDeepLinkHandler('/vehicle/*', VehicleDeepLinkHandler());
    registerDeepLinkHandler('/telemetry/*', TelemetryDeepLinkHandler());
    registerDeepLinkHandler('/maintenance/*', MaintenanceDeepLinkHandler());

    // Service screens
    registerDeepLinkHandler(
      '/service-centers/*',
      ServiceCenterDeepLinkHandler(),
    );
    registerDeepLinkHandler('/appointments/*', AppointmentDeepLinkHandler());

    // Chat screens
    registerDeepLinkHandler('/chat/*', ChatDeepLinkHandler());

    // Reports screens
    registerDeepLinkHandler('/reports/*', ReportDeepLinkHandler());

    // Settings screens
    registerDeepLinkHandler('/settings/*', SettingsDeepLinkHandler());
  }

  void _setupNotificationTapHandling() {
    _fcmService.messageStream.listen((message) {
      if (message.isTapped && message.data.containsKey('deep_link')) {
        final deepLink = message.data['deep_link'] as String;
        handleDeepLink(deepLink);
      }
    });
  }

  Future<void> _sendFCMActionableNotification(
    ActionableNotification notification,
  ) async {
    // Convert actions to FCM format
    final fcmActions = notification.actions
        .map(
          (action) => {
            'action': action.id,
            'title': action.title,
            'icon': action.icon,
          },
        )
        .toList();

    final data = {
      ...notification.data,
      'notification_id': notification.id,
      'actions': json.encode(fcmActions),
      if (notification.deepLinkUrl != null)
        'deep_link': notification.deepLinkUrl!,
    };

    await _fcmService.sendLocalNotification(
      title: notification.title,
      body: notification.message,
      category: notification.category,
      data: data,
      imageUrl: notification.imageUrl,
    );
  }

  Future<void> _addToNotificationCenter(
    ActionableNotification notification,
  ) async {
    final notificationActions = notification.actions
        .map(
          (action) => NotificationAction(
            id: action.id,
            label: action.title,
            isPrimary: action.isPrimary,
            onPressed: () =>
                executeAction(notification.id, action.id, action.data),
          ),
        )
        .toList();

    await _notificationCenter.addNotification(
      title: notification.title,
      message: notification.message,
      category: notification.category,
      data: notification.data,
      imageUrl: notification.imageUrl,
      actions: notificationActions,
    );
  }

  Future<void> _storeNotificationRecord(
    ActionableNotification notification,
  ) async {
    // Store notification record for analytics
    try {
      // Implementation would insert into database
    } catch (e) {
      debugPrint('Failed to store notification record: $e');
    }
  }

  Future<void> _trackActionExecution(
    String notificationId,
    String actionId,
    bool success,
  ) async {
    // Track action execution for analytics
    debugPrint(
      'Action executed: $actionId on notification $notificationId, success: $success',
    );
  }

  Future<void> _trackDeepLinkUsage(String url, bool success) async {
    // Track deep link usage for analytics
    debugPrint('Deep link used: $url, success: $success');
  }

  bool _matchesPattern(String url, String pattern) {
    // Simple pattern matching - in production, use proper regex
    if (pattern.endsWith('*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return url.startsWith(prefix);
    }
    return url == pattern;
  }
}

/// Actionable notification model
class ActionableNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationCategory category;
  final List<QuickAction> actions;
  final String? deepLinkUrl;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final DateTime timestamp;

  ActionableNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.category,
    required this.actions,
    this.deepLinkUrl,
    required this.data,
    this.imageUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'category_id': category.id,
      'actions': actions.map((a) => a.toJson()).toList(),
      'deep_link_url': deepLinkUrl,
      'data': data,
      'image_url': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Quick action for notifications
class QuickAction {
  final String id;
  final String title;
  final String? icon;
  final bool isPrimary;
  final Map<String, dynamic>? data;

  QuickAction({
    required this.id,
    required this.title,
    this.icon,
    this.isPrimary = false,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'is_primary': isPrimary,
      'data': data,
    };
  }
}

/// Action execution result
class ActionResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  ActionResult({required this.success, this.message, this.data});

  factory ActionResult.success({String? message, Map<String, dynamic>? data}) {
    return ActionResult(success: true, message: message, data: data);
  }

  factory ActionResult.error(String message) {
    return ActionResult(success: false, message: message);
  }
}

/// Deep link handling result
class DeepLinkResult {
  final bool success;
  final String? message;
  final String? targetScreen;

  DeepLinkResult({required this.success, this.message, this.targetScreen});

  factory DeepLinkResult.success({String? message, String? targetScreen}) {
    return DeepLinkResult(
      success: true,
      message: message,
      targetScreen: targetScreen,
    );
  }

  factory DeepLinkResult.error(String message) {
    return DeepLinkResult(success: false, message: message);
  }
}

/// Abstract notification action handler
abstract class NotificationActionHandler {
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  );
}

/// Abstract deep link handler
abstract class DeepLinkHandler {
  Future<DeepLinkResult> handle(String url);
}

/// Notification analytics
class NotificationAnalytics {
  final int totalNotifications;
  final int totalActions;
  final int totalDeepLinks;
  final double actionClickRate;
  final double deepLinkClickRate;
  final Map<String, int> topActions;
  final Map<String, int> topDeepLinks;

  NotificationAnalytics({
    required this.totalNotifications,
    required this.totalActions,
    required this.totalDeepLinks,
    required this.actionClickRate,
    required this.deepLinkClickRate,
    required this.topActions,
    required this.topDeepLinks,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_notifications': totalNotifications,
      'total_actions': totalActions,
      'total_deep_links': totalDeepLinks,
      'action_click_rate': actionClickRate,
      'deep_link_click_rate': deepLinkClickRate,
      'top_actions': topActions,
      'top_deep_links': topDeepLinks,
    };
  }
}

// Concrete action handlers

class ScheduleServiceHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Navigate to service scheduling screen
    // Implementation would use navigation service
    return ActionResult.success(message: 'Opening service scheduler');
  }
}

class DismissAlertHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Mark alert as dismissed
    return ActionResult.success(message: 'Alert dismissed');
  }
}

class ViewDetailsHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Navigate to details screen
    return ActionResult.success(message: 'Opening details');
  }
}

class CallServiceHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Initiate phone call to service center
    try {
      const platform = MethodChannel('com.aivonity.phone');
      final phoneNumber = data['phone_number'] as String?;
      if (phoneNumber != null) {
        await platform.invokeMethod('makeCall', {'number': phoneNumber});
        return ActionResult.success(message: 'Calling service center');
      } else {
        return ActionResult.error('Phone number not available');
      }
    } catch (e) {
      return ActionResult.error('Failed to make call: $e');
    }
  }
}

class ViewReportHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Navigate to report screen
    return ActionResult.success(message: 'Opening report');
  }
}

class ShareDataHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Open share dialog
    return ActionResult.success(message: 'Opening share dialog');
  }
}

class OptimizeRouteHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Navigate to route optimization
    return ActionResult.success(message: 'Optimizing route');
  }
}

class ReplyMessageHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Open quick reply interface
    return ActionResult.success(message: 'Opening reply interface');
  }
}

class MarkReadHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Mark message as read
    return ActionResult.success(message: 'Message marked as read');
  }
}

class OpenChatHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Navigate to chat screen
    return ActionResult.success(message: 'Opening chat');
  }
}

class UpdateAppHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Navigate to app store for update
    return ActionResult.success(message: 'Opening app store');
  }
}

class SyncDataHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Trigger data sync
    return ActionResult.success(message: 'Starting data sync');
  }
}

class BackupDataHandler extends NotificationActionHandler {
  @override
  Future<ActionResult> execute(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    // Trigger data backup
    return ActionResult.success(message: 'Starting data backup');
  }
}

// Concrete deep link handlers

class VehicleDeepLinkHandler extends DeepLinkHandler {
  @override
  Future<DeepLinkResult> handle(String url) async {
    // Navigate to vehicle screen
    return DeepLinkResult.success(targetScreen: 'vehicle');
  }
}

class TelemetryDeepLinkHandler extends DeepLinkHandler {
  @override
  Future<DeepLinkResult> handle(String url) async {
    // Navigate to telemetry screen
    return DeepLinkResult.success(targetScreen: 'telemetry');
  }
}

class MaintenanceDeepLinkHandler extends DeepLinkHandler {
  @override
  Future<DeepLinkResult> handle(String url) async {
    // Navigate to maintenance screen
    return DeepLinkResult.success(targetScreen: 'maintenance');
  }
}

class ServiceCenterDeepLinkHandler extends DeepLinkHandler {
  @override
  Future<DeepLinkResult> handle(String url) async {
    // Navigate to service center screen
    return DeepLinkResult.success(targetScreen: 'service_centers');
  }
}

class AppointmentDeepLinkHandler extends DeepLinkHandler {
  @override
  Future<DeepLinkResult> handle(String url) async {
    // Navigate to appointment screen
    return DeepLinkResult.success(targetScreen: 'appointments');
  }
}

class ChatDeepLinkHandler extends DeepLinkHandler {
  @override
  Future<DeepLinkResult> handle(String url) async {
    // Navigate to chat screen
    return DeepLinkResult.success(targetScreen: 'chat');
  }
}

class ReportDeepLinkHandler extends DeepLinkHandler {
  @override
  Future<DeepLinkResult> handle(String url) async {
    // Navigate to report screen
    return DeepLinkResult.success(targetScreen: 'reports');
  }
}

class SettingsDeepLinkHandler extends DeepLinkHandler {
  @override
  Future<DeepLinkResult> handle(String url) async {
    // Navigate to settings screen
    return DeepLinkResult.success(targetScreen: 'settings');
  }
}
