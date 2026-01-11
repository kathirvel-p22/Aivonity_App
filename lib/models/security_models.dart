/// Security-related data models for threat detection and fraud prevention
library;

/// Security event for behavioral analysis
class SecurityEvent {
  final String id;
  final String? userId;
  final SecurityEventType eventType;
  final DateTime timestamp;
  final String? location;
  final String? deviceInfo;
  final String? ipAddress;
  final Map<String, String>? metadata;

  SecurityEvent({
    required this.id,
    this.userId,
    required this.eventType,
    required this.timestamp,
    this.location,
    this.deviceInfo,
    this.ipAddress,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'eventType': eventType.name,
    'timestamp': timestamp.toIso8601String(),
    'location': location,
    'deviceInfo': deviceInfo,
    'ipAddress': ipAddress,
    'metadata': metadata,
  };

  factory SecurityEvent.fromJson(Map<String, dynamic> json) => SecurityEvent(
    id: json['id'],
    userId: json['userId'],
    eventType: SecurityEventType.values.firstWhere(
      (e) => e.name == json['eventType'],
    ),
    timestamp: DateTime.parse(json['timestamp']),
    location: json['location'],
    deviceInfo: json['deviceInfo'],
    ipAddress: json['ipAddress'],
    metadata: json['metadata'] != null
        ? Map<String, String>.from(json['metadata'])
        : null,
  );
}

/// Types of security events
enum SecurityEventType {
  login,
  logout,
  failedLogin,
  dataAccess,
  featureAccess,
  apiCall,
  threatDetected,
  anomalyDetected,
}

/// User behavior profile for anomaly detection
class UserBehaviorProfile {
  final String userId;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<int> loginTimes; // Hours of day
  final List<String> locations;
  final List<String> devices;
  final Map<String, int> featureUsage;
  final List<int> sessionDurations; // In minutes

  UserBehaviorProfile({
    required this.userId,
    required this.createdAt,
    required this.lastUpdated,
    required this.loginTimes,
    required this.locations,
    required this.devices,
    required this.featureUsage,
    required this.sessionDurations,
  });

  UserBehaviorProfile copyWith({
    String? userId,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<int>? loginTimes,
    List<String>? locations,
    List<String>? devices,
    Map<String, int>? featureUsage,
    List<int>? sessionDurations,
  }) {
    return UserBehaviorProfile(
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      loginTimes: loginTimes ?? this.loginTimes,
      locations: locations ?? this.locations,
      devices: devices ?? this.devices,
      featureUsage: featureUsage ?? this.featureUsage,
      sessionDurations: sessionDurations ?? this.sessionDurations,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'loginTimes': loginTimes,
    'locations': locations,
    'devices': devices,
    'featureUsage': featureUsage,
    'sessionDurations': sessionDurations,
  };

  factory UserBehaviorProfile.fromJson(Map<String, dynamic> json) =>
      UserBehaviorProfile(
        userId: json['userId'],
        createdAt: DateTime.parse(json['createdAt']),
        lastUpdated: DateTime.parse(json['lastUpdated']),
        loginTimes: List<int>.from(json['loginTimes']),
        locations: List<String>.from(json['locations']),
        devices: List<String>.from(json['devices']),
        featureUsage: Map<String, int>.from(json['featureUsage']),
        sessionDurations: List<int>.from(json['sessionDurations']),
      );
}

/// Threat alert
class ThreatAlert {
  final String id;
  final ThreatType threatType;
  final ThreatSeverity severity;
  final String? userId;
  final DateTime timestamp;
  final String details;
  final List<String> recommendedActions;

  ThreatAlert({
    required this.id,
    required this.threatType,
    required this.severity,
    this.userId,
    required this.timestamp,
    required this.details,
    required this.recommendedActions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'threatType': threatType.name,
    'severity': severity.name,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
    'recommendedActions': recommendedActions,
  };

  factory ThreatAlert.fromJson(Map<String, dynamic> json) => ThreatAlert(
    id: json['id'],
    threatType: ThreatType.values.firstWhere(
      (e) => e.name == json['threatType'],
    ),
    severity: ThreatSeverity.values.firstWhere(
      (e) => e.name == json['severity'],
    ),
    userId: json['userId'],
    timestamp: DateTime.parse(json['timestamp']),
    details: json['details'],
    recommendedActions: List<String>.from(json['recommendedActions']),
  );
}

/// Types of security threats
enum ThreatType {
  suspiciousLocation,
  unknownDevice,
  unusualTime,
  unauthorizedAccess,
  bruteForceAttack,
  credentialStuffing,
  apiAbuse,
  botBehavior,
}

/// Threat severity levels
enum ThreatSeverity { low, medium, high, critical }

/// Anomaly detection result
class AnomalyDetection {
  final String id;
  final AnomalyType anomalyType;
  final double confidence;
  final String userId;
  final DateTime timestamp;
  final String description;
  final String baseline;
  final String observed;

  AnomalyDetection({
    required this.id,
    required this.anomalyType,
    required this.confidence,
    required this.userId,
    required this.timestamp,
    required this.description,
    required this.baseline,
    required this.observed,
  });
}

/// Types of behavioral anomalies
enum AnomalyType {
  unusualFrequency,
  newLocation,
  unusualTime,
  unusualFeatureUsage,
  suspiciousPattern,
}

/// Behavioral anomaly details
class BehavioralAnomaly {
  final AnomalyType type;
  final double confidence;
  final String description;
  final String baseline;
  final String observed;

  BehavioralAnomaly({
    required this.type,
    required this.confidence,
    required this.description,
    required this.baseline,
    required this.observed,
  });
}

/// Login attempt for fraud analysis
class LoginAttempt {
  final String userId;
  final DateTime timestamp;
  final String ipAddress;
  final String? location;
  final String? deviceInfo;
  final String? userAgent;
  final bool successful;

  LoginAttempt({
    required this.userId,
    required this.timestamp,
    required this.ipAddress,
    this.location,
    this.deviceInfo,
    this.userAgent,
    required this.successful,
  });
}

/// Fraud analysis result
class FraudAnalysisResult {
  final RiskLevel riskLevel;
  final double riskScore;
  final List<RiskFactor> riskFactors;
  final String recommendedAction;

  FraudAnalysisResult({
    required this.riskLevel,
    required this.riskScore,
    required this.riskFactors,
    required this.recommendedAction,
  });
}

/// Risk factor for fraud detection
class RiskFactor {
  final String name;
  final String description;
  final double weight;
  final RiskFactorType type;

  RiskFactor({
    required this.name,
    required this.description,
    required this.weight,
    required this.type,
  });
}

/// Types of risk factors
enum RiskFactorType { location, device, timing, velocity, behavioral }

/// Risk levels
enum RiskLevel { low, medium, high, critical }

/// Threat detection statistics
class ThreatDetectionStats {
  final int totalThreatsDetected;
  final int recentThreats;
  final int activeProfiles;
  final double anomalyThreshold;

  ThreatDetectionStats({
    required this.totalThreatsDetected,
    required this.recentThreats,
    required this.activeProfiles,
    required this.anomalyThreshold,
  });
}

/// Security incident for automated response
class SecurityIncident {
  final String id;
  final ThreatAlert? threatAlert;
  final AnomalyDetection? anomalyDetection;
  final IncidentSeverity severity;
  IncidentStatus status;
  final DateTime createdAt;
  DateTime lastUpdated;
  final List<ResponseActionRecord> responseActions;
  final List<String> affectedUsers;

  SecurityIncident({
    required this.id,
    this.threatAlert,
    this.anomalyDetection,
    required this.severity,
    required this.status,
    required this.createdAt,
    required this.lastUpdated,
    required this.responseActions,
    required this.affectedUsers,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'threatAlert': threatAlert?.toJson(),
    'anomalyDetection': anomalyDetection != null
        ? {
            'id': anomalyDetection!.id,
            'anomalyType': anomalyDetection!.anomalyType.name,
            'confidence': anomalyDetection!.confidence,
            'userId': anomalyDetection!.userId,
            'timestamp': anomalyDetection!.timestamp.toIso8601String(),
            'description': anomalyDetection!.description,
          }
        : null,
    'severity': severity.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    'responseActions': responseActions.map((a) => a.toJson()).toList(),
    'affectedUsers': affectedUsers,
  };

  factory SecurityIncident.fromJson(Map<String, dynamic> json) =>
      SecurityIncident(
        id: json['id'],
        threatAlert: json['threatAlert'] != null
            ? ThreatAlert.fromJson(json['threatAlert'])
            : null,
        severity: IncidentSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
        ),
        status: IncidentStatus.values.firstWhere(
          (e) => e.name == json['status'],
        ),
        createdAt: DateTime.parse(json['createdAt']),
        lastUpdated: DateTime.parse(json['lastUpdated']),
        responseActions: (json['responseActions'] as List)
            .map((a) => ResponseActionRecord.fromJson(a))
            .toList(),
        affectedUsers: List<String>.from(json['affectedUsers']),
      );
}

/// Incident severity levels
enum IncidentSeverity { low, medium, high, critical }

/// Incident status
enum IncidentStatus { open, investigating, contained, resolved, escalated }

/// Response action for automated incident response
class ResponseAction {
  final ResponseActionType type;
  final String? targetUserId;
  final Duration? duration;
  final String? message;

  ResponseAction({
    required this.type,
    this.targetUserId,
    this.duration,
    this.message,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'targetUserId': targetUserId,
    'duration': duration?.inMilliseconds,
    'message': message,
  };

  factory ResponseAction.fromJson(Map<String, dynamic> json) => ResponseAction(
    type: ResponseActionType.values.firstWhere((e) => e.name == json['type']),
    targetUserId: json['targetUserId'],
    duration: json['duration'] != null
        ? Duration(milliseconds: json['duration'])
        : null,
    message: json['message'],
  );
}

/// Types of automated response actions
enum ResponseActionType {
  blockUser,
  requireMFA,
  quarantineSession,
  sendAlert,
  logEvent,
  escalateToAdmin,
  revokeTokens,
  lockAccount,
}

/// Record of executed response action
class ResponseActionRecord {
  final ResponseAction action;
  final DateTime executedAt;
  final bool successful;
  final String details;

  ResponseActionRecord({
    required this.action,
    required this.executedAt,
    required this.successful,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
    'action': action.toJson(),
    'executedAt': executedAt.toIso8601String(),
    'successful': successful,
    'details': details,
  };

  factory ResponseActionRecord.fromJson(Map<String, dynamic> json) =>
      ResponseActionRecord(
        action: ResponseAction.fromJson(json['action']),
        executedAt: DateTime.parse(json['executedAt']),
        successful: json['successful'],
        details: json['details'],
      );
}

/// Response rule for automated incident handling
class ResponseRule {
  final String id;
  final String name;
  final IncidentSeverity? triggerSeverity;
  final ThreatType? triggerThreatType;
  final AnomalyType? triggerAnomalyType;
  final List<ResponseAction> actions;

  ResponseRule({
    required this.id,
    required this.name,
    this.triggerSeverity,
    this.triggerThreatType,
    this.triggerAnomalyType,
    required this.actions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'triggerSeverity': triggerSeverity?.name,
    'triggerThreatType': triggerThreatType?.name,
    'triggerAnomalyType': triggerAnomalyType?.name,
    'actions': actions.map((a) => a.toJson()).toList(),
  };

  factory ResponseRule.fromJson(Map<String, dynamic> json) => ResponseRule(
    id: json['id'],
    name: json['name'],
    triggerSeverity: json['triggerSeverity'] != null
        ? IncidentSeverity.values.firstWhere(
            (e) => e.name == json['triggerSeverity'],
          )
        : null,
    triggerThreatType: json['triggerThreatType'] != null
        ? ThreatType.values.firstWhere(
            (e) => e.name == json['triggerThreatType'],
          )
        : null,
    triggerAnomalyType: json['triggerAnomalyType'] != null
        ? AnomalyType.values.firstWhere(
            (e) => e.name == json['triggerAnomalyType'],
          )
        : null,
    actions: (json['actions'] as List)
        .map((a) => ResponseAction.fromJson(a))
        .toList(),
  );
}

/// Session quarantine information
class SessionQuarantine {
  final String id;
  final String userId;
  final DateTime quarantinedAt;
  final String reason;
  final List<String> restrictions;

  SessionQuarantine({
    required this.id,
    required this.userId,
    required this.quarantinedAt,
    required this.reason,
    required this.restrictions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'quarantinedAt': quarantinedAt.toIso8601String(),
    'reason': reason,
    'restrictions': restrictions,
  };

  factory SessionQuarantine.fromJson(Map<String, dynamic> json) =>
      SessionQuarantine(
        id: json['id'],
        userId: json['userId'],
        quarantinedAt: DateTime.parse(json['quarantinedAt']),
        reason: json['reason'],
        restrictions: List<String>.from(json['restrictions']),
      );
}
