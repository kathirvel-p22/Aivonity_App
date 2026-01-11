import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../alert_service.dart';
import '../../models/security_models.dart';

/// Automated security incident response service
class IncidentResponseService {
  static const String _incidentPrefix = 'incident_';
  static const String _quarantinePrefix = 'quarantine_';

  final AlertService _alertService;
  SharedPreferences? _prefs;

  final StreamController<SecurityIncident> _incidentController =
      StreamController<SecurityIncident>.broadcast();
  final List<SecurityIncident> _activeIncidents = [];

  /// Stream for incidents
  Stream<SecurityIncident> get incidentStream => _incidentController.stream;

  IncidentResponseService(this._alertService);

  /// Initialize the incident response service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('🚨 Incident response service initialized');
  }

  /// Handle a security threat alert
  Future<void> handleThreatAlert(ThreatAlert alert) async {
    final incident = SecurityIncident(
      id: _generateIncidentId(),
      threatAlert: alert,
      severity: _mapThreatSeverityToIncidentSeverity(alert.severity),
      status: IncidentStatus.open,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      responseActions: [],
      affectedUsers: alert.userId != null ? [alert.userId!] : [],
    );

    _activeIncidents.add(incident);
    _incidentController.add(incident);

    // Execute automated response
    await _executeAutomatedResponse(incident);
    await _logIncident(incident);
  }

  /// Execute automated response based on incident severity
  Future<void> _executeAutomatedResponse(SecurityIncident incident) async {
    switch (incident.severity) {
      case IncidentSeverity.critical:
        await _handleCriticalIncident(incident);
        break;
      case IncidentSeverity.high:
        await _handleHighSeverityIncident(incident);
        break;
      case IncidentSeverity.medium:
        await _handleMediumSeverityIncident(incident);
        break;
      case IncidentSeverity.low:
        await _handleLowSeverityIncident(incident);
        break;
    }

    incident.lastUpdated = DateTime.now();
  }

  /// Handle critical security incidents
  Future<void> _handleCriticalIncident(SecurityIncident incident) async {
    for (final userId in incident.affectedUsers) {
      await _blockUser(userId, Duration(hours: 24));
      await _revokeUserTokens(userId);
    }

    await _escalateToAdmin(incident);
    await _sendSecurityAlert(
      incident,
      'Critical security threat detected and user blocked',
    );
  }

  /// Handle high severity incidents
  Future<void> _handleHighSeverityIncident(SecurityIncident incident) async {
    for (final userId in incident.affectedUsers) {
      await _requireMFA(userId);
      await _quarantineSession(userId);
    }

    await _sendSecurityAlert(
      incident,
      'High severity security incident detected',
    );
  }

  /// Handle medium severity incidents
  Future<void> _handleMediumSeverityIncident(SecurityIncident incident) async {
    for (final userId in incident.affectedUsers) {
      await _requireMFA(userId);
    }

    await _logSecurityEvent(
      incident,
      'Medium severity security incident logged',
    );
  }

  /// Handle low severity incidents
  Future<void> _handleLowSeverityIncident(SecurityIncident incident) async {
    await _logSecurityEvent(incident, 'Low severity security incident logged');
  }

  /// Block a user temporarily
  Future<void> _blockUser(String userId, Duration duration) async {
    final blockUntil = DateTime.now().add(duration);
    await _prefs?.setString(
      'blocked_user_$userId',
      blockUntil.toIso8601String(),
    );
    print('🚫 Blocked user $userId until $blockUntil');
  }

  /// Require multi-factor authentication for user
  Future<void> _requireMFA(String userId) async {
    await _prefs?.setBool('require_mfa_$userId', true);
    print('🔐 MFA required for user $userId');
  }

  /// Quarantine user session
  Future<void> _quarantineSession(String userId) async {
    final quarantineId = _generateQuarantineId();
    final quarantine = SessionQuarantine(
      id: quarantineId,
      userId: userId,
      quarantinedAt: DateTime.now(),
      reason: 'Automated security response',
      restrictions: [
        'No data export',
        'Limited feature access',
        'Enhanced monitoring',
      ],
    );

    await _prefs?.setString(
      '$_quarantinePrefix$quarantineId',
      jsonEncode(quarantine.toJson()),
    );
    print('🔒 Quarantined session for user $userId');
  }

  /// Send security alert to administrators
  Future<void> _sendSecurityAlert(
    SecurityIncident incident,
    String message,
  ) async {
    final alert = EnhancedAlert(
      id: 'alert_${incident.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Security Incident Alert',
      message: message,
      severity: AlertSeverity.high,
      category: AlertCategory.security,
      timestamp: DateTime.now(),
      data: {
        'incident_id': incident.id,
        'severity': incident.severity.name,
      },
    );
    _alertService.processAlert(alert);
  }

  /// Log security event
  Future<void> _logSecurityEvent(
    SecurityIncident incident,
    String message,
  ) async {
    final logEntry = {
      'incident_id': incident.id,
      'timestamp': DateTime.now().toIso8601String(),
      'message': message,
      'severity': incident.severity.name,
    };

    final logKey = 'security_log_${DateTime.now().millisecondsSinceEpoch}';
    await _prefs?.setString(logKey, jsonEncode(logEntry));
  }

  /// Escalate incident to administrators
  Future<void> _escalateToAdmin(SecurityIncident incident) async {
    await _sendSecurityAlert(
      incident,
      'High-severity security incident requires immediate attention. Incident ID: ${incident.id}',
    );

    incident.status = IncidentStatus.escalated;
    print('⬆️ Escalated incident ${incident.id} to administrators');
  }

  /// Revoke all user tokens
  Future<void> _revokeUserTokens(String userId) async {
    await _prefs?.setBool('tokens_revoked_$userId', true);
    print('🔑 Revoked all tokens for user $userId');
  }

  /// Log incident to persistent storage
  Future<void> _logIncident(SecurityIncident incident) async {
    final incidentKey = '$_incidentPrefix${incident.id}';
    await _prefs?.setString(incidentKey, jsonEncode(incident.toJson()));
  }

  /// Generate unique incident ID
  String _generateIncidentId() {
    return 'INC_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Generate unique quarantine ID
  String _generateQuarantineId() {
    return 'QUA_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Map threat severity to incident severity
  IncidentSeverity _mapThreatSeverityToIncidentSeverity(
    ThreatSeverity severity,
  ) {
    switch (severity) {
      case ThreatSeverity.low:
        return IncidentSeverity.low;
      case ThreatSeverity.medium:
        return IncidentSeverity.medium;
      case ThreatSeverity.high:
        return IncidentSeverity.high;
      case ThreatSeverity.critical:
        return IncidentSeverity.critical;
    }
  }

  /// Dispose resources
  void dispose() {
    _incidentController.close();
  }
}

