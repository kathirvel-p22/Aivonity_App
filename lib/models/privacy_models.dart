/// Privacy and GDPR compliance related data models
library;

/// User consent for data processing
class UserConsent {
  final String userId;
  final ConsentType consentType;
  final bool granted;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final String? purpose;
  final String? legalBasis;

  UserConsent({
    required this.userId,
    required this.consentType,
    required this.granted,
    required this.timestamp,
    this.expiresAt,
    this.purpose,
    this.legalBasis,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'consentType': consentType.name,
    'granted': granted,
    'timestamp': timestamp.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'purpose': purpose,
    'legalBasis': legalBasis,
  };

  factory UserConsent.fromJson(Map<String, dynamic> json) => UserConsent(
    userId: json['userId'],
    consentType: ConsentType.values.firstWhere(
      (e) => e.name == json['consentType'],
    ),
    granted: json['granted'],
    timestamp: DateTime.parse(json['timestamp']),
    expiresAt: json['expiresAt'] != null
        ? DateTime.parse(json['expiresAt'])
        : null,
    purpose: json['purpose'],
    legalBasis: json['legalBasis'],
  );
}

/// Types of consent
enum ConsentType {
  dataProcessing,
  marketing,
  analytics,
  cookies,
  locationTracking,
  dataSharing,
  profiling,
}

/// Privacy settings for a user
class PrivacySettings {
  final String userId;
  final DateTime lastUpdated;
  final Map<String, DataCategorySettings> dataCategories;
  final bool allowDataSharing;
  final bool allowProfiling;
  final bool allowMarketing;
  final DataRetentionPreference retentionPreference;

  PrivacySettings({
    required this.userId,
    required this.lastUpdated,
    required this.dataCategories,
    required this.allowDataSharing,
    required this.allowProfiling,
    required this.allowMarketing,
    required this.retentionPreference,
  });

  factory PrivacySettings.defaultSettings(String userId) => PrivacySettings(
    userId: userId,
    lastUpdated: DateTime.now(),
    dataCategories: {
      'profile': DataCategorySettings(includeInExport: true, anonymize: false),
      'preferences': DataCategorySettings(
        includeInExport: true,
        anonymize: false,
      ),
      'activity': DataCategorySettings(includeInExport: true, anonymize: true),
      'telemetry': DataCategorySettings(
        includeInExport: false,
        anonymize: true,
      ),
    },
    allowDataSharing: false,
    allowProfiling: false,
    allowMarketing: false,
    retentionPreference: DataRetentionPreference.minimal,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'lastUpdated': lastUpdated.toIso8601String(),
    'dataCategories': dataCategories.map((k, v) => MapEntry(k, v.toJson())),
    'allowDataSharing': allowDataSharing,
    'allowProfiling': allowProfiling,
    'allowMarketing': allowMarketing,
    'retentionPreference': retentionPreference.name,
  };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      PrivacySettings(
        userId: json['userId'],
        lastUpdated: DateTime.parse(json['lastUpdated']),
        dataCategories: (json['dataCategories'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, DataCategorySettings.fromJson(v)),
        ),
        allowDataSharing: json['allowDataSharing'],
        allowProfiling: json['allowProfiling'],
        allowMarketing: json['allowMarketing'],
        retentionPreference: DataRetentionPreference.values.firstWhere(
          (e) => e.name == json['retentionPreference'],
        ),
      );
}

/// Settings for a specific data category
class DataCategorySettings {
  final bool includeInExport;
  final bool anonymize;

  DataCategorySettings({
    required this.includeInExport,
    required this.anonymize,
  });

  Map<String, dynamic> toJson() => {
    'includeInExport': includeInExport,
    'anonymize': anonymize,
  };

  factory DataCategorySettings.fromJson(Map<String, dynamic> json) =>
      DataCategorySettings(
        includeInExport: json['includeInExport'],
        anonymize: json['anonymize'],
      );
}

/// Data retention preferences
enum DataRetentionPreference { minimal, standard, extended }

/// Data request for GDPR compliance
class DataRequest {
  final String id;
  final String userId;
  final DataRequestType requestType;
  DataRequestStatus status;
  final DateTime createdAt;
  DateTime? completedAt;

  DataRequest({
    required this.id,
    required this.userId,
    required this.requestType,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'requestType': requestType.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory DataRequest.fromJson(Map<String, dynamic> json) => DataRequest(
    id: json['id'],
    userId: json['userId'],
    requestType: DataRequestType.values.firstWhere(
      (e) => e.name == json['requestType'],
    ),
    status: DataRequestStatus.values.firstWhere(
      (e) => e.name == json['status'],
    ),
    createdAt: DateTime.parse(json['createdAt']),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
  );
}

/// Types of data requests
enum DataRequestType {
  portability,
  deletion,
  rectification,
  access,
  restriction,
}

/// Status of data requests
enum DataRequestStatus { pending, processing, completed, rejected, failed }

/// Consent update notification
class ConsentUpdate {
  final String userId;
  final ConsentType consentType;
  final bool granted;
  final DateTime timestamp;

  ConsentUpdate({
    required this.userId,
    required this.consentType,
    required this.granted,
    required this.timestamp,
  });
}

/// Data export package
class DataExportPackage {
  final String userId;
  final DateTime exportedAt;
  final List<String> dataCategories;
  final Map<String, dynamic> data;
  final String format;
  final int size;

  DataExportPackage({
    required this.userId,
    required this.exportedAt,
    required this.dataCategories,
    required this.data,
    required this.format,
    required this.size,
  });
}

/// Result of data export operation
class DataExportResult {
  final bool success;
  final DataExportPackage? exportPackage;
  final String message;

  DataExportResult({
    required this.success,
    this.exportPackage,
    required this.message,
  });
}

/// Result of data deletion operation
class DataDeletionResult {
  final bool success;
  final String message;
  final DataDeletionSummary? deletionSummary;
  final RetentionCheck? retentionInfo;

  DataDeletionResult({
    required this.success,
    required this.message,
    this.deletionSummary,
    this.retentionInfo,
  });
}

/// Summary of data deletion
class DataDeletionSummary {
  final List<String> deletedCategories;
  final int deletedRecords;
  final List<String> errors;
  final DateTime completedAt;

  DataDeletionSummary({
    required this.deletedCategories,
    required this.deletedRecords,
    required this.errors,
    required this.completedAt,
  });
}

/// Result of data rectification operation
class DataRectificationResult {
  final bool success;
  final String message;
  final Map<String, bool>? correctionResults;

  DataRectificationResult({
    required this.success,
    required this.message,
    this.correctionResults,
  });
}

/// Data retention policy
class RetentionPolicy {
  final String dataCategory;
  final Duration retentionPeriod;
  final String legalBasis;
  final bool autoDelete;
  final DateTime createdAt;

  RetentionPolicy({
    required this.dataCategory,
    required this.retentionPeriod,
    required this.legalBasis,
    required this.autoDelete,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'dataCategory': dataCategory,
    'retentionPeriodDays': retentionPeriod.inDays,
    'legalBasis': legalBasis,
    'autoDelete': autoDelete,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RetentionPolicy.fromJson(Map<String, dynamic> json) =>
      RetentionPolicy(
        dataCategory: json['dataCategory'],
        retentionPeriod: Duration(days: json['retentionPeriodDays']),
        legalBasis: json['legalBasis'],
        autoDelete: json['autoDelete'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

/// Retention check result
class RetentionCheck {
  final bool hasLegalObligations;
  final String? reason;
  final DateTime? retentionUntil;

  RetentionCheck({
    required this.hasLegalObligations,
    this.reason,
    this.retentionUntil,
  });
}

/// Compliance report
class ComplianceReport {
  final DateTime generatedAt;
  final int totalConsents;
  final int totalDataRequests;
  final int totalRetentionPolicies;
  final List<DataRequest> recentRequests;
  final ComplianceStatus complianceStatus;

  ComplianceReport({
    required this.generatedAt,
    required this.totalConsents,
    required this.totalDataRequests,
    required this.totalRetentionPolicies,
    required this.recentRequests,
    required this.complianceStatus,
  });
}

/// Compliance status
enum ComplianceStatus { compliant, partiallyCompliant, nonCompliant }

