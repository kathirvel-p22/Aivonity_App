import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';
import '../../models/monitoring_models.dart';
import '../../models/security_models.dart' show RiskLevel, ThreatType;

/// Comprehensive security monitoring and auditing service
class SecurityMonitoringService {
  static const String _auditLogPrefix = 'audit_log_';
  static const String _securityMetricsPrefix = 'security_metrics_';
  static const String _alertRulesPrefix = 'alert_rules_';
  static const String _vulnerabilityPrefix = 'vulnerability_';

  SharedPreferences? _prefs;
  Timer? _monitoringTimer;
  Timer? _metricsTimer;

  final StreamController<AuditEvent> _auditController =
      StreamController<AuditEvent>.broadcast();
  final StreamController<SecurityAlert> _alertController =
      StreamController<SecurityAlert>.broadcast();
  final StreamController<SecurityMetrics> _metricsController =
      StreamController<SecurityMetrics>.broadcast();

  final List<AuditEvent> _recentAudits = [];
  final Map<String, AlertRule> _alertRules = {};
  final SecurityMetrics _currentMetrics = SecurityMetrics.empty();

  /// Streams for audit events, alerts, and metrics
  Stream<AuditEvent> get auditStream => _auditController.stream;
  Stream<SecurityAlert> get alertStream => _alertController.stream;
  Stream<SecurityMetrics> get metricsStream => _metricsController.stream;

  /// Initialize the security monitoring service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAlertRules();
    _setupDefaultAlertRules();
    _startMonitoring();

    AppLogger.info('👁️ Security monitoring service initialized');
  }

  /// Log an audit event
  Future<void> logAuditEvent(AuditEvent event) async {
    _recentAudits.add(event);

    // Maintain audit history size
    if (_recentAudits.length > 10000) {
      _recentAudits.removeAt(0);
    }

    // Persist audit log
    await _persistAuditEvent(event);

    // Emit audit event
    _auditController.add(event);

    // Check for alert conditions
    await _checkAlertConditions(event);

    // Update security metrics
    _updateSecurityMetrics(event);

    AppLogger.info(
      '📝 Audit event logged: ${event.action} by ${event.userId ?? 'system'}',
    );
  }

  /// Create comprehensive audit log for all user actions
  Future<void> auditUserAction({
    required String userId,
    required String action,
    required String resource,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
  }) async {
    final event = AuditEvent(
      id: _generateAuditId(),
      userId: userId,
      action: action,
      resource: resource,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      metadata: metadata,
      severity: _determineAuditSeverity(action),
      category: _determineAuditCategory(action),
    );

    await logAuditEvent(event);
  }

  /// Monitor system security in real-time
  Future<void> performSecurityScan() async {
    final scanResults = SecurityScanResult(
      scanId: _generateScanId(),
      timestamp: DateTime.now(),
      vulnerabilities: await _scanForVulnerabilities(),
      securityScore: 0.0,
      recommendations: [],
    );

    // Calculate security score
    scanResults.securityScore = _calculateSecurityScore(
      scanResults.vulnerabilities,
    );

    // Generate recommendations
    scanResults.recommendations = _generateSecurityRecommendations(
      scanResults.vulnerabilities,
    );

    // Log scan results
    await _logSecurityScan(scanResults);

    // Check for critical vulnerabilities
    final criticalVulns = scanResults.vulnerabilities
        .where((v) => v.severity == VulnerabilitySeverity.critical)
        .toList();

    if (criticalVulns.isNotEmpty) {
      await _alertCriticalVulnerabilities(criticalVulns);
    }

    AppLogger.info(
      '🔍 Security scan completed. Score: ${scanResults.securityScore.toStringAsFixed(2)}',
    );
  }

  /// Perform penetration testing simulation
  Future<PenetrationTestResult> performPenetrationTest() async {
    final testResult = PenetrationTestResult(
      testId: _generateTestId(),
      timestamp: DateTime.now(),
      testType: PenetrationTestType.automated,
      duration: Duration.zero,
      findings: [],
      overallRisk: RiskLevel.low,
    );

    final startTime = DateTime.now();

    // Simulate various penetration tests
    testResult.findings.addAll(await _testAuthenticationSecurity());
    testResult.findings.addAll(await _testDataEncryption());
    testResult.findings.addAll(await _testInputValidation());
    testResult.findings.addAll(await _testSessionManagement());
    testResult.findings.addAll(await _testAccessControls());

    testResult.duration = DateTime.now().difference(startTime);
    testResult.overallRisk = _calculateOverallRisk(testResult.findings);

    // Log penetration test results
    await _logPenetrationTest(testResult);

    AppLogger.info(
      '🎯 Penetration test completed. Risk level: ${testResult.overallRisk.name}',
    );
    return testResult;
  }

  /// Generate security compliance report
  Future<SecurityComplianceReport> generateComplianceReport() async {
    final auditEvents = await _getRecentAuditEvents(Duration(days: 30));
    final securityScans = await _getRecentSecurityScans(Duration(days: 30));
    final penetrationTests = await _getRecentPenetrationTests(
      Duration(days: 90),
    );

    final report = SecurityComplianceReport(
      generatedAt: DateTime.now(),
      reportPeriod: Duration(days: 30),
      totalAuditEvents: auditEvents.length,
      securityIncidents: auditEvents
          .where((e) => e.severity == AuditSeverity.high)
          .length,
      vulnerabilitiesFound: securityScans.fold<int>(
        0,
        (sum, scan) => sum + scan.vulnerabilities.length,
      ),
      averageSecurityScore: _calculateAverageSecurityScore(securityScans),
      complianceStatus: _assessComplianceStatus(auditEvents, securityScans),
      recommendations: _generateComplianceRecommendations(
        auditEvents,
        securityScans,
      ),
    );

    return report;
  }

  /// Get security metrics dashboard data
  Future<SecurityDashboardData> getSecurityDashboard() async {
    final recentEvents = _recentAudits
        .where(
          (e) => DateTime.now().difference(e.timestamp) <= Duration(hours: 24),
        )
        .toList();

    final threatsByType = <ThreatType, int>{};
    final eventsByHour = <int, int>{};

    // Analyze recent events
    for (final event in recentEvents) {
      final hour = event.timestamp.hour;
      eventsByHour[hour] = (eventsByHour[hour] ?? 0) + 1;
    }

    return SecurityDashboardData(
      totalEvents: recentEvents.length,
      criticalAlerts: recentEvents
          .where((e) => e.severity == AuditSeverity.critical)
          .length,
      activeThreats: threatsByType.length,
      securityScore: _currentMetrics.overallSecurityScore,
      eventsByHour: eventsByHour,
      topThreats: threatsByType.entries.take(5).toList(),
      recentAlerts: _getRecentAlerts(10),
    );
  }

  /// Set up alert rule for specific conditions
  Future<void> createAlertRule(AlertRule rule) async {
    _alertRules[rule.id] = rule;

    final ruleKey = '$_alertRulesPrefix${rule.id}';
    await _prefs?.setString(ruleKey, jsonEncode(rule.toJson()));

    AppLogger.info('🚨 Created alert rule: ${rule.name}');
  }

  /// Export audit logs for compliance
  Future<AuditLogExport> exportAuditLogs({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? userIds,
    List<String>? actions,
  }) async {
    final filteredEvents = _recentAudits.where((event) {
      if (event.timestamp.isBefore(startDate) ||
          event.timestamp.isAfter(endDate)) {
        return false;
      }

      if (userIds != null && !userIds.contains(event.userId)) {
        return false;
      }

      if (actions != null && !actions.contains(event.action)) {
        return false;
      }

      return true;
    }).toList();

    return AuditLogExport(
      exportId: _generateExportId(),
      exportedAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      totalEvents: filteredEvents.length,
      events: filteredEvents,
      format: 'JSON',
      checksum: _calculateChecksum(filteredEvents),
    );
  }

  // Private helper methods

  Future<void> _persistAuditEvent(AuditEvent event) async {
    final auditKey = '$_auditLogPrefix${event.id}';
    await _prefs?.setString(auditKey, jsonEncode(event.toJson()));
  }

  Future<void> _checkAlertConditions(AuditEvent event) async {
    for (final rule in _alertRules.values) {
      if (await _evaluateAlertRule(rule, event)) {
        final alert = SecurityAlert(
          id: _generateAlertId(),
          title: 'Alert Rule Triggered',
          description: 'Alert rule triggered: ${rule.name}',
          severity: AlertSeverity.high,
          timestamp: DateTime.now(),
          source: 'audit_system',
        );

        _alertController.add(alert);
      }
    }
  }

  void _updateSecurityMetrics(AuditEvent event) {
    _currentMetrics.totalEvents++;

    switch (event.severity) {
      case AuditSeverity.critical:
        _currentMetrics.criticalEvents++;
        break;
      case AuditSeverity.high:
        _currentMetrics.highSeverityEvents++;
        break;
      case AuditSeverity.medium:
        _currentMetrics.mediumSeverityEvents++;
        break;
      case AuditSeverity.low:
        _currentMetrics.lowSeverityEvents++;
        break;
    }

    // Recalculate security score
    _currentMetrics.overallSecurityScore = _calculateCurrentSecurityScore();
  }

  Future<List<Vulnerability>> _scanForVulnerabilities() async {
    final vulnerabilities = <Vulnerability>[];

    // Simulate vulnerability scanning
    vulnerabilities.addAll(await _checkWeakPasswords());
    vulnerabilities.addAll(await _checkOutdatedDependencies());
    vulnerabilities.addAll(await _checkInsecureConfigurations());
    vulnerabilities.addAll(await _checkUnencryptedData());

    return vulnerabilities;
  }

  double _calculateSecurityScore(List<Vulnerability> vulnerabilities) {
    if (vulnerabilities.isEmpty) return 100.0;

    double score = 100.0;

    for (final vuln in vulnerabilities) {
      switch (vuln.severity) {
        case VulnerabilitySeverity.critical:
          score -= 20.0;
          break;
        case VulnerabilitySeverity.high:
          score -= 10.0;
          break;
        case VulnerabilitySeverity.medium:
          score -= 5.0;
          break;
        case VulnerabilitySeverity.low:
          score -= 1.0;
          break;
      }
    }

    return max(0.0, score);
  }

  List<String> _generateSecurityRecommendations(
    List<Vulnerability> vulnerabilities,
  ) {
    final recommendations = <String>[];

    final criticalCount = vulnerabilities
        .where((v) => v.severity == VulnerabilitySeverity.critical)
        .length;
    final highCount = vulnerabilities
        .where((v) => v.severity == VulnerabilitySeverity.high)
        .length;

    if (criticalCount > 0) {
      recommendations.add(
        'Immediately address $criticalCount critical vulnerabilities',
      );
    }

    if (highCount > 0) {
      recommendations.add(
        'Prioritize fixing $highCount high-severity vulnerabilities',
      );
    }

    if (vulnerabilities.any((v) => v.category == 'authentication')) {
      recommendations.add('Strengthen authentication mechanisms');
    }

    if (vulnerabilities.any((v) => v.category == 'encryption')) {
      recommendations.add('Review and update encryption implementations');
    }

    return recommendations;
  }

  void _startMonitoring() {
    // Start periodic security monitoring
    _monitoringTimer = Timer.periodic(Duration(minutes: 15), (_) async {
      await performSecurityScan();
    });

    // Start metrics collection
    _metricsTimer = Timer.periodic(Duration(minutes: 5), (_) async {
      _metricsController.add(_currentMetrics);
    });
  }

  void _setupDefaultAlertRules() {
    _alertRules['failed_logins'] = AlertRule(
      id: 'failed_logins',
      name: 'Multiple Failed Logins',
      description: 'Alert when user has multiple failed login attempts',
      condition: 'failed_login_count > 5',
      severity: AlertSeverity.high,
      enabled: true,
    );

    _alertRules['privilege_escalation'] = AlertRule(
      id: 'privilege_escalation',
      name: 'Privilege Escalation Attempt',
      description: 'Alert when user attempts to access unauthorized resources',
      condition: 'action = "privilege_escalation"',
      severity: AlertSeverity.critical,
      enabled: true,
    );
  }

  Future<void> _loadAlertRules() async {
    final allKeys = _prefs?.getKeys() ?? <String>{};

    for (final key in allKeys) {
      if (key.startsWith(_alertRulesPrefix)) {
        final ruleId = key.substring(_alertRulesPrefix.length);
        final ruleJson = _prefs?.getString(key);

        if (ruleJson != null) {
          try {
            final rule = AlertRule.fromJson(jsonDecode(ruleJson));
            _alertRules[ruleId] = rule;
          } catch (e) {
            AppLogger.error('❌ Failed to load alert rule $ruleId', e);
          }
        }
      }
    }
  }

  String _generateAuditId() =>
      'audit_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  String _generateScanId() => 'scan_${DateTime.now().millisecondsSinceEpoch}';
  String _generateTestId() => 'test_${DateTime.now().millisecondsSinceEpoch}';
  String _generateExportId() =>
      'export_${DateTime.now().millisecondsSinceEpoch}';
  String _generateAlertId() =>
      'alert_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

  AuditSeverity _determineAuditSeverity(String action) {
    if (action.contains('delete') || action.contains('admin')) {
      return AuditSeverity.high;
    }
    if (action.contains('update') || action.contains('create')) {
      return AuditSeverity.medium;
    }
    return AuditSeverity.low;
  }

  String _determineAuditCategory(String action) {
    if (action.contains('login') || action.contains('auth')) {
      return 'authentication';
    }
    if (action.contains('data') || action.contains('export')) {
      return 'data_access';
    }
    if (action.contains('admin') || action.contains('config')) {
      return 'administration';
    }
    return 'general';
  }

  double _calculateCurrentSecurityScore() {
    final total = _currentMetrics.totalEvents;
    if (total == 0) return 100.0;

    final criticalWeight = _currentMetrics.criticalEvents * 4;
    final highWeight = _currentMetrics.highSeverityEvents * 2;
    final mediumWeight = _currentMetrics.mediumSeverityEvents * 1;

    final riskScore = (criticalWeight + highWeight + mediumWeight) / total;
    return max(0.0, 100.0 - (riskScore * 10));
  }

  // Placeholder methods for vulnerability scanning and penetration testing
  Future<List<Vulnerability>> _checkWeakPasswords() async => [];
  Future<List<Vulnerability>> _checkOutdatedDependencies() async => [];
  Future<List<Vulnerability>> _checkInsecureConfigurations() async => [];
  Future<List<Vulnerability>> _checkUnencryptedData() async => [];

  Future<List<PenetrationTestFinding>> _testAuthenticationSecurity() async =>
      [];
  Future<List<PenetrationTestFinding>> _testDataEncryption() async => [];
  Future<List<PenetrationTestFinding>> _testInputValidation() async => [];
  Future<List<PenetrationTestFinding>> _testSessionManagement() async => [];
  Future<List<PenetrationTestFinding>> _testAccessControls() async => [];

  RiskLevel _calculateOverallRisk(List<PenetrationTestFinding> findings) =>
      RiskLevel.low;

  Future<bool> _evaluateAlertRule(AlertRule rule, AuditEvent event) async =>
      false;
  Future<void> _alertCriticalVulnerabilities(
    List<Vulnerability> vulnerabilities,
  ) async {}
  Future<void> _logSecurityScan(SecurityScanResult result) async {}
  Future<void> _logPenetrationTest(PenetrationTestResult result) async {}

  Future<List<AuditEvent>> _getRecentAuditEvents(Duration period) async => [];
  Future<List<SecurityScanResult>> _getRecentSecurityScans(
    Duration period,
  ) async => [];
  Future<List<PenetrationTestResult>> _getRecentPenetrationTests(
    Duration period,
  ) async => [];

  double _calculateAverageSecurityScore(List<SecurityScanResult> scans) => 85.0;
  String _assessComplianceStatus(
    List<AuditEvent> events,
    List<SecurityScanResult> scans,
  ) => 'Compliant';
  List<String> _generateComplianceRecommendations(
    List<AuditEvent> events,
    List<SecurityScanResult> scans,
  ) => [];
  List<SecurityAlert> _getRecentAlerts(int count) => [];
  String _calculateChecksum(List<AuditEvent> events) => 'checksum';

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _metricsTimer?.cancel();
    _auditController.close();
    _alertController.close();
    _metricsController.close();
  }
}
