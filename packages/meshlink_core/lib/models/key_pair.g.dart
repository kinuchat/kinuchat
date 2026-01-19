// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_pair.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$Ed25519KeyPairImpl _$$Ed25519KeyPairImplFromJson(Map<String, dynamic> json) =>
    _$Ed25519KeyPairImpl(
      publicKey: const Uint8ListConverter().fromJson(json['publicKey'] as List),
      privateKey: const Uint8ListConverter().fromJson(
        json['privateKey'] as List,
      ),
    );

Map<String, dynamic> _$$Ed25519KeyPairImplToJson(
  _$Ed25519KeyPairImpl instance,
) => <String, dynamic>{
  'publicKey': const Uint8ListConverter().toJson(instance.publicKey),
  'privateKey': const Uint8ListConverter().toJson(instance.privateKey),
};

_$X25519KeyPairImpl _$$X25519KeyPairImplFromJson(Map<String, dynamic> json) =>
    _$X25519KeyPairImpl(
      publicKey: const Uint8ListConverter().fromJson(json['publicKey'] as List),
      privateKey: const Uint8ListConverter().fromJson(
        json['privateKey'] as List,
      ),
    );

Map<String, dynamic> _$$X25519KeyPairImplToJson(_$X25519KeyPairImpl instance) =>
    <String, dynamic>{
      'publicKey': const Uint8ListConverter().toJson(instance.publicKey),
      'privateKey': const Uint8ListConverter().toJson(instance.privateKey),
    };
