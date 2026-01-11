import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for data anonymization and pseudonymization for GDPR compliance
class DataAnonymizationService {
  static const String _pseudonymMappingPrefix = 'pseudonym_';
  static const String _anonymizationLogPrefix = 'anon_log_';

  final Random _random = Random.secure();
  SharedPreferences? _prefs;

  /// Initialize the anonymization service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Anonymize personal data by removing identifying information
  AnonymizedData anonymizePersonalData(Map<String, dynamic> personalData) {
    final anonymized = <String, dynamic>{};
    final anonymizationLog = <String, AnonymizationAction>{};

    for (final entry in personalData.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        anonymized[key] = null;
        continue;
      }

      final dataType = _detectDataType(key, value.toString());
      final anonymizedValue = _anonymizeByType(value.toString(), dataType);

      anonymized[key] = anonymizedValue;
      anonymizationLog[key] = AnonymizationAction(
        originalType: dataType,
        method: _getAnonymizationMethod(dataType),
        timestamp: DateTime.now(),
      );
    }

    return AnonymizedData(
      anonymizedData: anonymized,
      anonymizationLog: anonymizationLog,
      anonymizedAt: DateTime.now(),
    );
  }

  /// Create consistent pseudonyms for data that needs to be linkable
  Future<String> createPseudonym(String originalValue, String context) async {
    final pseudonymKey =
        '$_pseudonymMappingPrefix${context}_${_hashValue(originalValue)}';

    // Check if pseudonym already exists
    String? existingPseudonym = _prefs?.getString(pseudonymKey);
    if (existingPseudonym != null) {
      return existingPseudonym;
    }

    // Generate new pseudonym
    final pseudonym = _generatePseudonym(context);
    await _prefs?.setString(pseudonymKey, pseudonym);

    // Log the pseudonymization
    await _logPseudonymization(originalValue, pseudonym, context);

    return pseudonym;
  }

  /// Pseudonymize a dataset while maintaining relationships
  Future<Map<String, dynamic>> pseudonymizeDataset(
    Map<String, dynamic> dataset,
    Map<String, String> fieldContexts,
  ) async {
    final pseudonymized = <String, dynamic>{};

    for (final entry in dataset.entries) {
      final key = entry.key;
      final value = entry.value;
      final context = fieldContexts[key];

      if (context != null && value != null) {
        pseudonymized[key] = await createPseudonym(value.toString(), context);
      } else {
        pseudonymized[key] = value;
      }
    }

    return pseudonymized;
  }

  /// Remove all personal identifiers (for complete anonymization)
  Map<String, dynamic> removePersonalIdentifiers(Map<String, dynamic> data) {
    final sensitiveFields = {
      'name',
      'firstName',
      'lastName',
      'fullName',
      'email',
      'emailAddress',
      'phone',
      'phoneNumber',
      'address',
      'streetAddress',
      'homeAddress',
      'ssn',
      'socialSecurityNumber',
      'nationalId',
      'driverLicense',
      'passport',
      'creditCard',
      'userId',
      'customerId',
      'accountId',
    };

    final anonymized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();

      if (sensitiveFields.any((field) => key.contains(field))) {
        anonymized[entry.key] = '[REMOVED]';
      } else {
        anonymized[entry.key] = entry.value;
      }
    }

    return anonymized;
  }

  /// Generalize numeric data to ranges
  String generalizeNumericData(num value, GeneralizationLevel level) {
    switch (level) {
      case GeneralizationLevel.low:
        return _roundToNearest(value, 10).toString();
      case GeneralizationLevel.medium:
        return _roundToNearest(value, 100).toString();
      case GeneralizationLevel.high:
        return _createRange(value, 1000);
      case GeneralizationLevel.extreme:
        return _createRange(value, 10000);
    }
  }

  /// Generalize date data
  String generalizeDateData(DateTime date, GeneralizationLevel level) {
    switch (level) {
      case GeneralizationLevel.low:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case GeneralizationLevel.medium:
        return '${date.year}-Q${((date.month - 1) ~/ 3) + 1}';
      case GeneralizationLevel.high:
        return date.year.toString();
      case GeneralizationLevel.extreme:
        return '${(date.year ~/ 10) * 10}s';
    }
  }

  /// Apply k-anonymity to a dataset
  List<Map<String, dynamic>> applyKAnonymity(
    List<Map<String, dynamic>> dataset,
    List<String> quasiIdentifiers,
    int k,
  ) {
    // Group records by quasi-identifier combinations
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final record in dataset) {
      final key = quasiIdentifiers
          .map((field) => record[field]?.toString() ?? '')
          .join('|');
      groups[key] ??= [];
      groups[key]!.add(record);
    }

    // Filter out groups with less than k records
    final anonymizedDataset = <Map<String, dynamic>>[];

    for (final group in groups.values) {
      if (group.length >= k) {
        anonymizedDataset.addAll(group);
      } else {
        // Generalize the quasi-identifiers for small groups
        for (final record in group) {
          final generalizedRecord = Map<String, dynamic>.from(record);
          for (final field in quasiIdentifiers) {
            generalizedRecord[field] = '[GENERALIZED]';
          }
          anonymizedDataset.add(generalizedRecord);
        }
      }
    }

    return anonymizedDataset;
  }

  /// Get anonymization statistics
  Future<AnonymizationStats> getAnonymizationStats() async {
    final allKeys = _prefs?.getKeys() ?? <String>{};

    final pseudonymCount = allKeys
        .where((key) => key.startsWith(_pseudonymMappingPrefix))
        .length;

    final logCount = allKeys
        .where((key) => key.startsWith(_anonymizationLogPrefix))
        .length;

    return AnonymizationStats(
      totalPseudonyms: pseudonymCount,
      totalAnonymizations: logCount,
      lastAnonymization: await _getLastAnonymizationTime(),
    );
  }

  /// Clear all pseudonym mappings (for data subject rights)
  Future<void> clearPseudonymMappings(String context) async {
    final allKeys = _prefs?.getKeys() ?? <String>{};
    final keysToRemove = allKeys
        .where((key) => key.startsWith('$_pseudonymMappingPrefix${context}_'))
        .toList();

    for (final key in keysToRemove) {
      await _prefs?.remove(key);
    }

    print(
      '🗑️ Cleared ${keysToRemove.length} pseudonym mappings for context: $context',
    );
  }

  // Private helper methods

  DataType _detectDataType(String fieldName, String value) {
    final lowerField = fieldName.toLowerCase();

    if (lowerField.contains('email')) return DataType.email;
    if (lowerField.contains('phone')) return DataType.phone;
    if (lowerField.contains('name')) return DataType.name;
    if (lowerField.contains('address')) return DataType.address;
    if (lowerField.contains('id')) return DataType.identifier;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(value)) return DataType.date;
    if (RegExp(r'^\d+$').hasMatch(value)) return DataType.numeric;

    return DataType.generic;
  }

  String _anonymizeByType(String value, DataType type) {
    switch (type) {
      case DataType.email:
        return _anonymizeEmail(value);
      case DataType.phone:
        return _anonymizePhone(value);
      case DataType.name:
        return _anonymizeName(value);
      case DataType.address:
        return '[ADDRESS REMOVED]';
      case DataType.identifier:
        return '[ID REMOVED]';
      case DataType.date:
        return _anonymizeDate(value);
      case DataType.numeric:
        return _anonymizeNumeric(value);
      case DataType.generic:
        return '[ANONYMIZED]';
    }
  }

  String _anonymizeEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '[EMAIL]';

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '***@$domain';
    }

    return '${username.substring(0, 2)}***@$domain';
  }

  String _anonymizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 4) return '[PHONE]';

    return '***-***-${digits.substring(digits.length - 4)}';
  }

  String _anonymizeName(String name) {
    final parts = name.split(' ');
    return parts
        .map((part) {
          if (part.length <= 1) return part;
          return '${part[0]}***';
        })
        .join(' ');
  }

  String _anonymizeDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return parsed.year.toString();
    } catch (e) {
      return '[DATE]';
    }
  }

  String _anonymizeNumeric(String numeric) {
    try {
      final value = num.parse(numeric);
      return _roundToNearest(value, 100).toString();
    } catch (e) {
      return '[NUMBER]';
    }
  }

  AnonymizationMethod _getAnonymizationMethod(DataType type) {
    switch (type) {
      case DataType.email:
      case DataType.phone:
      case DataType.name:
        return AnonymizationMethod.masking;
      case DataType.address:
      case DataType.identifier:
        return AnonymizationMethod.removal;
      case DataType.date:
      case DataType.numeric:
        return AnonymizationMethod.generalization;
      case DataType.generic:
        return AnonymizationMethod.suppression;
    }
  }

  String _generatePseudonym(String context) {
    final prefixes = {
      'user': 'USR',
      'vehicle': 'VEH',
      'location': 'LOC',
      'session': 'SES',
    };

    final prefix = prefixes[context] ?? 'PSE';
    final randomId = _random.nextInt(999999).toString().padLeft(6, '0');

    return '${prefix}_$randomId';
  }

  String _hashValue(String value) {
    return sha256.convert(utf8.encode(value)).toString().substring(0, 16);
  }

  num _roundToNearest(num value, num nearest) {
    return (value / nearest).round() * nearest;
  }

  String _createRange(num value, num rangeSize) {
    final lowerBound = (value / rangeSize).floor() * rangeSize;
    final upperBound = lowerBound + rangeSize;
    return '$lowerBound-$upperBound';
  }

  Future<void> _logPseudonymization(
    String original,
    String pseudonym,
    String context,
  ) async {
    final logKey =
        '$_anonymizationLogPrefix${DateTime.now().millisecondsSinceEpoch}';
    final logEntry = {
      'context': context,
      'pseudonym': pseudonym,
      'originalHash': _hashValue(original),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _prefs?.setString(logKey, jsonEncode(logEntry));
  }

  Future<DateTime?> _getLastAnonymizationTime() async {
    final allKeys = _prefs?.getKeys() ?? <String>{};
    final logKeys = allKeys
        .where((key) => key.startsWith(_anonymizationLogPrefix))
        .toList();

    if (logKeys.isEmpty) return null;

    logKeys.sort();
    final lastLogKey = logKeys.last;
    final timestamp = lastLogKey.substring(_anonymizationLogPrefix.length);

    return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
  }
}

/// Container for anonymized data with metadata
class AnonymizedData {
  final Map<String, dynamic> anonymizedData;
  final Map<String, AnonymizationAction> anonymizationLog;
  final DateTime anonymizedAt;

  AnonymizedData({
    required this.anonymizedData,
    required this.anonymizationLog,
    required this.anonymizedAt,
  });
}

/// Record of anonymization action
class AnonymizationAction {
  final DataType originalType;
  final AnonymizationMethod method;
  final DateTime timestamp;

  AnonymizationAction({
    required this.originalType,
    required this.method,
    required this.timestamp,
  });
}

/// Statistics about anonymization operations
class AnonymizationStats {
  final int totalPseudonyms;
  final int totalAnonymizations;
  final DateTime? lastAnonymization;

  AnonymizationStats({
    required this.totalPseudonyms,
    required this.totalAnonymizations,
    this.lastAnonymization,
  });
}

/// Data types for anonymization
enum DataType {
  email,
  phone,
  name,
  address,
  identifier,
  date,
  numeric,
  generic,
}

/// Anonymization methods
enum AnonymizationMethod {
  masking,
  removal,
  generalization,
  suppression,
  pseudonymization,
}

/// Levels of generalization
enum GeneralizationLevel { low, medium, high, extreme }

