/// AIVONITY User Model
/// Simplified user model without external dependencies
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;
  final String language;
  final String role;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.isVerified = false,
    this.language = 'en',
    this.role = 'user',
    required this.preferences,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      role: json['role'] as String? ?? 'user',
      preferences: UserPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'language': language,
      'role': role,
      'preferences': preferences.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatarUrl,
    bool? isVerified,
    String? language,
    String? role,
    UserPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      language: language ?? this.language,
      role: role ?? this.role,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// User Preferences Model
class UserPreferences {
  final String theme;
  final String language;
  final bool darkMode;
  final NotificationPreferences notifications;
  final DashboardPreferences dashboard;
  final PrivacyPreferences privacy;
  final String timeZone;

  const UserPreferences({
    this.theme = 'system',
    this.language = 'en',
    this.darkMode = false,
    required this.notifications,
    required this.dashboard,
    required this.privacy,
    this.timeZone = 'UTC',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      darkMode: json['darkMode'] as bool? ?? false,
      notifications: NotificationPreferences.fromJson(
        json['notifications'] as Map<String, dynamic>? ?? {},
      ),
      dashboard: DashboardPreferences.fromJson(
        json['dashboard'] as Map<String, dynamic>? ?? {},
      ),
      privacy: PrivacyPreferences.fromJson(
        json['privacy'] as Map<String, dynamic>? ?? {},
      ),
      timeZone: json['timeZone'] as String? ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'darkMode': darkMode,
      'notifications': notifications.toJson(),
      'dashboard': dashboard.toJson(),
      'privacy': privacy.toJson(),
      'timeZone': timeZone,
    };
  }

  UserPreferences copyWith({
    String? theme,
    String? language,
    bool? darkMode,
    NotificationPreferences? notifications,
    DashboardPreferences? dashboard,
    PrivacyPreferences? privacy,
    String? timeZone,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      dashboard: dashboard ?? this.dashboard,
      privacy: privacy ?? this.privacy,
      timeZone: timeZone ?? this.timeZone,
    );
  }
}

/// Notification Preferences Model
class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool healthAlerts;
  final bool maintenanceReminders;
  final bool bookingUpdates;
  final bool marketingEmails;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.healthAlerts = true,
    this.maintenanceReminders = true,
    this.bookingUpdates = true,
    this.marketingEmails = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      smsEnabled: json['smsEnabled'] as bool? ?? false,
      healthAlerts: json['healthAlerts'] as bool? ?? true,
      maintenanceReminders: json['maintenanceReminders'] as bool? ?? true,
      bookingUpdates: json['bookingUpdates'] as bool? ?? true,
      marketingEmails: json['marketingEmails'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
      'healthAlerts': healthAlerts,
      'maintenanceReminders': maintenanceReminders,
      'bookingUpdates': bookingUpdates,
      'marketingEmails': marketingEmails,
    };
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? healthAlerts,
    bool? maintenanceReminders,
    bool? bookingUpdates,
    bool? marketingEmails,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      healthAlerts: healthAlerts ?? this.healthAlerts,
      maintenanceReminders: maintenanceReminders ?? this.maintenanceReminders,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }
}

/// Dashboard Preferences Model
class DashboardPreferences {
  final String defaultView;
  final List<String> visibleWidgets;
  final bool showWeather;
  final String refreshInterval;

  const DashboardPreferences({
    this.defaultView = 'overview',
    this.visibleWidgets = const ['health', 'alerts', 'performance'],
    this.showWeather = true,
    this.refreshInterval = '30s',
  });

  factory DashboardPreferences.fromJson(Map<String, dynamic> json) {
    return DashboardPreferences(
      defaultView: json['defaultView'] as String? ?? 'overview',
      visibleWidgets:
          (json['visibleWidgets'] as List<dynamic>?)?.cast<String>() ??
          const ['health', 'alerts', 'performance'],
      showWeather: json['showWeather'] as bool? ?? true,
      refreshInterval: json['refreshInterval'] as String? ?? '30s',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultView': defaultView,
      'visibleWidgets': visibleWidgets,
      'showWeather': showWeather,
      'refreshInterval': refreshInterval,
    };
  }

  DashboardPreferences copyWith({
    String? defaultView,
    List<String>? visibleWidgets,
    bool? showWeather,
    String? refreshInterval,
  }) {
    return DashboardPreferences(
      defaultView: defaultView ?? this.defaultView,
      visibleWidgets: visibleWidgets ?? this.visibleWidgets,
      showWeather: showWeather ?? this.showWeather,
      refreshInterval: refreshInterval ?? this.refreshInterval,
    );
  }
}

/// Privacy Preferences Model
class PrivacyPreferences {
  final bool shareAnalytics;
  final bool shareLocation;
  final bool shareUsageData;

  const PrivacyPreferences({
    this.shareAnalytics = false,
    this.shareLocation = true,
    this.shareUsageData = false,
  });

  factory PrivacyPreferences.fromJson(Map<String, dynamic> json) {
    return PrivacyPreferences(
      shareAnalytics: json['shareAnalytics'] as bool? ?? false,
      shareLocation: json['shareLocation'] as bool? ?? true,
      shareUsageData: json['shareUsageData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareAnalytics': shareAnalytics,
      'shareLocation': shareLocation,
      'shareUsageData': shareUsageData,
    };
  }

  PrivacyPreferences copyWith({
    bool? shareAnalytics,
    bool? shareLocation,
    bool? shareUsageData,
  }) {
    return PrivacyPreferences(
      shareAnalytics: shareAnalytics ?? this.shareAnalytics,
      shareLocation: shareLocation ?? this.shareLocation,
      shareUsageData: shareUsageData ?? this.shareUsageData,
    );
  }
}

