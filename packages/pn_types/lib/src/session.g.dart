// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PosBranding _$PosBrandingFromJson(Map<String, dynamic> json) => _PosBranding(
  appName: json['app_name'] as String?,
  logo: json['logo'] == null
      ? null
      : FileRef.fromJson(json['logo'] as Map<String, dynamic>),
  customDomain: json['custom_domain'] as String?,
  accountMode: json['account_mode'] as String?,
);

Map<String, dynamic> _$PosBrandingToJson(_PosBranding instance) =>
    <String, dynamic>{
      'app_name': instance.appName,
      'logo': instance.logo,
      'custom_domain': instance.customDomain,
      'account_mode': instance.accountMode,
    };

_SessionUser _$SessionUserFromJson(Map<String, dynamic> json) => _SessionUser(
  id: json['id'] as String,
  name: json['name'] as String?,
  email: json['email'] as String?,
);

Map<String, dynamic> _$SessionUserToJson(_SessionUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };

_PosSession _$PosSessionFromJson(Map<String, dynamic> json) => _PosSession(
  baseUrl: json['baseUrl'] as String,
  companyId: json['companyId'] as String,
  outletId: json['outletId'] as String,
  deviceName: json['deviceName'] as String?,
  deviceToken: json['deviceToken'] as String?,
  deviceRevoked: json['deviceRevoked'] as bool? ?? false,
  sessionToken: json['sessionToken'] as String,
  sessionRefreshToken: json['sessionRefreshToken'] as String?,
  expiresAt: json['expiresAt'] as String?,
  user: json['user'] == null
      ? null
      : SessionUser.fromJson(json['user'] as Map<String, dynamic>),
  companies: (json['companies'] as List<dynamic>?)
      ?.map((e) => UserCompany.fromJson(e as Map<String, dynamic>))
      .toList(),
  branding: json['branding'] == null
      ? null
      : PosBranding.fromJson(json['branding'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PosSessionToJson(_PosSession instance) =>
    <String, dynamic>{
      'baseUrl': instance.baseUrl,
      'companyId': instance.companyId,
      'outletId': instance.outletId,
      'deviceName': instance.deviceName,
      'deviceToken': instance.deviceToken,
      'deviceRevoked': instance.deviceRevoked,
      'sessionToken': instance.sessionToken,
      'sessionRefreshToken': instance.sessionRefreshToken,
      'expiresAt': instance.expiresAt,
      'user': instance.user,
      'companies': instance.companies,
      'branding': instance.branding,
    };
