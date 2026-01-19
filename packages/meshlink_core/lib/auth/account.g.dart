// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountImpl _$$AccountImplFromJson(Map<String, dynamic> json) =>
    _$AccountImpl(
      id: json['id'] as String,
      handle: json['handle'] as String,
      displayName: json['displayName'] as String,
      hasPasskey: json['hasPasskey'] as bool,
      hasPassword: json['hasPassword'] as bool,
      hasEmail: json['hasEmail'] as bool,
      emailVerified: json['emailVerified'] as bool,
      totpEnabled: json['totpEnabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$AccountImplToJson(_$AccountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'handle': instance.handle,
      'displayName': instance.displayName,
      'hasPasskey': instance.hasPasskey,
      'hasPassword': instance.hasPassword,
      'hasEmail': instance.hasEmail,
      'emailVerified': instance.emailVerified,
      'totpEnabled': instance.totpEnabled,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$RegisterRequestImpl _$$RegisterRequestImplFromJson(
  Map<String, dynamic> json,
) => _$RegisterRequestImpl(
  handle: json['handle'] as String,
  displayName: json['displayName'] as String,
  password: json['password'] as String?,
  email: json['email'] as String?,
  deviceName: json['deviceName'] as String?,
  devicePlatform: json['devicePlatform'] as String?,
);

Map<String, dynamic> _$$RegisterRequestImplToJson(
  _$RegisterRequestImpl instance,
) => <String, dynamic>{
  'handle': instance.handle,
  'displayName': instance.displayName,
  'password': instance.password,
  'email': instance.email,
  'deviceName': instance.deviceName,
  'devicePlatform': instance.devicePlatform,
};

_$LoginRequestImpl _$$LoginRequestImplFromJson(Map<String, dynamic> json) =>
    _$LoginRequestImpl(
      handle: json['handle'] as String,
      password: json['password'] as String,
      totpCode: json['totpCode'] as String?,
      deviceName: json['deviceName'] as String?,
      devicePlatform: json['devicePlatform'] as String?,
    );

Map<String, dynamic> _$$LoginRequestImplToJson(_$LoginRequestImpl instance) =>
    <String, dynamic>{
      'handle': instance.handle,
      'password': instance.password,
      'totpCode': instance.totpCode,
      'deviceName': instance.deviceName,
      'devicePlatform': instance.devicePlatform,
    };

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map<String, dynamic> json) =>
    _$AuthResponseImpl(
      token: json['token'] as String,
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      deviceId: json['deviceId'] as String,
      matrix: json['matrix'] == null
          ? null
          : MatrixCredentials.fromJson(json['matrix'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'account': instance.account,
      'deviceId': instance.deviceId,
      'matrix': instance.matrix,
    };

_$MatrixCredentialsImpl _$$MatrixCredentialsImplFromJson(
  Map<String, dynamic> json,
) => _$MatrixCredentialsImpl(
  userId: json['userId'] as String,
  accessToken: json['accessToken'] as String,
  deviceId: json['deviceId'] as String,
  homeserverUrl: json['homeserverUrl'] as String,
);

Map<String, dynamic> _$$MatrixCredentialsImplToJson(
  _$MatrixCredentialsImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'accessToken': instance.accessToken,
  'deviceId': instance.deviceId,
  'homeserverUrl': instance.homeserverUrl,
};

_$HandleCheckResponseImpl _$$HandleCheckResponseImplFromJson(
  Map<String, dynamic> json,
) => _$HandleCheckResponseImpl(
  available: json['available'] as bool,
  handle: json['handle'] as String,
);

Map<String, dynamic> _$$HandleCheckResponseImplToJson(
  _$HandleCheckResponseImpl instance,
) => <String, dynamic>{
  'available': instance.available,
  'handle': instance.handle,
};

_$TotpSetupResponseImpl _$$TotpSetupResponseImplFromJson(
  Map<String, dynamic> json,
) => _$TotpSetupResponseImpl(
  secret: json['secret'] as String,
  otpauthUrl: json['otpauth_url'] as String,
  qrCodeBase64: json['qr_code_base64'] as String,
);

Map<String, dynamic> _$$TotpSetupResponseImplToJson(
  _$TotpSetupResponseImpl instance,
) => <String, dynamic>{
  'secret': instance.secret,
  'otpauth_url': instance.otpauthUrl,
  'qr_code_base64': instance.qrCodeBase64,
};

_$BackupCodesResponseImpl _$$BackupCodesResponseImplFromJson(
  Map<String, dynamic> json,
) => _$BackupCodesResponseImpl(
  codes: (json['codes'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$$BackupCodesResponseImplToJson(
  _$BackupCodesResponseImpl instance,
) => <String, dynamic>{'codes': instance.codes};

_$ApiErrorImpl _$$ApiErrorImplFromJson(Map<String, dynamic> json) =>
    _$ApiErrorImpl(
      error: json['error'] as String,
      code: json['code'] as String,
    );

Map<String, dynamic> _$$ApiErrorImplToJson(_$ApiErrorImpl instance) =>
    <String, dynamic>{'error': instance.error, 'code': instance.code};

_$DeviceInfoImpl _$$DeviceInfoImplFromJson(Map<String, dynamic> json) =>
    _$DeviceInfoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      isCurrent: json['isCurrent'] as bool,
      location: json['location'] as String?,
    );

Map<String, dynamic> _$$DeviceInfoImplToJson(_$DeviceInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'lastActiveAt': instance.lastActiveAt.toIso8601String(),
      'isCurrent': instance.isCurrent,
      'location': instance.location,
    };

_$DataExportResponseImpl _$$DataExportResponseImplFromJson(
  Map<String, dynamic> json,
) => _$DataExportResponseImpl(
  exportedAt: DateTime.parse(json['exportedAt'] as String),
  account: AccountExportData.fromJson(json['account'] as Map<String, dynamic>),
  devices: (json['devices'] as List<dynamic>)
      .map((e) => DeviceExportData.fromJson(e as Map<String, dynamic>))
      .toList(),
  security: SecurityExportData.fromJson(
    json['security'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$$DataExportResponseImplToJson(
  _$DataExportResponseImpl instance,
) => <String, dynamic>{
  'exportedAt': instance.exportedAt.toIso8601String(),
  'account': instance.account,
  'devices': instance.devices,
  'security': instance.security,
};

_$AccountExportDataImpl _$$AccountExportDataImplFromJson(
  Map<String, dynamic> json,
) => _$AccountExportDataImpl(
  id: json['id'] as String,
  handle: json['handle'] as String,
  displayName: json['displayName'] as String,
  hasEmail: json['hasEmail'] as bool,
  emailVerified: json['emailVerified'] as bool,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$$AccountExportDataImplToJson(
  _$AccountExportDataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'handle': instance.handle,
  'displayName': instance.displayName,
  'hasEmail': instance.hasEmail,
  'emailVerified': instance.emailVerified,
  'createdAt': instance.createdAt,
};

_$DeviceExportDataImpl _$$DeviceExportDataImplFromJson(
  Map<String, dynamic> json,
) => _$DeviceExportDataImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  platform: json['platform'] as String,
  firstSeen: json['firstSeen'] as String,
  lastActive: json['lastActive'] as String,
);

Map<String, dynamic> _$$DeviceExportDataImplToJson(
  _$DeviceExportDataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'platform': instance.platform,
  'firstSeen': instance.firstSeen,
  'lastActive': instance.lastActive,
};

_$SecurityExportDataImpl _$$SecurityExportDataImplFromJson(
  Map<String, dynamic> json,
) => _$SecurityExportDataImpl(
  hasPasskey: json['hasPasskey'] as bool,
  hasPassword: json['hasPassword'] as bool,
  totpEnabled: json['totpEnabled'] as bool,
  backupCodesRemaining: (json['backupCodesRemaining'] as num).toInt(),
);

Map<String, dynamic> _$$SecurityExportDataImplToJson(
  _$SecurityExportDataImpl instance,
) => <String, dynamic>{
  'hasPasskey': instance.hasPasskey,
  'hasPassword': instance.hasPassword,
  'totpEnabled': instance.totpEnabled,
  'backupCodesRemaining': instance.backupCodesRemaining,
};
