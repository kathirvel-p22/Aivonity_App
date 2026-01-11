import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

/// Authentication result model
@JsonSerializable()
class AuthResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final UserData? user;
  final String? error;
  final String? message;

  const AuthResult({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.error,
    this.message,
  });

  factory AuthResult.success({
    required String accessToken,
    required String refreshToken,
    required UserData user,
    String? message,
  }) {
    return AuthResult(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      message: message,
    );
  }

  factory AuthResult.failure({
    required String error,
    String? message,
  }) {
    return AuthResult(
      success: false,
      error: error,
      message: message,
    );
  }

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResultToJson(this);
}

/// User data model for authentication
@JsonSerializable()
class UserData {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;
  final bool emailVerified;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserData({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.isVerified = false,
    this.emailVerified = false,
    this.role = 'user',
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

/// Login credentials model
@JsonSerializable()
class LoginCredentials {
  final String email;
  final String password;
  final String? deviceId;
  final String? deviceName;

  const LoginCredentials({
    required this.email,
    required this.password,
    this.deviceId,
    this.deviceName,
  });

  factory LoginCredentials.fromJson(Map<String, dynamic> json) =>
      _$LoginCredentialsFromJson(json);

  Map<String, dynamic> toJson() => _$LoginCredentialsToJson(this);
}

/// Registration data model
@JsonSerializable()
class RegistrationData {
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? deviceId;
  final String? deviceName;

  const RegistrationData({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.deviceId,
    this.deviceName,
  });

  factory RegistrationData.fromJson(Map<String, dynamic> json) =>
      _$RegistrationDataFromJson(json);

  Map<String, dynamic> toJson() => _$RegistrationDataToJson(this);
}

/// Password reset request model
@JsonSerializable()
class PasswordResetRequest {
  final String email;

  const PasswordResetRequest({
    required this.email,
  });

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordResetRequestToJson(this);
}

/// Password reset confirmation model
@JsonSerializable()
class PasswordResetConfirmation {
  final String token;
  final String newPassword;

  const PasswordResetConfirmation({
    required this.token,
    required this.newPassword,
  });

  factory PasswordResetConfirmation.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetConfirmationFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordResetConfirmationToJson(this);
}

/// Email verification model
@JsonSerializable()
class EmailVerificationRequest {
  final String token;

  const EmailVerificationRequest({
    required this.token,
  });

  factory EmailVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$EmailVerificationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EmailVerificationRequestToJson(this);
}

/// Token pair model
@JsonSerializable()
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) =>
      _$TokenPairFromJson(json);

  Map<String, dynamic> toJson() => _$TokenPairToJson(this);
}

/// Device information model
@JsonSerializable()
class DeviceInfo {
  final String id;
  final String name;
  final String platform;
  final String? model;
  final String? version;
  final DateTime registeredAt;
  final DateTime? lastActiveAt;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    this.model,
    this.version,
    required this.registeredAt,
    this.lastActiveAt,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);
}

/// Social login provider enum
enum SocialProvider {
  google,
  apple,
  facebook,
}

/// Social login data model
@JsonSerializable()
class SocialLoginData {
  final SocialProvider provider;
  final String token;
  final String? email;
  final String? name;
  final String? avatarUrl;

  const SocialLoginData({
    required this.provider,
    required this.token,
    this.email,
    this.name,
    this.avatarUrl,
  });

  factory SocialLoginData.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginDataFromJson(json);

  Map<String, dynamic> toJson() => _$SocialLoginDataToJson(this);
}

