import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/security_models.dart';

/// Advanced threat detection service with behavioral analysis and fraud prevention
class ThreatDetectionService {
  static const String _behaviorProfilePrefix = 'behavior_profile_';
  static const String _threatLogPrefix = 'threat_log_';
  static const String _anomalyThresholdKey = 'anomaly_threshold';

  final StreamController<ThreatAlert> _threatController =
      StreamController<ThreatAlert>.broadcast();
  final StreamController<AnomalyDetection> _anomalyController =
      StreamController<AnomalyDetection>.broadcast();

  SharedPreferences? _prefs;
  Timer? _monitoringTimer;

  // Behavioral baselines
  final Map<String, UserBehaviorProfile> _behaviorProfiles = {};
  final List<SecurityEvent> _recentEvents = [];

  // Threat detection parameters
  double _anomalyThreshold = 0.7;
  final int _maxRecentEvents = 1000;
  final Duration _behaviorWindow = Duration(hours: 24);

  /// Streams for threat alerts and anomaly detection
  Stream<ThreatAlert> get threatStream => _threatController.stream;
  Stream<AnomalyDetection> get anomalyStream => _anomalyController.stream;

  /// Initialize the threat detection service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _anomalyThreshold = _prefs?.getDouble(_anomalyThresholdKey) ?? 0.7;

    await _loadBehaviorProfiles();
    _startContinuousMonitoring();

    debugPrint('🛡️ Threat detection service initialized');
  }

  /// Record a security event for analysis
  Future<void> recordSecurityEvent(SecurityEvent event) async {
    _recentEvents.add(event);

    // Maintain event history size
    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeAt(0);
    }

    // Update user behavior profile
    await _updateBehaviorProfile(event);

    // Analyze for threats
    await _analyzeEventForThreats(event);

    // Check for behavioral anomalies
    await _checkBehavioralAnomalies(event);
  }

  /// Analyze login attempt for fraud detection
  Future<FraudAnalysisResult> analyzeFraudRisk(LoginAttempt attempt) async {
    final riskFactors = <RiskFactor>[];
    double riskScore = 0.0;

    // Check for suspicious patterns
    riskFactors.addAll(await _checkLocationAnomalies(attempt));
    riskFactors.addAll(await _checkDeviceAnomalies(attempt));
    riskFactors.addAll(await _checkTimeAnomalies(attempt));
    riskFactors.addAll(await _checkVelocityAnomalies(attempt));

    // Calculate overall risk score
    for (final factor in riskFactors) {
      riskScore += factor.weight;
    }

    final riskLevel = _calculateRiskLevel(riskScore);

    // Log high-risk attempts
    if (riskLevel == RiskLevel.high || riskLevel == RiskLevel.critical) {
      await _logFraudAttempt(attempt, riskFactors, riskScore);
    }

    return FraudAnalysisResult(
      riskLevel: riskLevel,
      riskScore: riskScore,
      riskFactors: riskFactors,
      recommendedAction: _getRecommendedAction(riskLevel),
    );
  }

  /// Detect behavioral anomalies in user patterns
  Future<List<BehavioralAnomaly>> detectBehavioralAnomalies(
    String userId,
  ) async {
    final profile = _behaviorProfiles[userId];
    if (profile == null) return [];

    final anomalies = <BehavioralAnomaly>[];
    final recentUserEvents = _recentEvents
        .where((event) => event.userId == userId)
        .where(
          (event) =>
              DateTime.now().difference(event.timestamp) <= _behaviorWindow,
        )
        .toList();

    if (recentUserEvents.isEmpty) return anomalies;

    // Check usage pattern anomalies
    anomalies.addAll(_detectUsagePatternAnomalies(profile, recentUserEvents));

    // Check location anomalies
    anomalies.addAll(_detectLocationAnomalies(profile, recentUserEvents));

    // Check time-based anomalies
    anomalies.addAll(_detectTimeAnomalies(profile, recentUserEvents));

    // Check feature usage anomalies
    anomalies.addAll(_detectFeatureUsageAnomalies(profile, recentUserEvents));

    return anomalies;
  }

  /// Monitor for automated attack patterns
  Future<void> detectAutomatedAttacks() async {
    final recentEvents = _recentEvents
        .where(
          (event) =>
              DateTime.now().difference(event.timestamp) <=
              Duration(minutes: 15),
        )
        .toList();

    // Check for brute force attacks
    await _detectBruteForceAttacks(recentEvents);

    // Check for credential stuffing
    await _detectCredentialStuffing(recentEvents);

    // Check for API abuse
    await _detectApiAbuse(recentEvents);

    // Check for bot behavior
    await _detectBotBehavior(recentEvents);
  }

  /// Get threat detection statistics
  Future<ThreatDetectionStats> getStats() async {
    final allKeys = _prefs?.getKeys() ?? <String>{};
    final threatLogs = allKeys
        .where((key) => key.startsWith(_threatLogPrefix))
        .length;

    final recentThreats = _recentEvents
        .where((event) => event.eventType == SecurityEventType.threatDetected)
        .where(
          (event) =>
              DateTime.now().difference(event.timestamp) <= Duration(days: 7),
        )
        .length;

    return ThreatDetectionStats(
      totalThreatsDetected: threatLogs,
      recentThreats: recentThreats,
      activeProfiles: _behaviorProfiles.length,
      anomalyThreshold: _anomalyThreshold,
    );
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _threatController.close();
    _anomalyController.close();
  }

  // Private helper methods

  Future<void> _loadBehaviorProfiles() async {
    final allKeys = _prefs?.getKeys() ?? <String>{};

    for (final key in allKeys) {
      if (key.startsWith(_behaviorProfilePrefix)) {
        final userId = key.substring(_behaviorProfilePrefix.length);
        final profileJson = _prefs?.getString(key);

        if (profileJson != null) {
          try {
            final profile = UserBehaviorProfile.fromJson(
              jsonDecode(profileJson),
            );
            _behaviorProfiles[userId] = profile;
          } catch (e) {
            debugPrint('❌ Failed to load behavior profile for $userId: $e');
          }
        }
      }
    }

    debugPrint('📊 Loaded ${_behaviorProfiles.length} behavior profiles');
  }

  Future<void> _updateBehaviorProfile(SecurityEvent event) async {
    final userId = event.userId;
    if (userId == null) return;

    UserBehaviorProfile profile =
        _behaviorProfiles[userId] ??
        UserBehaviorProfile(
          userId: userId,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          loginTimes: [],
          locations: [],
          devices: [],
          featureUsage: {},
          sessionDurations: [],
        );

    // Update profile based on event type
    switch (event.eventType) {
      case SecurityEventType.login:
        profile = profile.copyWith(
          loginTimes: [...profile.loginTimes, event.timestamp.hour],
          locations: event.location != null
              ? [...profile.locations, event.location!]
              : profile.locations,
          devices: event.deviceInfo != null
              ? [...profile.devices, event.deviceInfo!]
              : profile.devices,
          lastUpdated: DateTime.now(),
        );
        break;
      case SecurityEventType.featureAccess:
        final featureUsage = Map<String, int>.from(profile.featureUsage);
        final feature = event.metadata?['feature'] ?? 'unknown';
        featureUsage[feature] = (featureUsage[feature] ?? 0) + 1;
        profile = profile.copyWith(
          featureUsage: featureUsage,
          lastUpdated: DateTime.now(),
        );
        break;
      case SecurityEventType.logout:
        if (event.metadata?['sessionDuration'] != null) {
          final duration =
              int.tryParse(event.metadata!['sessionDuration']!) ?? 0;
          profile = profile.copyWith(
            sessionDurations: [...profile.sessionDurations, duration],
            lastUpdated: DateTime.now(),
          );
        }
        break;
      default:
        break;
    }

    // Limit profile data size
    profile = _trimProfileData(profile);

    _behaviorProfiles[userId] = profile;

    // Save to persistent storage
    await _prefs?.setString(
      '$_behaviorProfilePrefix$userId',
      jsonEncode(profile.toJson()),
    );
  }

  void _startContinuousMonitoring() {
    _monitoringTimer = Timer.periodic(Duration(minutes: 5), (_) async {
      await detectAutomatedAttacks();
    });
  }

  List<BehavioralAnomaly> _detectUsagePatternAnomalies(
    UserBehaviorProfile profile,
    List<SecurityEvent> recentEvents,
  ) {
    final anomalies = <BehavioralAnomaly>[];

    // Check session frequency
    final loginEvents = recentEvents
        .where((e) => e.eventType == SecurityEventType.login)
        .length;
    final avgLogins =
        profile.loginTimes.length / 7; // Average per day over a week

    if (loginEvents > avgLogins * 3) {
      anomalies.add(
        BehavioralAnomaly(
          type: AnomalyType.unusualFrequency,
          confidence: 0.8,
          description: 'Unusually high login frequency detected',
          baseline: avgLogins.toString(),
          observed: loginEvents.toString(),
        ),
      );
    }

    return anomalies;
  }

  UserBehaviorProfile _trimProfileData(UserBehaviorProfile profile) {
    const maxEntries = 100;

    return profile.copyWith(
      loginTimes: profile.loginTimes.length > maxEntries
          ? profile.loginTimes.sublist(profile.loginTimes.length - maxEntries)
          : profile.loginTimes,
      locations: profile.locations.length > maxEntries
          ? profile.locations.sublist(profile.locations.length - maxEntries)
          : profile.locations,
      devices: profile.devices.length > maxEntries
          ? profile.devices.sublist(profile.devices.length - maxEntries)
          : profile.devices,
      sessionDurations: profile.sessionDurations.length > maxEntries
          ? profile.sessionDurations.sublist(
              profile.sessionDurations.length - maxEntries,
            )
          : profile.sessionDurations,
    );
  }

  // Placeholder methods for threat analysis
  Future<void> _analyzeEventForThreats(SecurityEvent event) async {}
  Future<void> _checkBehavioralAnomalies(SecurityEvent event) async {}
  Future<List<RiskFactor>> _checkLocationAnomalies(
    LoginAttempt attempt,
  ) async => [];
  Future<List<RiskFactor>> _checkDeviceAnomalies(LoginAttempt attempt) async =>
      [];
  Future<List<RiskFactor>> _checkTimeAnomalies(LoginAttempt attempt) async =>
      [];
  Future<List<RiskFactor>> _checkVelocityAnomalies(
    LoginAttempt attempt,
  ) async => [];
  Future<void> _detectBruteForceAttacks(List<SecurityEvent> events) async {}
  Future<void> _detectCredentialStuffing(List<SecurityEvent> events) async {}
  Future<void> _detectApiAbuse(List<SecurityEvent> events) async {}
  Future<void> _detectBotBehavior(List<SecurityEvent> events) async {}
  Future<void> _logFraudAttempt(
    LoginAttempt attempt,
    List<RiskFactor> factors,
    double score,
  ) async {}

  RiskLevel _calculateRiskLevel(double score) {
    if (score >= 0.8) return RiskLevel.critical;
    if (score >= 0.6) return RiskLevel.high;
    if (score >= 0.4) return RiskLevel.medium;
    return RiskLevel.low;
  }

  String _getRecommendedAction(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return 'Block access immediately';
      case RiskLevel.high:
        return 'Require additional authentication';
      case RiskLevel.medium:
        return 'Monitor closely';
      case RiskLevel.low:
        return 'Allow with logging';
    }
  }

  List<BehavioralAnomaly> _detectLocationAnomalies(
    UserBehaviorProfile profile,
    List<SecurityEvent> recentEvents,
  ) => [];
  List<BehavioralAnomaly> _detectTimeAnomalies(
    UserBehaviorProfile profile,
    List<SecurityEvent> recentEvents,
  ) => [];
  List<BehavioralAnomaly> _detectFeatureUsageAnomalies(
    UserBehaviorProfile profile,
    List<SecurityEvent> recentEvents,
  ) => [];
}
