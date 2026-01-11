import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase Cloud Messaging service with notification categories and priority levels
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamController<NotificationMessage>? _messageStreamController;
  Stream<NotificationMessage>? _messageStream;

  bool _isInitialized = false;
  String? _fcmToken;
  final Map<String, NotificationCategory> _categories = {};

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _setupNotificationCategories();
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _setupMessageHandlers();
    await _getToken();

    _messageStreamController =
        StreamController<NotificationMessage>.broadcast();
    _messageStream = _messageStreamController!.stream;

    _isInitialized = true;
  }

  /// Get notification message stream
  Stream<NotificationMessage> get messageStream {
    if (_messageStream == null) {
      throw StateError('FCMService not initialized. Call initialize() first.');
    }
    return _messageStream!;
  }

  /// Get FCM token
  Future<String?> getToken() async {
    if (_fcmToken == null) {
      await _getToken();
    }
    return _fcmToken;
  }

  /// Subscribe to topic
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

  /// Send local notification
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    final notification = NotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      category: category,
      data: data ?? {},
      timestamp: DateTime.now(),
      isLocal: true,
    );

    await _showNotification(notification, imageUrl: imageUrl);
    await _storeNotification(notification);
  }

  /// Schedule notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      category: category,
      data: data ?? {},
      timestamp: scheduledTime,
      isScheduled: true,
    );

    await _scheduleNotification(notification, scheduledTime);
    await _storeNotification(notification);
  }

  /// Get notification history
  Future<List<NotificationMessage>> getNotificationHistory({
    int? limit,
    NotificationCategory? category,
  }) async {
    // This would query the database for stored notifications
    // For now, return empty list
    return [];
  }

  /// Clear notification history
  Future<void> clearNotificationHistory() async {
    // Clear stored notifications from database
    await _localNotifications.cancelAll();
  }

  /// Get notification statistics
  Future<NotificationStatistics> getStatistics() async {
    // This would calculate statistics from stored notifications
    return NotificationStatistics(
      totalSent: 0,
      totalReceived: 0,
      totalClicked: 0,
      categoryCounts: {},
      deliveryRate: 0.0,
      clickThroughRate: 0.0,
    );
  }

  // Private methods

  Future<void> _setupNotificationCategories() async {
    // Critical alerts (vehicle emergencies, security breaches)
    _categories['critical'] = NotificationCategory(
      id: 'critical',
      name: 'Critical Alerts',
      description: 'Emergency and security alerts',
      priority: NotificationPriority.high,
      sound: 'emergency_alert.wav',
      vibrationPattern: [0, 1000, 500, 1000],
      ledColor: 0xFFFF0000, // Red
      importance: Importance.max,
      showBadge: true,
      playSound: true,
      enableVibration: true,
    );

    // Maintenance alerts (service due, low fuel, etc.)
    _categories['maintenance'] = NotificationCategory(
      id: 'maintenance',
      name: 'Maintenance Alerts',
      description: 'Vehicle maintenance and service reminders',
      priority: NotificationPriority.high,
      sound: 'maintenance_alert.wav',
      vibrationPattern: [0, 500, 250, 500],
      ledColor: 0xFFFF8000, // Orange
      importance: Importance.high,
      showBadge: true,
      playSound: true,
      enableVibration: true,
    );

    // Performance notifications (trip summaries, efficiency tips)
    _categories['performance'] = NotificationCategory(
      id: 'performance',
      name: 'Performance Updates',
      description: 'Vehicle performance and efficiency information',
      priority: NotificationPriority.normal,
      sound: 'notification.wav',
      vibrationPattern: [0, 250],
      ledColor: 0xFF0080FF, // Blue
      importance: Importance.defaultImportance,
      showBadge: true,
      playSound: true,
      enableVibration: false,
    );

    // Social notifications (chat messages, recommendations)
    _categories['social'] = NotificationCategory(
      id: 'social',
      name: 'Messages & Updates',
      description: 'Chat messages and social updates',
      priority: NotificationPriority.normal,
      sound: 'message.wav',
      vibrationPattern: [0, 200],
      ledColor: 0xFF00FF00, // Green
      importance: Importance.defaultImportance,
      showBadge: true,
      playSound: true,
      enableVibration: false,
    );

    // System notifications (app updates, sync status)
    _categories['system'] = NotificationCategory(
      id: 'system',
      name: 'System Updates',
      description: 'App updates and system notifications',
      priority: NotificationPriority.low,
      sound: null,
      vibrationPattern: [0, 100],
      ledColor: 0xFF808080, // Gray
      importance: Importance.low,
      showBadge: false,
      playSound: false,
      enableVibration: false,
    );

    // Marketing notifications (promotions, tips)
    _categories['marketing'] = NotificationCategory(
      id: 'marketing',
      name: 'Promotions & Tips',
      description: 'Promotional offers and helpful tips',
      priority: NotificationPriority.low,
      sound: null,
      vibrationPattern: [0, 100],
      ledColor: 0xFF800080, // Purple
      importance: Importance.low,
      showBadge: false,
      playSound: false,
      enableVibration: false,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    for (final category in _categories.values) {
      final androidChannel = AndroidNotificationChannel(
        category.id,
        category.name,
        description: category.description,
        importance: category.importance,
        playSound: category.playSound,
        sound: category.sound != null
            ? RawResourceAndroidNotificationSound(category.sound!)
            : null,
        enableVibration: category.enableVibration,
        vibrationPattern: Int64List.fromList(category.vibrationPattern),
        ledColor: Color(category.ledColor),
        showBadge: category.showBadge,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

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

    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTerminatedMessage(initialMessage);
    }
  }

  Future<void> _getToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Store token for server registration
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    final notification = _parseRemoteMessage(message);
    _messageStreamController?.add(notification);

    // Show local notification for foreground messages
    _showNotification(notification);
    _storeNotification(notification);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Received background message: ${message.messageId}');

    final notification = _parseRemoteMessage(message);
    _messageStreamController?.add(notification);
    _storeNotification(notification);
  }

  void _handleTerminatedMessage(RemoteMessage message) {
    debugPrint('Received terminated message: ${message.messageId}');

    final notification = _parseRemoteMessage(message);
    _messageStreamController?.add(notification);
    _storeNotification(notification);
  }

  NotificationMessage _parseRemoteMessage(RemoteMessage message) {
    final categoryId = message.data['category'] ?? 'system';
    final category = _categories[categoryId] ?? _categories['system']!;

    return NotificationMessage(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'AIVONITY',
      body: message.notification?.body ?? '',
      category: category,
      data: message.data,
      timestamp: DateTime.now(),
      imageUrl:
          message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
    );
  }

  Future<void> _showNotification(
    NotificationMessage notification, {
    String? imageUrl,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      notification.category.id,
      notification.category.name,
      channelDescription: notification.category.description,
      importance: notification.category.importance,
      priority: _mapPriorityToAndroid(notification.category.priority),
      playSound: notification.category.playSound,
      sound: notification.category.sound != null
          ? RawResourceAndroidNotificationSound(notification.category.sound!)
          : null,
      enableVibration: notification.category.enableVibration,
      vibrationPattern: Int64List.fromList(
        notification.category.vibrationPattern,
      ),
      ledColor: Color(notification.category.ledColor),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: BigTextStyleInformation(notification.body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: json.encode(notification.toJson()),
    );
  }

  Future<void> _scheduleNotification(
    NotificationMessage notification,
    DateTime scheduledTime,
  ) async {
    // TODO: Implement scheduling with timezone support
    // Requires timezone package and zonedSchedule
    debugPrint('Scheduled notification not implemented yet');
  }

  Priority _mapPriorityToAndroid(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        final notification = NotificationMessage.fromJson(data);

        // Handle notification tap
        _handleNotificationTap(notification);
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  void _handleNotificationTap(NotificationMessage notification) {
    // Add to stream for UI handling
    _messageStreamController?.add(notification.copyWith(isTapped: true));

    // Track click for analytics
    _trackNotificationClick(notification);
  }

  Future<void> _storeNotification(NotificationMessage notification) async {
    // Store notification in database for history
    // Implementation would depend on database schema
  }

  Future<void> _trackNotificationClick(NotificationMessage notification) async {
    // Track notification clicks for analytics
    debugPrint('Notification clicked: ${notification.id}');
  }

  void dispose() {
    _messageStreamController?.close();
  }
}

/// Notification category configuration
class NotificationCategory {
  final String id;
  final String name;
  final String description;
  final NotificationPriority priority;
  final String? sound;
  final List<int> vibrationPattern;
  final int ledColor;
  final Importance importance;
  final bool showBadge;
  final bool playSound;
  final bool enableVibration;

  NotificationCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.priority,
    this.sound,
    required this.vibrationPattern,
    required this.ledColor,
    required this.importance,
    required this.showBadge,
    required this.playSound,
    required this.enableVibration,
  });
}

/// Notification priority levels
enum NotificationPriority { low, normal, high }

/// Notification message model
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isLocal;
  final bool isScheduled;
  final bool isTapped;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.data,
    required this.timestamp,
    this.imageUrl,
    this.isLocal = false,
    this.isScheduled = false,
    this.isTapped = false,
  });

  NotificationMessage copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    String? imageUrl,
    bool? isLocal,
    bool? isScheduled,
    bool? isTapped,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      isLocal: isLocal ?? this.isLocal,
      isScheduled: isScheduled ?? this.isScheduled,
      isTapped: isTapped ?? this.isTapped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category_id': category.id,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'image_url': imageUrl,
      'is_local': isLocal,
      'is_scheduled': isScheduled,
      'is_tapped': isTapped,
    };
  }

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    // This would need access to categories map
    // Simplified implementation
    return NotificationMessage(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      category: NotificationCategory(
        id: json['category_id'] ?? 'system',
        name: 'System',
        description: 'System notification',
        priority: NotificationPriority.normal,
        vibrationPattern: [0, 250],
        ledColor: 0xFF808080,
        importance: Importance.defaultImportance,
        showBadge: true,
        playSound: true,
        enableVibration: false,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      imageUrl: json['image_url'],
      isLocal: json['is_local'] ?? false,
      isScheduled: json['is_scheduled'] ?? false,
      isTapped: json['is_tapped'] ?? false,
    );
  }
}

/// Notification statistics
class NotificationStatistics {
  final int totalSent;
  final int totalReceived;
  final int totalClicked;
  final Map<String, int> categoryCounts;
  final double deliveryRate;
  final double clickThroughRate;

  NotificationStatistics({
    required this.totalSent,
    required this.totalReceived,
    required this.totalClicked,
    required this.categoryCounts,
    required this.deliveryRate,
    required this.clickThroughRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_sent': totalSent,
      'total_received': totalReceived,
      'total_clicked': totalClicked,
      'category_counts': categoryCounts,
      'delivery_rate': deliveryRate,
      'click_through_rate': clickThroughRate,
    };
  }
}
