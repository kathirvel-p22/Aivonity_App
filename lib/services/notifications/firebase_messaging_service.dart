import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Commented out due to import issues
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'notification_models.dart';

/// Firebase Cloud Messaging service for push notifications
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // final FlutterLocalNotificationsPlugin _localNotifications =
  //     FlutterLocalNotificationsPlugin();
  final DatabaseHelper _db = DatabaseHelper();

  StreamController<NotificationMessage>? _messageStreamController;
  StreamController<String>? _tokenStreamController;

  String? _fcmToken;
  bool _isInitialized = false;

  // Notification categories and their configurations
  final Map<NotificationCategory, NotificationConfig> _categoryConfigs = {
    NotificationCategory.maintenance: NotificationConfig(
      priority: NotificationPriority.high,
      sound: 'maintenance_alert.wav',
      vibrationPattern: [0, 1000, 500, 1000],
      ledColor: 0xFFFF9800, // Orange
      channelId: 'maintenance_alerts',
      channelName: 'Maintenance Alerts',
      channelDescription: 'Important maintenance notifications',
    ),
    NotificationCategory.security: NotificationConfig(
      priority: NotificationPriority.max,
      sound: 'security_alert.wav',
      vibrationPattern: [0, 500, 200, 500, 200, 500],
      ledColor: 0xFFF44336, // Red
      channelId: 'security_alerts',
      channelName: 'Security Alerts',
      channelDescription: 'Critical security notifications',
    ),
    NotificationCategory.performance: NotificationConfig(
      priority: NotificationPriority.default_,
      sound: 'performance_info.wav',
      vibrationPattern: [0, 300],
      ledColor: 0xFF2196F3, // Blue
      channelId: 'performance_info',
      channelName: 'Performance Info',
      channelDescription: 'Vehicle performance updates',
    ),
    NotificationCategory.general: NotificationConfig(
      priority: NotificationPriority.default_,
      sound: 'default_notification.wav',
      vibrationPattern: [0, 500],
      ledColor: 0xFF4CAF50, // Green
      channelId: 'general_notifications',
      channelName: 'General Notifications',
      channelDescription: 'General app notifications',
    ),
  };

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  Stream<NotificationMessage>? get messageStream =>
      _messageStreamController?.stream;
  Stream<String>? get tokenStream => _tokenStreamController?.stream;

  /// Initialize Firebase Messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if not already done
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      // Initialize local notifications (commented out due to import issues)
      // await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Setup message handlers
      _setupMessageHandlers();

      // Get FCM token
      await _getFCMToken();

      // Setup token refresh listener
      _setupTokenRefreshListener();

      // Initialize stream controllers
      _messageStreamController =
          StreamController<NotificationMessage>.broadcast();
      _tokenStreamController = StreamController<String>.broadcast();

      _isInitialized = true;
      debugPrint('Firebase Messaging Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase Messaging Service: $e');
      rethrow;
    }
  }

  /// Initialize local notifications (commented out due to import issues)
  // Future<void> _initializeLocalNotifications() async {
  //   // Local notifications functionality commented out
  // }

  /// Create notification channels for different categories (commented out)
  // Future<void> _createNotificationChannels() async {
  //   // Local notification channels commented out
  // }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'Notification permission status: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw Exception('Notification permissions denied');
    }
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is terminated
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleTerminatedMessage(message);
      }
    });
  }

  /// Handle messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');

    final notificationMessage = await _processMessage(message);

    // Show local notification (commented out)
    // await _showLocalNotification(notificationMessage);

    // Store in database
    await _storeNotification(notificationMessage);

    // Emit to stream
    _messageStreamController?.add(notificationMessage);
  }

  /// Handle messages when app is opened from background
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('App opened from background message: ${message.messageId}');

    final notificationMessage = await _processMessage(message);
    await _storeNotification(notificationMessage);

    // Navigate to relevant screen based on notification type
    await _handleNotificationNavigation(notificationMessage);

    _messageStreamController?.add(notificationMessage);
  }

  /// Handle messages when app is opened from terminated state
  Future<void> _handleTerminatedMessage(RemoteMessage message) async {
    debugPrint('App opened from terminated state: ${message.messageId}');

    final notificationMessage = await _processMessage(message);
    await _storeNotification(notificationMessage);

    // Delay navigation to allow app to fully initialize
    Future.delayed(const Duration(seconds: 2), () {
      _handleNotificationNavigation(notificationMessage);
    });

    _messageStreamController?.add(notificationMessage);
  }

  /// Process raw Firebase message into structured notification
  Future<NotificationMessage> _processMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    return NotificationMessage(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? data['title'] ?? 'AIVONITY',
      body: notification?.body ?? data['body'] ?? '',
      category: _parseCategory(data['category']),
      priority: _parsePriority(data['priority']),
      timestamp: DateTime.now(),
      data: data,
      imageUrl: notification?.android?.imageUrl ?? data['image_url'],
      actionButtons: _parseActionButtons(data['actions']),
      deepLink: data['deep_link'],
      isRead: false,
      vehicleId: data['vehicle_id'],
    );
  }

  /// Show local notification (commented out due to import issues)
  // Future<void> _showLocalNotification(NotificationMessage message) async {
  //   // Local notification functionality commented out
  // }

  /// Store notification in local database
  Future<void> _storeNotification(NotificationMessage message) async {
    try {
      await _db.database.then(
        (db) => db.insert(
          'notifications',
          message.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      );
    } catch (e) {
      debugPrint('Failed to store notification: $e');
    }
  }

  /// Handle notification navigation
  Future<void> _handleNotificationNavigation(
    NotificationMessage message,
  ) async {
    // This would integrate with your app's navigation system
    // For now, we'll just log the intended navigation
    debugPrint(
      'Navigate to: ${message.deepLink ?? message.category.toString()}',
    );
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Store token for server registration
      if (_fcmToken != null) {
        await _storeTokenLocally(_fcmToken!);
        _tokenStreamController?.add(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  /// Setup token refresh listener
  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM Token refreshed: $newToken');

      _storeTokenLocally(newToken);
      _tokenStreamController?.add(newToken);

      // Here you would typically send the new token to your server
      _sendTokenToServer(newToken);
    });
  }

  /// Store FCM token locally
  Future<void> _storeTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    await prefs.setInt(
      'fcm_token_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Send token to server for registration
  Future<void> _sendTokenToServer(String token) async {
    try {
      // This would make an API call to register the token with your server
      debugPrint('Sending token to server: $token');

      // Example API call structure:
      // await apiService.registerFCMToken(token, userId, deviceInfo);
    } catch (e) {
      debugPrint('Failed to send token to server: $e');
    }
  }

  /// Subscribe to topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Handle notification tap (commented out)
  // void _onNotificationTapped(NotificationResponse response) {
  //   // Notification tap handling commented out
  // }

  /// Mark notification as read
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      final db = await _db.database;
      await db.update(
        'notifications',
        {'is_read': 1, 'read_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// Get notification delivery statistics
  Future<NotificationStats> getNotificationStats() async {
    try {
      final db = await _db.database;

      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications',
      );
      final total = totalResult.first['count'] as int;

      final readResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE is_read = 1',
      );
      final read = readResult.first['count'] as int;

      final todayResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE timestamp >= ?',
        [
          DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
        ],
      );
      final today = todayResult.first['count'] as int;

      return NotificationStats(
        totalNotifications: total,
        readNotifications: read,
        unreadNotifications: total - read,
        todayNotifications: today,
        readRate: total > 0 ? read / total : 0.0,
      );
    } catch (e) {
      debugPrint('Failed to get notification stats: $e');
      return NotificationStats(
        totalNotifications: 0,
        readNotifications: 0,
        unreadNotifications: 0,
        todayNotifications: 0,
        readRate: 0.0,
      );
    }
  }

  // Helper methods

  NotificationCategory _parseCategory(String? category) {
    if (category == null) return NotificationCategory.general;

    try {
      return NotificationCategory.values.firstWhere(
        (cat) => cat.toString().split('.').last == category,
        orElse: () => NotificationCategory.general,
      );
    } catch (e) {
      return NotificationCategory.general;
    }
  }

  NotificationPriority _parsePriority(String? priority) {
    if (priority == null) return NotificationPriority.default_;

    try {
      return NotificationPriority.values.firstWhere(
        (pri) => pri.toString().split('.').last == priority,
        orElse: () => NotificationPriority.default_,
      );
    } catch (e) {
      return NotificationPriority.default_;
    }
  }

  List<NotificationAction>? _parseActionButtons(String? actionsJson) {
    if (actionsJson == null) return null;

    try {
      final actionsList = json.decode(actionsJson) as List;
      return actionsList
          .map((action) => NotificationAction.fromJson(action))
          .toList();
    } catch (e) {
      return null;
    }
  }

  // Android notification importance and priority methods commented out
  // Importance _getAndroidImportance(NotificationPriority priority) { ... }
  // Priority _getAndroidPriority(NotificationPriority priority) { ... }

  /// Dispose resources
  void dispose() {
    _messageStreamController?.close();
    _tokenStreamController?.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');

  // Store the message for processing when app opens
  final prefs = await SharedPreferences.getInstance();
  final backgroundMessages = prefs.getStringList('background_messages') ?? [];
  backgroundMessages.add(
    json.encode({
      'messageId': message.messageId,
      'data': message.data,
      'notification': {
        'title': message.notification?.title,
        'body': message.notification?.body,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }),
  );

  // Keep only last 10 background messages
  if (backgroundMessages.length > 10) {
    backgroundMessages.removeRange(0, backgroundMessages.length - 10);
  }

  await prefs.setStringList('background_messages', backgroundMessages);
}

