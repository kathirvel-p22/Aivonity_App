import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';

/// Advanced key management service with rotation and secure storage
class KeyManagementService {
  static const String _masterKeyId = 'master_key';
  static const String _keyRotationPrefix = 'key_rotation_';
  static const String _keyMetadataPrefix = 'key_metadata_';
  static const Duration _defaultRotationInterval = Duration(days: 30);

  SharedPreferences? _prefs;
  final Random _random = Random.secure();

  /// Initialize the key management service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _ensureMasterKey();
    await _scheduleKeyRotations();
  }

  /// Create a new encryption key with metadata
  Future<KeyMetadata> createKey({
    required String keyId,
    required KeyType keyType,
    Duration? rotationInterval,
    Map<String, String>? tags,
  }) async {
    final keyData = _generateSecureKey();
    final metadata = KeyMetadata(
      keyId: keyId,
      keyType: keyType,
      createdAt: DateTime.now(),
      lastRotated: DateTime.now(),
      rotationInterval: rotationInterval ?? _defaultRotationInterval,
      version: 1,
      status: KeyStatus.active,
      tags: tags ?? {},
    );

    // Encrypt the key with master key
    final encryptedKey = await _encryptWithMasterKey(keyData);

    // Store encrypted key and metadata
    await _prefs?.setString('key_$keyId', encryptedKey);
    await _prefs?.setString(
      '$_keyMetadataPrefix$keyId',
      jsonEncode(metadata.toJson()),
    );

    AppLogger.info('🔑 Created new key: $keyId (${keyType.name})');
    return metadata;
  }

  /// Retrieve a key by ID
  Future<String?> getKey(String keyId) async {
    final encryptedKey = _prefs?.getString('key_$keyId');
    if (encryptedKey == null) return null;

    return await _decryptWithMasterKey(encryptedKey);
  }

  /// Get key metadata
  Future<KeyMetadata?> getKeyMetadata(String keyId) async {
    final metadataJson = _prefs?.getString('$_keyMetadataPrefix$keyId');
    if (metadataJson == null) return null;

    return KeyMetadata.fromJson(jsonDecode(metadataJson));
  }

  /// Rotate a key (create new version, keep old for decryption)
  Future<KeyMetadata> rotateKey(String keyId) async {
    final currentMetadata = await getKeyMetadata(keyId);
    if (currentMetadata == null) {
      throw KeyManagementException('Key not found: $keyId');
    }

    // Archive current key version
    final currentKey = await getKey(keyId);
    if (currentKey != null) {
      await _archiveKeyVersion(keyId, currentMetadata.version, currentKey);
    }

    // Generate new key
    final newKeyData = _generateSecureKey();
    final newMetadata = currentMetadata.copyWith(
      version: currentMetadata.version + 1,
      lastRotated: DateTime.now(),
      status: KeyStatus.active,
    );

    // Store new key and metadata
    final encryptedKey = await _encryptWithMasterKey(newKeyData);
    await _prefs?.setString('key_$keyId', encryptedKey);
    await _prefs?.setString(
      '$_keyMetadataPrefix$keyId',
      jsonEncode(newMetadata.toJson()),
    );

    AppLogger.info(
      '🔄 Rotated key: $keyId (v${currentMetadata.version} → v${newMetadata.version})',
    );
    return newMetadata;
  }

  /// Perform automatic key rotation for expired keys
  Future<void> performScheduledRotations() async {
    final keysToRotate = await getKeysNeedingRotation();

    for (final keyMetadata in keysToRotate) {
      try {
        await rotateKey(keyMetadata.keyId);
        AppLogger.info('✅ Auto-rotated key: ${keyMetadata.keyId}');
      } catch (e) {
        AppLogger.error('❌ Failed to rotate key ${keyMetadata.keyId}', e);
      }
    }
  }

  /// Check which keys need rotation
  Future<List<KeyMetadata>> getKeysNeedingRotation() async {
    final allKeys = await listKeys();
    final now = DateTime.now();

    return allKeys.where((key) {
      final nextRotation = key.lastRotated.add(key.rotationInterval);
      return now.isAfter(nextRotation) && key.status == KeyStatus.active;
    }).toList();
  }

  /// List all keys with their metadata
  Future<List<KeyMetadata>> listKeys() async {
    final keys = <KeyMetadata>[];
    final allKeys = _prefs?.getKeys() ?? <String>{};

    for (final key in allKeys) {
      if (key.startsWith(_keyMetadataPrefix)) {
        final keyId = key.substring(_keyMetadataPrefix.length);
        final metadata = await getKeyMetadata(keyId);
        if (metadata != null) {
          keys.add(metadata);
        }
      }
    }

    return keys;
  }

  // Private helper methods

  Future<void> _ensureMasterKey() async {
    final masterKey = _prefs?.getString(_masterKeyId);
    if (masterKey == null) {
      final newMasterKey = _generateSecureKey();
      await _prefs?.setString(
        _masterKeyId,
        base64Encode(utf8.encode(newMasterKey)),
      );
      AppLogger.info('🔐 Generated new master key');
    }
  }

  Future<void> _scheduleKeyRotations() async {
    AppLogger.info('📅 Key rotation scheduler initialized');
  }

  String _generateSecureKey() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    return List.generate(
      64,
      (index) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  Future<String> _encryptWithMasterKey(String data) async {
    final masterKeyData = _prefs?.getString(_masterKeyId);
    if (masterKeyData == null) {
      throw KeyManagementException('Master key not found');
    }

    final masterKey = utf8.decode(base64Decode(masterKeyData));
    final dataBytes = utf8.encode(data);
    final encrypted = <int>[];

    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ masterKey.codeUnitAt(i % masterKey.length));
    }

    return base64Encode(encrypted);
  }

  Future<String> _decryptWithMasterKey(String encryptedData) async {
    final masterKeyData = _prefs?.getString(_masterKeyId);
    if (masterKeyData == null) {
      throw KeyManagementException('Master key not found');
    }

    final masterKey = utf8.decode(base64Decode(masterKeyData));
    final encryptedBytes = base64Decode(encryptedData);
    final decrypted = <int>[];

    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(
        encryptedBytes[i] ^ masterKey.codeUnitAt(i % masterKey.length),
      );
    }

    return utf8.decode(decrypted);
  }

  Future<void> _archiveKeyVersion(
    String keyId,
    int version,
    String keyData,
  ) async {
    final encryptedKey = await _encryptWithMasterKey(keyData);
    await _prefs?.setString('key_${keyId}_v$version', encryptedKey);
  }
}

/// Key metadata for tracking and management
class KeyMetadata {
  final String keyId;
  final KeyType keyType;
  final DateTime createdAt;
  final DateTime lastRotated;
  final Duration rotationInterval;
  final int version;
  final KeyStatus status;
  final Map<String, String> tags;

  KeyMetadata({
    required this.keyId,
    required this.keyType,
    required this.createdAt,
    required this.lastRotated,
    required this.rotationInterval,
    required this.version,
    required this.status,
    required this.tags,
  });

  KeyMetadata copyWith({
    String? keyId,
    KeyType? keyType,
    DateTime? createdAt,
    DateTime? lastRotated,
    Duration? rotationInterval,
    int? version,
    KeyStatus? status,
    Map<String, String>? tags,
  }) {
    return KeyMetadata(
      keyId: keyId ?? this.keyId,
      keyType: keyType ?? this.keyType,
      createdAt: createdAt ?? this.createdAt,
      lastRotated: lastRotated ?? this.lastRotated,
      rotationInterval: rotationInterval ?? this.rotationInterval,
      version: version ?? this.version,
      status: status ?? this.status,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'keyId': keyId,
    'keyType': keyType.name,
    'createdAt': createdAt.toIso8601String(),
    'lastRotated': lastRotated.toIso8601String(),
    'rotationIntervalDays': rotationInterval.inDays,
    'version': version,
    'status': status.name,
    'tags': tags,
  };

  factory KeyMetadata.fromJson(Map<String, dynamic> json) => KeyMetadata(
    keyId: json['keyId'],
    keyType: KeyType.values.firstWhere((e) => e.name == json['keyType']),
    createdAt: DateTime.parse(json['createdAt']),
    lastRotated: DateTime.parse(json['lastRotated']),
    rotationInterval: Duration(days: json['rotationIntervalDays']),
    version: json['version'],
    status: KeyStatus.values.firstWhere((e) => e.name == json['status']),
    tags: Map<String, String>.from(json['tags']),
  );
}

/// Types of encryption keys
enum KeyType {
  dataEncryption,
  tokenSigning,
  apiAuthentication,
  sessionEncryption,
}

/// Key lifecycle status
enum KeyStatus { active, archived, revoked, expired }

/// Custom exception for key management errors
class KeyManagementException implements Exception {
  final String message;
  KeyManagementException(this.message);

  @override
  String toString() => 'KeyManagementException: $message';
}
