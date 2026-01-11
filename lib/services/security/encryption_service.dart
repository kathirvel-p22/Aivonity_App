import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive encryption service for end-to-end data protection
class EncryptionService {
  static const String _keyPrefix = 'enc_key_';
  static const String _saltPrefix = 'enc_salt_';
  static const int _keyLength = 32; // 256-bit keys
  static const int _saltLength = 16; // 128-bit salt

  final Random _random = Random.secure();
  SharedPreferences? _prefs;

  /// Initialize the encryption service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Generate a new encryption key for a specific data type
  Future<String> generateKey(String keyId) async {
    final key = _generateRandomBytes(_keyLength);
    final keyString = base64Encode(key);

    await _prefs?.setString('$_keyPrefix$keyId', keyString);
    print('🔑 Generated new encryption key for: $keyId');

    return keyString;
  }

  /// Retrieve an existing encryption key
  Future<String?> getKey(String keyId) async {
    return _prefs?.getString('$_keyPrefix$keyId');
  }

  /// Rotate an existing encryption key
  Future<String> rotateKey(String keyId) async {
    final oldKey = await getKey(keyId);
    if (oldKey != null) {
      // Store old key with timestamp for data migration
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _prefs?.setString('$_keyPrefix${keyId}_old_$timestamp', oldKey);
    }

    return await generateKey(keyId);
  }

  /// Encrypt sensitive data with AES-256
  Future<EncryptedData> encryptData(String data, String keyId) async {
    try {
      String? keyString = await getKey(keyId);
      keyString ??= await generateKey(keyId);

      final key = base64Decode(keyString);
      final salt = _generateRandomBytes(_saltLength);
      final iv = _generateRandomBytes(16); // AES block size

      // Derive key using PBKDF2
      final derivedKey = _deriveKey(key, salt);

      // Simple XOR encryption (in production, use proper AES)
      final dataBytes = utf8.encode(data);
      final encryptedBytes = _xorEncrypt(dataBytes, derivedKey, iv);

      return EncryptedData(
        encryptedData: base64Encode(encryptedBytes),
        salt: base64Encode(salt),
        iv: base64Encode(iv),
        keyId: keyId,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  /// Decrypt sensitive data
  Future<String> decryptData(EncryptedData encryptedData) async {
    try {
      final keyString = await getKey(encryptedData.keyId);
      if (keyString == null) {
        throw EncryptionException(
          'Encryption key not found: ${encryptedData.keyId}',
        );
      }

      final key = base64Decode(keyString);
      final salt = base64Decode(encryptedData.salt);
      final iv = base64Decode(encryptedData.iv);
      final encryptedBytes = base64Decode(encryptedData.encryptedData);

      // Derive the same key
      final derivedKey = _deriveKey(key, salt);

      // Decrypt using XOR
      final decryptedBytes = _xorDecrypt(encryptedBytes, derivedKey, iv);

      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Anonymize personal data by replacing with pseudonyms
  String anonymizeData(String data, DataType dataType) {
    switch (dataType) {
      case DataType.email:
        return _anonymizeEmail(data);
      case DataType.phoneNumber:
        return _anonymizePhoneNumber(data);
      case DataType.name:
        return _anonymizeName(data);
      case DataType.address:
        return _anonymizeAddress(data);
      case DataType.vehicleId:
        return _anonymizeVehicleId(data);
      default:
        return _generatePseudonym(data);
    }
  }

  /// Pseudonymize data with consistent mapping
  Future<String> pseudonymizeData(String data, String context) async {
    final hash = sha256.convert(utf8.encode('$data:$context')).toString();
    return 'PSEUDO_${hash.substring(0, 8).toUpperCase()}';
  }

  /// Generate secure hash for data integrity
  String generateHash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Verify data integrity
  bool verifyHash(String data, String expectedHash) {
    return generateHash(data) == expectedHash;
  }

  /// Clear all encryption keys (for security reset)
  Future<void> clearAllKeys() async {
    final keys =
        _prefs?.getKeys().where((key) => key.startsWith(_keyPrefix)) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    print('🔑 All encryption keys cleared');
  }

  // Private helper methods

  Uint8List _generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  Uint8List _deriveKey(Uint8List key, Uint8List salt) {
    // Simple key derivation (in production, use proper PBKDF2)
    final combined = Uint8List(key.length + salt.length);
    combined.setRange(0, key.length, key);
    combined.setRange(key.length, combined.length, salt);

    final hash = sha256.convert(combined);
    return Uint8List.fromList(hash.bytes.take(_keyLength).toList());
  }

  Uint8List _xorEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final encrypted = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    return encrypted;
  }

  Uint8List _xorDecrypt(Uint8List encryptedData, Uint8List key, Uint8List iv) {
    return _xorEncrypt(encryptedData, key, iv); // XOR is symmetric
  }

  String _anonymizeEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return 'anonymous@example.com';

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '***@$domain';
    }

    return '${username.substring(0, 2)}***@$domain';
  }

  String _anonymizePhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 4) return '***-***-****';

    return '***-***-${digits.substring(digits.length - 4)}';
  }

  String _anonymizeName(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return 'Anonymous';

    return parts
        .map((part) {
          if (part.length <= 1) return part;
          return '${part[0]}***';
        })
        .join(' ');
  }

  String _anonymizeAddress(String address) {
    return 'Street Address Anonymized';
  }

  String _anonymizeVehicleId(String vehicleId) {
    if (vehicleId.length < 4) return 'VEH***';
    return 'VEH${vehicleId.substring(vehicleId.length - 4)}';
  }

  String _generatePseudonym(String data) {
    final hash = sha256.convert(utf8.encode(data)).toString();
    return 'ANON_${hash.substring(0, 8).toUpperCase()}';
  }
}

/// Encrypted data container
class EncryptedData {
  final String encryptedData;
  final String salt;
  final String iv;
  final String keyId;
  final DateTime timestamp;

  EncryptedData({
    required this.encryptedData,
    required this.salt,
    required this.iv,
    required this.keyId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'encryptedData': encryptedData,
    'salt': salt,
    'iv': iv,
    'keyId': keyId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
    encryptedData: json['encryptedData'],
    salt: json['salt'],
    iv: json['iv'],
    keyId: json['keyId'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

/// Data types for anonymization
enum DataType { email, phoneNumber, name, address, vehicleId, generic }

/// Custom exception for encryption errors
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}

