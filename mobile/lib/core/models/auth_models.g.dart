// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResult _$AuthResultFromJson(Map<String, dynamic> json) => AuthResult(
      success: json['success'] as bool,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] == null
          ? null
          : UserData.fromJson(json['user'] as Map<String, dynamic>),
      error: json['error'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$AuthResultToJson(AuthResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
      'error': instance.error,
      'message': instance.message,
    };

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      emailVerified: json['emailVerified'] as bool? ?? false,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
    );

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'phone': instance.phone,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
      'emailVerified': instance.emailVerified,
      'role': instance.role,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
    };

LoginCredentials _$LoginCredentialsFromJson(Map<String, dynamic> json) =>
    LoginCredentials(
      email: json['email'] as String,
      password: json['password'] as String,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
    );

Map<String, dynamic> _$LoginCredentialsToJson(LoginCredentials instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
    };

RegistrationData _$RegistrationDataFromJson(Map<String, dynamic> json) =>
    RegistrationData(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      phone: json['phone'] as String?,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
    );

Map<String, dynamic> _$RegistrationDataToJson(RegistrationData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'password': instance.password,
      'phone': instance.phone,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
    };

PasswordResetRequest _$PasswordResetRequestFromJson(
        Map<String, dynamic> json) =>
    PasswordResetRequest(
      email: json['email'] as String,
    );

Map<String, dynamic> _$PasswordResetRequestToJson(
        PasswordResetRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
    };

PasswordResetConfirmation _$PasswordResetConfirmationFromJson(
        Map<String, dynamic> json) =>
    PasswordResetConfirmation(
      token: json['token'] as String,
      newPassword: json['newPassword'] as String,
    );

Map<String, dynamic> _$PasswordResetConfirmationToJson(
        PasswordResetConfirmation instance) =>
    <String, dynamic>{
      'token': instance.token,
      'newPassword': instance.newPassword,
    };

EmailVerificationRequest _$EmailVerificationRequestFromJson(
        Map<String, dynamic> json) =>
    EmailVerificationRequest(
      token: json['token'] as String,
    );

Map<String, dynamic> _$EmailVerificationRequestToJson(
        EmailVerificationRequest instance) =>
    <String, dynamic>{
      'token': instance.token,
    };

TokenPair _$TokenPairFromJson(Map<String, dynamic> json) => TokenPair(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$TokenPairToJson(TokenPair instance) => <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String,
      model: json['model'] as String?,
      version: json['version'] as String?,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      lastActiveAt: json['lastActiveAt'] == null
          ? null
          : DateTime.parse(json['lastActiveAt'] as String),
    );

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'platform': instance.platform,
      'model': instance.model,
      'version': instance.version,
      'registeredAt': instance.registeredAt.toIso8601String(),
      'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
    };

SocialLoginData _$SocialLoginDataFromJson(Map<String, dynamic> json) =>
    SocialLoginData(
      provider: $enumDecode(_$SocialProviderEnumMap, json['provider']),
      token: json['token'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$SocialLoginDataToJson(SocialLoginData instance) =>
    <String, dynamic>{
      'provider': _$SocialProviderEnumMap[instance.provider]!,
      'token': instance.token,
      'email': instance.email,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
    };

const _$SocialProviderEnumMap = {
  SocialProvider.google: 'google',
  SocialProvider.apple: 'apple',
  SocialProvider.facebook: 'facebook',
};

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

