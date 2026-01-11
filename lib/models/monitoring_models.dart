/// Security monitoring and auditing related data models
library;

import 'security_models.dart' show RiskLevel, ThreatType;

/// Audit event for comprehensive logging
class AuditEvent {
  final String id;
  final String? userId;
  final String action;
  final String resource;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? metadata;
  final AuditSeverity severity;
  final String category;

  AuditEvent({
    required this.id,
    this.userId,
    required this.action,
    required this.resource,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.metadata,
    required this.severity,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'action': action,
    'resource': resource,
    'timestamp': timestamp.toIso8601String(),
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'metadata': metadata,
    'severity': severity.name,
    'category': category,
  };

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
    id: json['id'],
    userId: json['userId'],
    action: json['action'],
    resource: json['resource'],
    timestamp: DateTime.parse(json['timestamp']),
    ipAddress: json['ipAddress'],
    userAgent: json['userAgent'],
    metadata: json['metadata'] != null
        ? Map<String, dynamic>.from(json['metadata'])
        : null,
    severity: AuditSeverity.values.firstWhere(
      (e) => e.name == json['severity'],
    ),
    category: json['category'],
  );
}

/// Audit event severity levels
enum AuditSeverity { low, medium, high, critical }

/// Security metrics for monitoring
class SecurityMetrics {
  int totalEvents;
  int criticalEvents;
  int highSeverityEvents;
  int mediumSeverityEvents;
  int lowSeverityEvents;
  double overallSecurityScore;
  DateTime lastUpdated;

  SecurityMetrics({
    required this.totalEvents,
    required this.criticalEvents,
    required this.highSeverityEvents,
    required this.mediumSeverityEvents,
    required this.lowSeverityEvents,
    required this.overallSecurityScore,
    required this.lastUpdated,
  });

  factory SecurityMetrics.empty() => SecurityMetrics(
    totalEvents: 0,
    criticalEvents: 0,
    highSeverityEvents: 0,
    mediumSeverityEvents: 0,
    lowSeverityEvents: 0,
    overallSecurityScore: 100.0,
    lastUpdated: DateTime.now(),
  );
}

/// Alert rule for automated monitoring
class AlertRule {
  final String id;
  final String name;
  final String description;
  final String condition;
  final AlertSeverity severity;
  final bool enabled;

  AlertRule({
    required this.id,
    required this.name,
    required this.description,
    required this.condition,
    required this.severity,
    required this.enabled,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'condition': condition,
    'severity': severity.name,
    'enabled': enabled,
  };

  factory AlertRule.fromJson(Map<String, dynamic> json) => AlertRule(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    condition: json['condition'],
    severity: AlertSeverity.values.firstWhere(
      (e) => e.name == json['severity'],
    ),
    enabled: json['enabled'],
  );
}

/// Alert severity levels
enum AlertSeverity { low, medium, high, critical }

/// Vulnerability found during security scanning
class Vulnerability {
  final String id;
  final String title;
  final String description;
  final VulnerabilitySeverity severity;
  final String category;
  final String? cveId;
  final double? cvssScore;
  final DateTime discoveredAt;
  final String? remediation;

  Vulnerability({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    this.cveId,
    this.cvssScore,
    required this.discoveredAt,
    this.remediation,
  });
}

/// Vulnerability severity levels
enum VulnerabilitySeverity { low, medium, high, critical }

/// Security scan result
class SecurityScanResult {
  final String scanId;
  final DateTime timestamp;
  final List<Vulnerability> vulnerabilities;
  double securityScore;
  List<String> recommendations;

  SecurityScanResult({
    required this.scanId,
    required this.timestamp,
    required this.vulnerabilities,
    required this.securityScore,
    required this.recommendations,
  });
}

/// Penetration test result
class PenetrationTestResult {
  final String testId;
  final DateTime timestamp;
  final PenetrationTestType testType;
  Duration duration;
  List<PenetrationTestFinding> findings;
  RiskLevel overallRisk;

  PenetrationTestResult({
    required this.testId,
    required this.timestamp,
    required this.testType,
    required this.duration,
    required this.findings,
    required this.overallRisk,
  });
}

/// Types of penetration tests
enum PenetrationTestType { automated, manual, hybrid }

/// Finding from penetration test
class PenetrationTestFinding {
  final String id;
  final String title;
  final String description;
  final RiskLevel riskLevel;
  final String category;
  final String? exploitDetails;
  final String? remediation;

  PenetrationTestFinding({
    required this.id,
    required this.title,
    required this.description,
    required this.riskLevel,
    required this.category,
    this.exploitDetails,
    this.remediation,
  });
}

/// Security compliance report
class SecurityComplianceReport {
  final DateTime generatedAt;
  final Duration reportPeriod;
  final int totalAuditEvents;
  final int securityIncidents;
  final int vulnerabilitiesFound;
  final double averageSecurityScore;
  final String complianceStatus;
  final List<String> recommendations;

  SecurityComplianceReport({
    required this.generatedAt,
    required this.reportPeriod,
    required this.totalAuditEvents,
    required this.securityIncidents,
    required this.vulnerabilitiesFound,
    required this.averageSecurityScore,
    required this.complianceStatus,
    required this.recommendations,
  });
}

/// Security dashboard data
class SecurityDashboardData {
  final int totalEvents;
  final int criticalAlerts;
  final int activeThreats;
  final double securityScore;
  final Map<int, int> eventsByHour;
  final List<MapEntry<ThreatType, int>> topThreats;
  final List<SecurityAlert> recentAlerts;

  SecurityDashboardData({
    required this.totalEvents,
    required this.criticalAlerts,
    required this.activeThreats,
    required this.securityScore,
    required this.eventsByHour,
    required this.topThreats,
    required this.recentAlerts,
  });
}

/// Audit log export for compliance
class AuditLogExport {
  final String exportId;
  final DateTime exportedAt;
  final DateTime startDate;
  final DateTime endDate;
  final int totalEvents;
  final List<AuditEvent> events;
  final String format;
  final String checksum;

  AuditLogExport({
    required this.exportId,
    required this.exportedAt,
    required this.startDate,
    required this.endDate,
    required this.totalEvents,
    required this.events,
    required this.format,
    required this.checksum,
  });
}

/// Security alert for dashboard display
class SecurityAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isResolved;
  final String? source;

  SecurityAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    this.isResolved = false,
    this.source,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'severity': severity.name,
    'timestamp': timestamp.toIso8601String(),
    'isResolved': isResolved,
    'source': source,
  };

  factory SecurityAlert.fromJson(Map<String, dynamic> json) => SecurityAlert(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    severity: AlertSeverity.values.firstWhere(
      (e) => e.name == json['severity'],
    ),
    timestamp: DateTime.parse(json['timestamp']),
    isResolved: json['isResolved'] ?? false,
    source: json['source'],
  );
}

