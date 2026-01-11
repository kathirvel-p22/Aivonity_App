import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_anonymization_service.dart';
import '../../models/privacy_models.dart';

/// GDPR-compliant privacy controls and data management service
class PrivacyComplianceService {
  static const String _consentPrefix = 'consent_';
  static const String _privacySettingsPrefix = 'privacy_settings_';
  static const String _dataRequestPrefix = 'data_request_';
  static const String _retentionPolicyPrefix = 'retention_policy_';

  final DataAnonymizationService _anonymizationService;
  SharedPreferences? _prefs;

  final StreamController<DataRequest> _dataRequestController =
      StreamController<DataRequest>.broadcast();
  final StreamController<ConsentUpdate> _consentController =
      StreamController<ConsentUpdate>.broadcast();

  /// Streams for data requests and consent updates
  Stream<DataRequest> get dataRequestStream => _dataRequestController.stream;
  Stream<ConsentUpdate> get consentStream => _consentController.stream;

  PrivacyComplianceService(this._anonymizationService);

  /// Initialize the privacy compliance service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _anonymizationService.initialize();
    print('🔒 Privacy compliance service initialized');
  }

  /// Record user consent for data processing
  Future<void> recordConsent(UserConsent consent) async {
    final consentKey = '$_consentPrefix${consent.userId}';
    await _prefs?.setString(consentKey, jsonEncode(consent.toJson()));

    _consentController.add(
      ConsentUpdate(
        userId: consent.userId,
        consentType: consent.consentType,
        granted: consent.granted,
        timestamp: consent.timestamp,
      ),
    );

    print(
      '✅ Recorded consent for user ${consent.userId}: ${consent.consentType.name} = ${consent.granted}',
    );
  }

  /// Get user consent status
  Future<UserConsent?> getUserConsent(
    String userId,
    ConsentType consentType,
  ) async {
    final consentKey = '$_consentPrefix$userId';
    final consentJson = _prefs?.getString(consentKey);

    if (consentJson != null) {
      try {
        final consent = UserConsent.fromJson(jsonDecode(consentJson));
        return consent.consentType == consentType ? consent : null;
      } catch (e) {
        print('❌ Failed to parse consent for user $userId: $e');
      }
    }

    return null;
  }

  /// Update privacy settings for a user
  Future<void> updatePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) async {
    final settingsKey = '$_privacySettingsPrefix$userId';
    await _prefs?.setString(settingsKey, jsonEncode(settings.toJson()));

    print('🔧 Updated privacy settings for user $userId');
  }

  /// Get user privacy settings
  Future<PrivacySettings> getPrivacySettings(String userId) async {
    final settingsKey = '$_privacySettingsPrefix$userId';
    final settingsJson = _prefs?.getString(settingsKey);

    if (settingsJson != null) {
      try {
        return PrivacySettings.fromJson(jsonDecode(settingsJson));
      } catch (e) {
        print('❌ Failed to parse privacy settings for user $userId: $e');
      }
    }

    // Return default privacy settings
    return PrivacySettings.defaultSettings(userId);
  }

  /// Handle data portability request (GDPR Article 20)
  Future<DataExportResult> handleDataPortabilityRequest(String userId) async {
    final request = DataRequest(
      id: _generateRequestId(),
      userId: userId,
      requestType: DataRequestType.portability,
      status: DataRequestStatus.processing,
      createdAt: DateTime.now(),
      completedAt: null,
    );

    await _logDataRequest(request);
    _dataRequestController.add(request);

    try {
      // Collect all user data
      final userData = await _collectUserData(userId);

      // Apply privacy settings
      final privacySettings = await getPrivacySettings(userId);
      final filteredData = _applyPrivacyFilters(userData, privacySettings);

      // Create export package
      final exportData = DataExportPackage(
        userId: userId,
        exportedAt: DateTime.now(),
        dataCategories: filteredData.keys.toList(),
        data: filteredData,
        format: 'JSON',
        size: _calculateDataSize(filteredData),
      );

      // Update request status
      request.status = DataRequestStatus.completed;
      request.completedAt = DateTime.now();
      await _logDataRequest(request);

      return DataExportResult(
        success: true,
        exportPackage: exportData,
        message: 'Data export completed successfully',
      );
    } catch (e) {
      request.status = DataRequestStatus.failed;
      await _logDataRequest(request);

      return DataExportResult(
        success: false,
        message: 'Data export failed: $e',
      );
    }
  }

  /// Handle right to be forgotten request (GDPR Article 17)
  Future<DataDeletionResult> handleRightToBeForgottenRequest(
    String userId, {
    String? reason,
  }) async {
    final request = DataRequest(
      id: _generateRequestId(),
      userId: userId,
      requestType: DataRequestType.deletion,
      status: DataRequestStatus.processing,
      createdAt: DateTime.now(),
      completedAt: null,
    );

    await _logDataRequest(request);
    _dataRequestController.add(request);

    try {
      // Check if deletion is legally required or if there are retention obligations
      final retentionCheck = await _checkRetentionObligations(userId);

      if (retentionCheck.hasLegalObligations) {
        request.status = DataRequestStatus.rejected;
        request.completedAt = DateTime.now();
        await _logDataRequest(request);

        return DataDeletionResult(
          success: false,
          message:
              'Data deletion rejected due to legal retention obligations: ${retentionCheck.reason}',
          retentionInfo: retentionCheck,
        );
      }

      // Perform data deletion
      final deletionSummary = await _performDataDeletion(userId);

      // Update request status
      request.status = DataRequestStatus.completed;
      request.completedAt = DateTime.now();
      await _logDataRequest(request);

      return DataDeletionResult(
        success: true,
        message: 'Data deletion completed successfully',
        deletionSummary: deletionSummary,
      );
    } catch (e) {
      request.status = DataRequestStatus.failed;
      await _logDataRequest(request);

      return DataDeletionResult(
        success: false,
        message: 'Data deletion failed: $e',
      );
    }
  }

  /// Handle data rectification request (GDPR Article 16)
  Future<DataRectificationResult> handleDataRectificationRequest(
    String userId,
    Map<String, dynamic> corrections,
  ) async {
    final request = DataRequest(
      id: _generateRequestId(),
      userId: userId,
      requestType: DataRequestType.rectification,
      status: DataRequestStatus.processing,
      createdAt: DateTime.now(),
      completedAt: null,
    );

    await _logDataRequest(request);
    _dataRequestController.add(request);

    try {
      final correctionResults = <String, bool>{};

      for (final entry in corrections.entries) {
        final field = entry.key;
        final newValue = entry.value;

        // Validate the correction
        if (await _validateDataCorrection(userId, field, newValue)) {
          await _updateUserData(userId, field, newValue);
          correctionResults[field] = true;
        } else {
          correctionResults[field] = false;
        }
      }

      request.status = DataRequestStatus.completed;
      request.completedAt = DateTime.now();
      await _logDataRequest(request);

      return DataRectificationResult(
        success: true,
        correctionResults: correctionResults,
        message: 'Data rectification completed',
      );
    } catch (e) {
      request.status = DataRequestStatus.failed;
      await _logDataRequest(request);

      return DataRectificationResult(
        success: false,
        message: 'Data rectification failed: $e',
      );
    }
  }

  /// Set data retention policy for a data category
  Future<void> setRetentionPolicy(
    String dataCategory,
    RetentionPolicy policy,
  ) async {
    final policyKey = '$_retentionPolicyPrefix$dataCategory';
    await _prefs?.setString(policyKey, jsonEncode(policy.toJson()));

    print(
      '📅 Set retention policy for $dataCategory: ${policy.retentionPeriod.inDays} days',
    );
  }

  /// Get data retention policy for a category
  Future<RetentionPolicy?> getRetentionPolicy(String dataCategory) async {
    final policyKey = '$_retentionPolicyPrefix$dataCategory';
    final policyJson = _prefs?.getString(policyKey);

    if (policyJson != null) {
      try {
        return RetentionPolicy.fromJson(jsonDecode(policyJson));
      } catch (e) {
        print('❌ Failed to parse retention policy for $dataCategory: $e');
      }
    }

    return null;
  }

  /// Check if user has given consent for specific data processing
  Future<bool> hasValidConsent(String userId, ConsentType consentType) async {
    final consent = await getUserConsent(userId, consentType);

    if (consent == null || !consent.granted) {
      return false;
    }

    // Check if consent has expired
    if (consent.expiresAt != null &&
        DateTime.now().isAfter(consent.expiresAt!)) {
      return false;
    }

    return true;
  }

  /// Generate privacy compliance report
  Future<ComplianceReport> generateComplianceReport() async {
    final allKeys = _prefs?.getKeys() ?? <String>{};

    final consentCount = allKeys
        .where((key) => key.startsWith(_consentPrefix))
        .length;
    final dataRequestCount = allKeys
        .where((key) => key.startsWith(_dataRequestPrefix))
        .length;
    final retentionPolicyCount = allKeys
        .where((key) => key.startsWith(_retentionPolicyPrefix))
        .length;

    // Get recent data requests
    final recentRequests = await _getRecentDataRequests();

    return ComplianceReport(
      generatedAt: DateTime.now(),
      totalConsents: consentCount,
      totalDataRequests: dataRequestCount,
      totalRetentionPolicies: retentionPolicyCount,
      recentRequests: recentRequests,
      complianceStatus: _assessComplianceStatus(
        consentCount,
        retentionPolicyCount,
      ),
    );
  }

  // Private helper methods

  Future<Map<String, dynamic>> _collectUserData(String userId) async {
    // In a real implementation, this would collect data from various sources
    return {
      'profile': {'userId': userId, 'name': 'User Name'},
      'preferences': {'theme': 'dark', 'notifications': true},
      'activity': {'lastLogin': DateTime.now().toIso8601String()},
      'telemetry': {
        'sessions': 10,
        'features_used': ['dashboard', 'reports'],
      },
    };
  }

  Map<String, dynamic> _applyPrivacyFilters(
    Map<String, dynamic> data,
    PrivacySettings settings,
  ) {
    final filtered = <String, dynamic>{};

    for (final entry in data.entries) {
      final category = entry.key;
      final categoryData = entry.value;

      if (settings.dataCategories[category]?.includeInExport ?? true) {
        if (settings.dataCategories[category]?.anonymize ?? false) {
          filtered[category] = _anonymizationService
              .anonymizePersonalData(Map<String, dynamic>.from(categoryData))
              .anonymizedData;
        } else {
          filtered[category] = categoryData;
        }
      }
    }

    return filtered;
  }

  Future<RetentionCheck> _checkRetentionObligations(String userId) async {
    // Check for legal retention requirements
    // This is a simplified implementation
    return RetentionCheck(
      hasLegalObligations: false,
      reason: null,
      retentionUntil: null,
    );
  }

  Future<DataDeletionSummary> _performDataDeletion(String userId) async {
    final deletedCategories = <String>[];
    final errors = <String>[];

    try {
      // Delete user preferences
      await _prefs?.remove('$_privacySettingsPrefix$userId');
      await _prefs?.remove('$_consentPrefix$userId');
      deletedCategories.addAll(['preferences', 'consent']);

      // In a real implementation, this would delete from databases, files, etc.
    } catch (e) {
      errors.add('Failed to delete some data: $e');
    }

    return DataDeletionSummary(
      deletedCategories: deletedCategories,
      deletedRecords: deletedCategories.length,
      errors: errors,
      completedAt: DateTime.now(),
    );
  }

  Future<bool> _validateDataCorrection(
    String userId,
    String field,
    dynamic newValue,
  ) async {
    // Implement validation logic for data corrections
    return true;
  }

  Future<void> _updateUserData(
    String userId,
    String field,
    dynamic newValue,
  ) async {
    // Implement data update logic
    print('📝 Updated $field for user $userId');
  }

  Future<void> _logDataRequest(DataRequest request) async {
    final requestKey = '$_dataRequestPrefix${request.id}';
    await _prefs?.setString(requestKey, jsonEncode(request.toJson()));
  }

  Future<List<DataRequest>> _getRecentDataRequests() async {
    final allKeys = _prefs?.getKeys() ?? <String>{};
    final requests = <DataRequest>[];

    for (final key in allKeys) {
      if (key.startsWith(_dataRequestPrefix)) {
        final requestJson = _prefs?.getString(key);
        if (requestJson != null) {
          try {
            final request = DataRequest.fromJson(jsonDecode(requestJson));
            if (DateTime.now().difference(request.createdAt).inDays <= 30) {
              requests.add(request);
            }
          } catch (e) {
            print('❌ Failed to parse data request: $e');
          }
        }
      }
    }

    return requests;
  }

  String _generateRequestId() {
    return 'REQ_${DateTime.now().millisecondsSinceEpoch}';
  }

  int _calculateDataSize(Map<String, dynamic> data) {
    return jsonEncode(data).length;
  }

  ComplianceStatus _assessComplianceStatus(
    int consentCount,
    int retentionPolicyCount,
  ) {
    if (consentCount > 0 && retentionPolicyCount > 0) {
      return ComplianceStatus.compliant;
    } else if (consentCount > 0 || retentionPolicyCount > 0) {
      return ComplianceStatus.partiallyCompliant;
    } else {
      return ComplianceStatus.nonCompliant;
    }
  }

  /// Dispose resources
  void dispose() {
    _dataRequestController.close();
    _consentController.close();
  }
}

