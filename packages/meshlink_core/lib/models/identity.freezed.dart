// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Identity _$IdentityFromJson(Map<String, dynamic> json) {
  return _Identity.fromJson(json);
}

/// @nodoc
mixin _$Identity {
  /// Ed25519 signing key pair for identity verification and message signing
  Ed25519KeyPair get signingKeyPair => throw _privateConstructorUsedError;

  /// X25519 key exchange key pair for Noise handshakes and session establishment
  X25519KeyPair get exchangeKeyPair => throw _privateConstructorUsedError;

  /// Mesh Peer ID: truncate(SHA256(Ed25519_pub), 8 bytes)
  @Uint8ListConverter()
  Uint8List get meshPeerId => throw _privateConstructorUsedError;

  /// When the identity was created
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Optional display name
  String? get displayName => throw _privateConstructorUsedError;

  /// Optional avatar URL or data
  String? get avatar => throw _privateConstructorUsedError;

  /// Serializes this Identity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IdentityCopyWith<Identity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IdentityCopyWith<$Res> {
  factory $IdentityCopyWith(Identity value, $Res Function(Identity) then) =
      _$IdentityCopyWithImpl<$Res, Identity>;
  @useResult
  $Res call({
    Ed25519KeyPair signingKeyPair,
    X25519KeyPair exchangeKeyPair,
    @Uint8ListConverter() Uint8List meshPeerId,
    DateTime createdAt,
    String? displayName,
    String? avatar,
  });

  $Ed25519KeyPairCopyWith<$Res> get signingKeyPair;
  $X25519KeyPairCopyWith<$Res> get exchangeKeyPair;
}

/// @nodoc
class _$IdentityCopyWithImpl<$Res, $Val extends Identity>
    implements $IdentityCopyWith<$Res> {
  _$IdentityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? signingKeyPair = null,
    Object? exchangeKeyPair = null,
    Object? meshPeerId = null,
    Object? createdAt = null,
    Object? displayName = freezed,
    Object? avatar = freezed,
  }) {
    return _then(
      _value.copyWith(
            signingKeyPair: null == signingKeyPair
                ? _value.signingKeyPair
                : signingKeyPair // ignore: cast_nullable_to_non_nullable
                      as Ed25519KeyPair,
            exchangeKeyPair: null == exchangeKeyPair
                ? _value.exchangeKeyPair
                : exchangeKeyPair // ignore: cast_nullable_to_non_nullable
                      as X25519KeyPair,
            meshPeerId: null == meshPeerId
                ? _value.meshPeerId
                : meshPeerId // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Ed25519KeyPairCopyWith<$Res> get signingKeyPair {
    return $Ed25519KeyPairCopyWith<$Res>(_value.signingKeyPair, (value) {
      return _then(_value.copyWith(signingKeyPair: value) as $Val);
    });
  }

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $X25519KeyPairCopyWith<$Res> get exchangeKeyPair {
    return $X25519KeyPairCopyWith<$Res>(_value.exchangeKeyPair, (value) {
      return _then(_value.copyWith(exchangeKeyPair: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$IdentityImplCopyWith<$Res>
    implements $IdentityCopyWith<$Res> {
  factory _$$IdentityImplCopyWith(
    _$IdentityImpl value,
    $Res Function(_$IdentityImpl) then,
  ) = __$$IdentityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Ed25519KeyPair signingKeyPair,
    X25519KeyPair exchangeKeyPair,
    @Uint8ListConverter() Uint8List meshPeerId,
    DateTime createdAt,
    String? displayName,
    String? avatar,
  });

  @override
  $Ed25519KeyPairCopyWith<$Res> get signingKeyPair;
  @override
  $X25519KeyPairCopyWith<$Res> get exchangeKeyPair;
}

/// @nodoc
class __$$IdentityImplCopyWithImpl<$Res>
    extends _$IdentityCopyWithImpl<$Res, _$IdentityImpl>
    implements _$$IdentityImplCopyWith<$Res> {
  __$$IdentityImplCopyWithImpl(
    _$IdentityImpl _value,
    $Res Function(_$IdentityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? signingKeyPair = null,
    Object? exchangeKeyPair = null,
    Object? meshPeerId = null,
    Object? createdAt = null,
    Object? displayName = freezed,
    Object? avatar = freezed,
  }) {
    return _then(
      _$IdentityImpl(
        signingKeyPair: null == signingKeyPair
            ? _value.signingKeyPair
            : signingKeyPair // ignore: cast_nullable_to_non_nullable
                  as Ed25519KeyPair,
        exchangeKeyPair: null == exchangeKeyPair
            ? _value.exchangeKeyPair
            : exchangeKeyPair // ignore: cast_nullable_to_non_nullable
                  as X25519KeyPair,
        meshPeerId: null == meshPeerId
            ? _value.meshPeerId
            : meshPeerId // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IdentityImpl extends _Identity {
  const _$IdentityImpl({
    required this.signingKeyPair,
    required this.exchangeKeyPair,
    @Uint8ListConverter() required this.meshPeerId,
    required this.createdAt,
    this.displayName,
    this.avatar,
  }) : super._();

  factory _$IdentityImpl.fromJson(Map<String, dynamic> json) =>
      _$$IdentityImplFromJson(json);

  /// Ed25519 signing key pair for identity verification and message signing
  @override
  final Ed25519KeyPair signingKeyPair;

  /// X25519 key exchange key pair for Noise handshakes and session establishment
  @override
  final X25519KeyPair exchangeKeyPair;

  /// Mesh Peer ID: truncate(SHA256(Ed25519_pub), 8 bytes)
  @override
  @Uint8ListConverter()
  final Uint8List meshPeerId;

  /// When the identity was created
  @override
  final DateTime createdAt;

  /// Optional display name
  @override
  final String? displayName;

  /// Optional avatar URL or data
  @override
  final String? avatar;

  @override
  String toString() {
    return 'Identity(signingKeyPair: $signingKeyPair, exchangeKeyPair: $exchangeKeyPair, meshPeerId: $meshPeerId, createdAt: $createdAt, displayName: $displayName, avatar: $avatar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IdentityImpl &&
            (identical(other.signingKeyPair, signingKeyPair) ||
                other.signingKeyPair == signingKeyPair) &&
            (identical(other.exchangeKeyPair, exchangeKeyPair) ||
                other.exchangeKeyPair == exchangeKeyPair) &&
            const DeepCollectionEquality().equals(
              other.meshPeerId,
              meshPeerId,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatar, avatar) || other.avatar == avatar));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    signingKeyPair,
    exchangeKeyPair,
    const DeepCollectionEquality().hash(meshPeerId),
    createdAt,
    displayName,
    avatar,
  );

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IdentityImplCopyWith<_$IdentityImpl> get copyWith =>
      __$$IdentityImplCopyWithImpl<_$IdentityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IdentityImplToJson(this);
  }
}

abstract class _Identity extends Identity {
  const factory _Identity({
    required final Ed25519KeyPair signingKeyPair,
    required final X25519KeyPair exchangeKeyPair,
    @Uint8ListConverter() required final Uint8List meshPeerId,
    required final DateTime createdAt,
    final String? displayName,
    final String? avatar,
  }) = _$IdentityImpl;
  const _Identity._() : super._();

  factory _Identity.fromJson(Map<String, dynamic> json) =
      _$IdentityImpl.fromJson;

  /// Ed25519 signing key pair for identity verification and message signing
  @override
  Ed25519KeyPair get signingKeyPair;

  /// X25519 key exchange key pair for Noise handshakes and session establishment
  @override
  X25519KeyPair get exchangeKeyPair;

  /// Mesh Peer ID: truncate(SHA256(Ed25519_pub), 8 bytes)
  @override
  @Uint8ListConverter()
  Uint8List get meshPeerId;

  /// When the identity was created
  @override
  DateTime get createdAt;

  /// Optional display name
  @override
  String? get displayName;

  /// Optional avatar URL or data
  @override
  String? get avatar;

  /// Create a copy of Identity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IdentityImplCopyWith<_$IdentityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IdentityBackup _$IdentityBackupFromJson(Map<String, dynamic> json) {
  return _IdentityBackup.fromJson(json);
}

/// @nodoc
mixin _$IdentityBackup {
  Identity get identity => throw _privateConstructorUsedError;

  /// Version of the backup format
  int get version => throw _privateConstructorUsedError;

  /// When the backup was created
  DateTime get exportedAt => throw _privateConstructorUsedError;

  /// Optional password hint (never store the actual password)
  String? get passwordHint => throw _privateConstructorUsedError;

  /// Serializes this IdentityBackup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IdentityBackup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IdentityBackupCopyWith<IdentityBackup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IdentityBackupCopyWith<$Res> {
  factory $IdentityBackupCopyWith(
    IdentityBackup value,
    $Res Function(IdentityBackup) then,
  ) = _$IdentityBackupCopyWithImpl<$Res, IdentityBackup>;
  @useResult
  $Res call({
    Identity identity,
    int version,
    DateTime exportedAt,
    String? passwordHint,
  });

  $IdentityCopyWith<$Res> get identity;
}

/// @nodoc
class _$IdentityBackupCopyWithImpl<$Res, $Val extends IdentityBackup>
    implements $IdentityBackupCopyWith<$Res> {
  _$IdentityBackupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IdentityBackup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? identity = null,
    Object? version = null,
    Object? exportedAt = null,
    Object? passwordHint = freezed,
  }) {
    return _then(
      _value.copyWith(
            identity: null == identity
                ? _value.identity
                : identity // ignore: cast_nullable_to_non_nullable
                      as Identity,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as int,
            exportedAt: null == exportedAt
                ? _value.exportedAt
                : exportedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            passwordHint: freezed == passwordHint
                ? _value.passwordHint
                : passwordHint // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of IdentityBackup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IdentityCopyWith<$Res> get identity {
    return $IdentityCopyWith<$Res>(_value.identity, (value) {
      return _then(_value.copyWith(identity: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$IdentityBackupImplCopyWith<$Res>
    implements $IdentityBackupCopyWith<$Res> {
  factory _$$IdentityBackupImplCopyWith(
    _$IdentityBackupImpl value,
    $Res Function(_$IdentityBackupImpl) then,
  ) = __$$IdentityBackupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Identity identity,
    int version,
    DateTime exportedAt,
    String? passwordHint,
  });

  @override
  $IdentityCopyWith<$Res> get identity;
}

/// @nodoc
class __$$IdentityBackupImplCopyWithImpl<$Res>
    extends _$IdentityBackupCopyWithImpl<$Res, _$IdentityBackupImpl>
    implements _$$IdentityBackupImplCopyWith<$Res> {
  __$$IdentityBackupImplCopyWithImpl(
    _$IdentityBackupImpl _value,
    $Res Function(_$IdentityBackupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IdentityBackup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? identity = null,
    Object? version = null,
    Object? exportedAt = null,
    Object? passwordHint = freezed,
  }) {
    return _then(
      _$IdentityBackupImpl(
        identity: null == identity
            ? _value.identity
            : identity // ignore: cast_nullable_to_non_nullable
                  as Identity,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as int,
        exportedAt: null == exportedAt
            ? _value.exportedAt
            : exportedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        passwordHint: freezed == passwordHint
            ? _value.passwordHint
            : passwordHint // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IdentityBackupImpl implements _IdentityBackup {
  const _$IdentityBackupImpl({
    required this.identity,
    this.version = 1,
    required this.exportedAt,
    this.passwordHint,
  });

  factory _$IdentityBackupImpl.fromJson(Map<String, dynamic> json) =>
      _$$IdentityBackupImplFromJson(json);

  @override
  final Identity identity;

  /// Version of the backup format
  @override
  @JsonKey()
  final int version;

  /// When the backup was created
  @override
  final DateTime exportedAt;

  /// Optional password hint (never store the actual password)
  @override
  final String? passwordHint;

  @override
  String toString() {
    return 'IdentityBackup(identity: $identity, version: $version, exportedAt: $exportedAt, passwordHint: $passwordHint)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IdentityBackupImpl &&
            (identical(other.identity, identity) ||
                other.identity == identity) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.exportedAt, exportedAt) ||
                other.exportedAt == exportedAt) &&
            (identical(other.passwordHint, passwordHint) ||
                other.passwordHint == passwordHint));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, identity, version, exportedAt, passwordHint);

  /// Create a copy of IdentityBackup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IdentityBackupImplCopyWith<_$IdentityBackupImpl> get copyWith =>
      __$$IdentityBackupImplCopyWithImpl<_$IdentityBackupImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$IdentityBackupImplToJson(this);
  }
}

abstract class _IdentityBackup implements IdentityBackup {
  const factory _IdentityBackup({
    required final Identity identity,
    final int version,
    required final DateTime exportedAt,
    final String? passwordHint,
  }) = _$IdentityBackupImpl;

  factory _IdentityBackup.fromJson(Map<String, dynamic> json) =
      _$IdentityBackupImpl.fromJson;

  @override
  Identity get identity;

  /// Version of the backup format
  @override
  int get version;

  /// When the backup was created
  @override
  DateTime get exportedAt;

  /// Optional password hint (never store the actual password)
  @override
  String? get passwordHint;

  /// Create a copy of IdentityBackup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IdentityBackupImplCopyWith<_$IdentityBackupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
