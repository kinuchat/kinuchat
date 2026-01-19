// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IdentityImpl _$$IdentityImplFromJson(Map<String, dynamic> json) =>
    _$IdentityImpl(
      signingKeyPair: Ed25519KeyPair.fromJson(
        json['signingKeyPair'] as Map<String, dynamic>,
      ),
      exchangeKeyPair: X25519KeyPair.fromJson(
        json['exchangeKeyPair'] as Map<String, dynamic>,
      ),
      meshPeerId: const Uint8ListConverter().fromJson(
        json['meshPeerId'] as List,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$$IdentityImplToJson(_$IdentityImpl instance) =>
    <String, dynamic>{
      'signingKeyPair': instance.signingKeyPair,
      'exchangeKeyPair': instance.exchangeKeyPair,
      'meshPeerId': const Uint8ListConverter().toJson(instance.meshPeerId),
      'createdAt': instance.createdAt.toIso8601String(),
      'displayName': instance.displayName,
      'avatar': instance.avatar,
    };

_$IdentityBackupImpl _$$IdentityBackupImplFromJson(Map<String, dynamic> json) =>
    _$IdentityBackupImpl(
      identity: Identity.fromJson(json['identity'] as Map<String, dynamic>),
      version: (json['version'] as num?)?.toInt() ?? 1,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      passwordHint: json['passwordHint'] as String?,
    );

Map<String, dynamic> _$$IdentityBackupImplToJson(
  _$IdentityBackupImpl instance,
) => <String, dynamic>{
  'identity': instance.identity,
  'version': instance.version,
  'exportedAt': instance.exportedAt.toIso8601String(),
  'passwordHint': instance.passwordHint,
};
