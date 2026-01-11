import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

/// Alert severity levels
enum AlertSeverity { info, low, medium, high, critical }

/// Alert categories
enum AlertCategory {
  engine,
  battery,
  fuel,
  temperature,
  pressure,
  diagnostic,
  security,
  maintenance,
  system,
}

/// Alert action types
enum AlertAction { acknowledge, dismiss, snooze, escalate, resolve }

/// Enhanced alert model with categorization
class EnhancedAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final AlertCategory category;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final List<String> recommendedActions;
  final bool acknowledged;
  final bool dismissed;
  final DateTime? snoozeUntil;
  final String? vehicleId;
  final String? userId;

  EnhancedAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.timestamp,
    required this.data,
    this.recommendedActions = const [],
    this.acknowledged = false,
    this.dismissed = false,
    this.snoozeUntil,
    this.vehicleId,
    this.userId,
  });

  factory EnhancedAlert.fromJson(Map<String, dynamic> json) {
    return EnhancedAlert(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: AlertSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      category: AlertCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AlertCategory.system,
      ),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      data: json['data'] ?? {},
      recommendedActions: List<String>.from(json['recommended_actions'] ?? []),
      acknowledged: json['acknowledged'] ?? false,
      dismissed: json['dismissed'] ?? false,
      snoozeUntil: json['snooze_until'] != null
          ? DateTime.parse(json['snooze_until'])
          : null,
      vehicleId: json['vehicle_id'],
      userId: json['user_id'],
    );
  }

  EnhancedAlert copyWith({
    bool? acknowledged,
    bool? dismissed,
    DateTime? snoozeUntil,
  }) {
    return EnhancedAlert(
      id: id,
      title: title,
      message: message,
      severity: severity,
      category: category,
      timestamp: timestamp,
      data: data,
      recommendedActions: recommendedActions,
      acknowledged: acknowledged ?? this.acknowledged,
      dismissed: dismissed ?? this.dismissed,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      vehicleId: vehicleId,
      userId: userId,
    );
  }
}

/// Alert notification preferences
class AlertPreferences {
  final bool pushNotificationsEnabled;
  final bool localNotificationsEnabled;
  final Map<AlertSeverity, bool> severityFilters;
  final Map<AlertCategory, bool> categoryFilters;
  final bool quietHoursEnabled;
  final int quietHoursStart; // Hour of day (0-23)
  final int quietHoursEnd; // Hour of day (0-23)
  final bool vibrationEnabled;
  final bool soundEnabled;

  AlertPreferences({
    this.pushNotificationsEnabled = true,
    this.localNotificationsEnabled = true,
    this.severityFilters = const {
      AlertSeverity.critical: true,
      AlertSeverity.high: true,
      AlertSeverity.medium: true,
      AlertSeverity.low: false,
      AlertSeverity.info: false,
    },
    this.categoryFilters = const {
      AlertCategory.engine: true,
      AlertCategory.battery: true,
      AlertCategory.fuel: true,
      AlertCategory.temperature: true,
      AlertCategory.pressure: true,
      AlertCategory.diagnostic: true,
      AlertCategory.security: true,
      AlertCategory.maintenance: true,
      AlertCategory.system: false,
    },
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22, // 10 PM
    this.quietHoursEnd = 7, // 7 AM
    this.vibrationEnabled = true,
    this.soundEnabled = true,
  });
}

/// Advanced alert service with local notifications
class AlertService {
  // Alert streams
  final PublishSubject<EnhancedAlert> _alertController =
      PublishSubject<EnhancedAlert>();
  final BehaviorSubject<List<EnhancedAlert>> _alertsController =
      BehaviorSubject<List<EnhancedAlert>>.seeded([]);
  final PublishSubject<String> _alertActionController =
      PublishSubject<String>();

  // Preferences
  AlertPreferences _preferences = AlertPreferences();

  // Alert storage
  final List<EnhancedAlert> _alerts = [];

  // Initialization status
  bool _initialized = false;

  // Getters for streams
  Stream<EnhancedAlert> get alertStream => _alertController.stream;
  Stream<List<EnhancedAlert>> get alertsStream => _alertsController.stream;
  Stream<String> get alertActionStream => _alertActionController.stream;

  List<EnhancedAlert> get currentAlerts => List.unmodifiable(_alerts);
  AlertPreferences get preferences => _preferences;

  /// Initialize the alert service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _initialized = true;
      debugPrint('✅ Alert service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing alert service: $e');
      rethrow;
    }
  }

  /// Process incoming alert
  void processAlert(EnhancedAlert alert) {
    // Check if alert should be filtered
    if (!_shouldShowAlert(alert)) {
      debugPrint('🔇 Alert filtered: ${alert.id}');
      return;
    }

    // Add to alerts list
    _alerts.insert(0, alert);

    // Keep only last 100 alerts
    if (_alerts.length > 100) {
      _alerts.removeRange(100, _alerts.length);
    }

    // Emit alert
    _alertController.add(alert);
    _alertsController.add(List.from(_alerts));

    debugPrint('🚨 Alert processed: ${alert.severity.name} - ${alert.title}');
  }

  /// Check if alert should be shown based on preferences
  bool _shouldShowAlert(EnhancedAlert alert) {
    // Check severity filter
    if (!(_preferences.severityFilters[alert.severity] ?? true)) {
      return false;
    }

    // Check category filter
    if (!(_preferences.categoryFilters[alert.category] ?? true)) {
      return false;
    }

    // Check quiet hours
    if (_preferences.quietHoursEnabled && _isQuietHours()) {
      // Only show critical alerts during quiet hours
      return alert.severity == AlertSeverity.critical;
    }

    return true;
  }

  /// Check if current time is within quiet hours
  bool _isQuietHours() {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (_preferences.quietHoursStart <= _preferences.quietHoursEnd) {
      // Same day range (e.g., 22:00 - 07:00 next day)
      return currentHour >= _preferences.quietHoursStart &&
          currentHour < _preferences.quietHoursEnd;
    } else {
      // Cross-day range (e.g., 22:00 - 07:00 next day)
      return currentHour >= _preferences.quietHoursStart ||
          currentHour < _preferences.quietHoursEnd;
    }
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      final alertIndex = _alerts.indexWhere((a) => a.id == alertId);
      if (alertIndex != -1) {
        _alerts[alertIndex] = _alerts[alertIndex].copyWith(acknowledged: true);
        _alertsController.add(List.from(_alerts));

        debugPrint('✅ Alert acknowledged: $alertId');
      }
    } catch (e) {
      debugPrint('❌ Error acknowledging alert: $e');
    }
  }

  /// Dismiss an alert
  Future<void> dismissAlert(String alertId) async {
    try {
      final alertIndex = _alerts.indexWhere((a) => a.id == alertId);
      if (alertIndex != -1) {
        _alerts[alertIndex] = _alerts[alertIndex].copyWith(dismissed: true);
        _alertsController.add(List.from(_alerts));

        debugPrint('🗑️ Alert dismissed: $alertId');
      }
    } catch (e) {
      debugPrint('❌ Error dismissing alert: $e');
    }
  }

  /// Snooze an alert
  Future<void> snoozeAlert(String alertId, Duration duration) async {
    try {
      final alertIndex = _alerts.indexWhere((a) => a.id == alertId);
      if (alertIndex != -1) {
        final snoozeUntil = DateTime.now().add(duration);
        _alerts[alertIndex] = _alerts[alertIndex].copyWith(
          snoozeUntil: snoozeUntil,
        );
        _alertsController.add(List.from(_alerts));

        debugPrint('😴 Alert snoozed until $snoozeUntil: $alertId');
      }
    } catch (e) {
      debugPrint('❌ Error snoozing alert: $e');
    }
  }

  /// Update alert preferences
  void updatePreferences(AlertPreferences preferences) {
    _preferences = preferences;
    debugPrint('⚙️ Alert preferences updated');
  }

  /// Get alerts by severity
  List<EnhancedAlert> getAlertsBySeverity(AlertSeverity severity) {
    return _alerts.where((alert) => alert.severity == severity).toList();
  }

  /// Get alerts by category
  List<EnhancedAlert> getAlertsByCategory(AlertCategory category) {
    return _alerts.where((alert) => alert.category == category).toList();
  }

  /// Get unacknowledged alerts
  List<EnhancedAlert> getUnacknowledgedAlerts() {
    return _alerts
        .where((alert) => !alert.acknowledged && !alert.dismissed)
        .toList();
  }

  /// Clear all alerts
  void clearAllAlerts() {
    _alerts.clear();
    _alertsController.add([]);
    debugPrint('🧹 All alerts cleared');
  }

  /// Dispose resources
  void dispose() {
    _alertController.close();
    _alertsController.close();
    _alertActionController.close();
  }
}

