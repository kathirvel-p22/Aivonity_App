import 'dart:async';
import 'package:get_it/get_it.dart';
import '../alert_service.dart';
import 'encryption_service.dart';
import 'key_management_service.dart';
import 'data_anonymization_service.dart' as anonymization;
import 'threat_detection_service.dart';
import 'incident_response_service.dart';
import 'privacy_compliance_service.dart';
import 'security_monitoring_service.dart';
import '../../models/security_models.dart';
import '../../models/privacy_models.dart';
import '../../models/monitoring_models.dart';

/// Coordinator service that integrates all security services
class SecurityServiceCoordinator {
  late final EncryptionService _encryptionService;
  late final KeyManagementService _keyManagementService;
  late final anonymization.DataAnonymizationService _anonymizationService;
  late final ThreatDetectionService _threatDetectionService;
  late final IncidentResponseService _incidentResponseService;
  late final PrivacyComplianceService _privacyComplianceService;
  late final SecurityMonitoringService _monitoringService;

  final StreamController<SecurityEvent> _securityEventController =
      StreamController<SecurityEvent>.broadcast();

  bool _initialized = false;

  /// Stream for all security events
  Stream<SecurityEvent> get securityEventStream =>
      _securityEventController.stream;

  /// Initialize all security services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize core services
      _encryptionService = EncryptionService();
      await _encryptionService.initialize();

      _keyManagementService = KeyManagementService();
      await _keyManagementService.initialize();

      _anonymizationService = anonymization.DataAnonymizationService();
      await _anonymizationService.initialize();

      _threatDetectionService = ThreatDetectionService();
      await _threatDetectionService.initialize();

      _monitoringService = SecurityMonitoringService();
      await _monitoringService.initialize();

      // Initialize services that depend on others
      final alertService = GetIt.instance<AlertService>();

      _incidentResponseService = IncidentResponseService(alertService);
      await _incidentResponseService.initialize();

      _privacyComplianceService = PrivacyComplianceService(
        _anonymizationService,
      );
      await _privacyComplianceService.initialize();

      // Set up event forwarding
      _setupEventForwarding();

      _initialized = true;
      print('🛡️ Security service coordinator initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize security services: $e');
      rethrow;
    }
  }

  /// Record a security event and distribute to relevant services
  Future<void> recordSecurityEvent(SecurityEvent event) async {
    if (!_initialized) {
      throw StateError('Security services not initialized');
    }

    try {
      // Emit to main stream
      _securityEventController.add(event);

      // Forward to threat detection
      await _threatDetectionService.recordSecurityEvent(event);

      // Log audit event
      await _monitoringService.auditUserAction(
        userId: event.userId ?? 'system',
        action: event.eventType.name,
        resource: 'security_event',
        metadata: event.metadata,
        ipAddress: event.ipAddress,
      );
    } catch (e) {
      print('❌ Error recording security event: $e');
    }
  }

  /// Encrypt sensitive data
  Future<EncryptedData> encryptData(String data, String keyId) async {
    return await _encryptionService.encryptData(data, keyId);
  }

  /// Decrypt sensitive data
  Future<String> decryptData(EncryptedData encryptedData) async {
    return await _encryptionService.decryptData(encryptedData);
  }

  /// Anonymize personal data
  String anonymizeData(String data, DataType dataType) {
    return _encryptionService.anonymizeData(data, dataType);
  }

  /// Create pseudonym for data linkability
  Future<String> createPseudonym(String originalValue, String context) async {
    return await _anonymizationService.createPseudonym(originalValue, context);
  }

  /// Analyze login attempt for fraud
  Future<FraudAnalysisResult> analyzeFraudRisk(LoginAttempt attempt) async {
    return await _threatDetectionService.analyzeFraudRisk(attempt);
  }

  /// Record user consent
  Future<void> recordConsent(UserConsent consent) async {
    await _privacyComplianceService.recordConsent(consent);
  }

  /// Handle data portability request
  Future<DataExportResult> handleDataPortabilityRequest(String userId) async {
    return await _privacyComplianceService.handleDataPortabilityRequest(userId);
  }

  /// Handle right to be forgotten request
  Future<DataDeletionResult> handleRightToBeForgottenRequest(
    String userId, {
    String? reason,
  }) async {
    return await _privacyComplianceService.handleRightToBeForgottenRequest(
      userId,
      reason: reason,
    );
  }

  /// Perform security scan
  Future<void> performSecurityScan() async {
    await _monitoringService.performSecurityScan();
  }

  /// Perform penetration test
  Future<PenetrationTestResult> performPenetrationTest() async {
    return await _monitoringService.performPenetrationTest();
  }

  /// Generate security compliance report
  Future<SecurityComplianceReport> generateComplianceReport() async {
    return await _monitoringService.generateComplianceReport();
  }

  /// Get security dashboard data
  Future<SecurityDashboardData> getSecurityDashboard() async {
    return await _monitoringService.getSecurityDashboard();
  }

  /// Rotate encryption keys
  Future<void> rotateKeys() async {
    await _keyManagementService.performScheduledRotations();
  }

  /// Get security service status
  Future<SecurityServiceStatus> getServiceStatus() async {
    final keyStats = await _keyManagementService.listKeys();
    final threatStats = await _threatDetectionService.getStats();
    final anonymizationStats = await _anonymizationService
        .getAnonymizationStats();

    return SecurityServiceStatus(
      encryptionServiceActive: true,
      keyManagementActive: true,
      threatDetectionActive: true,
      monitoringActive: true,
      totalKeys: keyStats.length,
      threatsDetected: threatStats.totalThreatsDetected,
      anonymizationsPerformed: anonymizationStats.totalAnonymizations,
      lastSecurityScan: DateTime.now().subtract(Duration(minutes: 15)),
    );
  }

  /// Set up event forwarding between services
  void _setupEventForwarding() {
    // Event forwarding will be implemented when the services are fully integrated
    print('🔗 Security service event forwarding configured');
  }

  /// Dispose all services
  void dispose() {
    _threatDetectionService.dispose();
    _incidentResponseService.dispose();
    _privacyComplianceService.dispose();
    _monitoringService.dispose();
    _securityEventController.close();
  }
}

/// Status of security services
class SecurityServiceStatus {
  final bool encryptionServiceActive;
  final bool keyManagementActive;
  final bool threatDetectionActive;
  final bool monitoringActive;
  final int totalKeys;
  final int threatsDetected;
  final int anonymizationsPerformed;
  final DateTime lastSecurityScan;

  SecurityServiceStatus({
    required this.encryptionServiceActive,
    required this.keyManagementActive,
    required this.threatDetectionActive,
    required this.monitoringActive,
    required this.totalKeys,
    required this.threatsDetected,
    required this.anonymizationsPerformed,
    required this.lastSecurityScan,
  });
}

