import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'key_pair.freezed.dart';
part 'key_pair.g.dart';

/// Ed25519 signing key pair
@freezed
class Ed25519KeyPair with _$Ed25519KeyPair {
  const factory Ed25519KeyPair({
    @Uint8ListConverter() required Uint8List publicKey,
    @Uint8ListConverter() required Uint8List privateKey,
  }) = _Ed25519KeyPair;

  factory Ed25519KeyPair.fromJson(Map<String, dynamic> json) =>
      _$Ed25519KeyPairFromJson(json);
}

/// X25519 key exchange key pair
@freezed
class X25519KeyPair with _$X25519KeyPair {
  const factory X25519KeyPair({
    @Uint8ListConverter() required Uint8List publicKey,
    @Uint8ListConverter() required Uint8List privateKey,
  }) = _X25519KeyPair;

  factory X25519KeyPair.fromJson(Map<String, dynamic> json) =>
      _$X25519KeyPairFromJson(json);
}

/// Converter for Uint8List to JSON
class Uint8ListConverter implements JsonConverter<Uint8List, List<dynamic>> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(List<dynamic> json) =>
      Uint8List.fromList(json.cast<int>());

  @override
  List<int> toJson(Uint8List object) => object.toList();
}
