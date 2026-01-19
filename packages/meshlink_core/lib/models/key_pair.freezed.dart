// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'key_pair.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Ed25519KeyPair _$Ed25519KeyPairFromJson(Map<String, dynamic> json) {
  return _Ed25519KeyPair.fromJson(json);
}

/// @nodoc
mixin _$Ed25519KeyPair {
  @Uint8ListConverter()
  Uint8List get publicKey => throw _privateConstructorUsedError;
  @Uint8ListConverter()
  Uint8List get privateKey => throw _privateConstructorUsedError;

  /// Serializes this Ed25519KeyPair to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Ed25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $Ed25519KeyPairCopyWith<Ed25519KeyPair> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $Ed25519KeyPairCopyWith<$Res> {
  factory $Ed25519KeyPairCopyWith(
    Ed25519KeyPair value,
    $Res Function(Ed25519KeyPair) then,
  ) = _$Ed25519KeyPairCopyWithImpl<$Res, Ed25519KeyPair>;
  @useResult
  $Res call({
    @Uint8ListConverter() Uint8List publicKey,
    @Uint8ListConverter() Uint8List privateKey,
  });
}

/// @nodoc
class _$Ed25519KeyPairCopyWithImpl<$Res, $Val extends Ed25519KeyPair>
    implements $Ed25519KeyPairCopyWith<$Res> {
  _$Ed25519KeyPairCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Ed25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? publicKey = null, Object? privateKey = null}) {
    return _then(
      _value.copyWith(
            publicKey: null == publicKey
                ? _value.publicKey
                : publicKey // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
            privateKey: null == privateKey
                ? _value.privateKey
                : privateKey // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$Ed25519KeyPairImplCopyWith<$Res>
    implements $Ed25519KeyPairCopyWith<$Res> {
  factory _$$Ed25519KeyPairImplCopyWith(
    _$Ed25519KeyPairImpl value,
    $Res Function(_$Ed25519KeyPairImpl) then,
  ) = __$$Ed25519KeyPairImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @Uint8ListConverter() Uint8List publicKey,
    @Uint8ListConverter() Uint8List privateKey,
  });
}

/// @nodoc
class __$$Ed25519KeyPairImplCopyWithImpl<$Res>
    extends _$Ed25519KeyPairCopyWithImpl<$Res, _$Ed25519KeyPairImpl>
    implements _$$Ed25519KeyPairImplCopyWith<$Res> {
  __$$Ed25519KeyPairImplCopyWithImpl(
    _$Ed25519KeyPairImpl _value,
    $Res Function(_$Ed25519KeyPairImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Ed25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? publicKey = null, Object? privateKey = null}) {
    return _then(
      _$Ed25519KeyPairImpl(
        publicKey: null == publicKey
            ? _value.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
        privateKey: null == privateKey
            ? _value.privateKey
            : privateKey // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$Ed25519KeyPairImpl implements _Ed25519KeyPair {
  const _$Ed25519KeyPairImpl({
    @Uint8ListConverter() required this.publicKey,
    @Uint8ListConverter() required this.privateKey,
  });

  factory _$Ed25519KeyPairImpl.fromJson(Map<String, dynamic> json) =>
      _$$Ed25519KeyPairImplFromJson(json);

  @override
  @Uint8ListConverter()
  final Uint8List publicKey;
  @override
  @Uint8ListConverter()
  final Uint8List privateKey;

  @override
  String toString() {
    return 'Ed25519KeyPair(publicKey: $publicKey, privateKey: $privateKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Ed25519KeyPairImpl &&
            const DeepCollectionEquality().equals(other.publicKey, publicKey) &&
            const DeepCollectionEquality().equals(
              other.privateKey,
              privateKey,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(publicKey),
    const DeepCollectionEquality().hash(privateKey),
  );

  /// Create a copy of Ed25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Ed25519KeyPairImplCopyWith<_$Ed25519KeyPairImpl> get copyWith =>
      __$$Ed25519KeyPairImplCopyWithImpl<_$Ed25519KeyPairImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$Ed25519KeyPairImplToJson(this);
  }
}

abstract class _Ed25519KeyPair implements Ed25519KeyPair {
  const factory _Ed25519KeyPair({
    @Uint8ListConverter() required final Uint8List publicKey,
    @Uint8ListConverter() required final Uint8List privateKey,
  }) = _$Ed25519KeyPairImpl;

  factory _Ed25519KeyPair.fromJson(Map<String, dynamic> json) =
      _$Ed25519KeyPairImpl.fromJson;

  @override
  @Uint8ListConverter()
  Uint8List get publicKey;
  @override
  @Uint8ListConverter()
  Uint8List get privateKey;

  /// Create a copy of Ed25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Ed25519KeyPairImplCopyWith<_$Ed25519KeyPairImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

X25519KeyPair _$X25519KeyPairFromJson(Map<String, dynamic> json) {
  return _X25519KeyPair.fromJson(json);
}

/// @nodoc
mixin _$X25519KeyPair {
  @Uint8ListConverter()
  Uint8List get publicKey => throw _privateConstructorUsedError;
  @Uint8ListConverter()
  Uint8List get privateKey => throw _privateConstructorUsedError;

  /// Serializes this X25519KeyPair to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of X25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $X25519KeyPairCopyWith<X25519KeyPair> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $X25519KeyPairCopyWith<$Res> {
  factory $X25519KeyPairCopyWith(
    X25519KeyPair value,
    $Res Function(X25519KeyPair) then,
  ) = _$X25519KeyPairCopyWithImpl<$Res, X25519KeyPair>;
  @useResult
  $Res call({
    @Uint8ListConverter() Uint8List publicKey,
    @Uint8ListConverter() Uint8List privateKey,
  });
}

/// @nodoc
class _$X25519KeyPairCopyWithImpl<$Res, $Val extends X25519KeyPair>
    implements $X25519KeyPairCopyWith<$Res> {
  _$X25519KeyPairCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of X25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? publicKey = null, Object? privateKey = null}) {
    return _then(
      _value.copyWith(
            publicKey: null == publicKey
                ? _value.publicKey
                : publicKey // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
            privateKey: null == privateKey
                ? _value.privateKey
                : privateKey // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$X25519KeyPairImplCopyWith<$Res>
    implements $X25519KeyPairCopyWith<$Res> {
  factory _$$X25519KeyPairImplCopyWith(
    _$X25519KeyPairImpl value,
    $Res Function(_$X25519KeyPairImpl) then,
  ) = __$$X25519KeyPairImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @Uint8ListConverter() Uint8List publicKey,
    @Uint8ListConverter() Uint8List privateKey,
  });
}

/// @nodoc
class __$$X25519KeyPairImplCopyWithImpl<$Res>
    extends _$X25519KeyPairCopyWithImpl<$Res, _$X25519KeyPairImpl>
    implements _$$X25519KeyPairImplCopyWith<$Res> {
  __$$X25519KeyPairImplCopyWithImpl(
    _$X25519KeyPairImpl _value,
    $Res Function(_$X25519KeyPairImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of X25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? publicKey = null, Object? privateKey = null}) {
    return _then(
      _$X25519KeyPairImpl(
        publicKey: null == publicKey
            ? _value.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
        privateKey: null == privateKey
            ? _value.privateKey
            : privateKey // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$X25519KeyPairImpl implements _X25519KeyPair {
  const _$X25519KeyPairImpl({
    @Uint8ListConverter() required this.publicKey,
    @Uint8ListConverter() required this.privateKey,
  });

  factory _$X25519KeyPairImpl.fromJson(Map<String, dynamic> json) =>
      _$$X25519KeyPairImplFromJson(json);

  @override
  @Uint8ListConverter()
  final Uint8List publicKey;
  @override
  @Uint8ListConverter()
  final Uint8List privateKey;

  @override
  String toString() {
    return 'X25519KeyPair(publicKey: $publicKey, privateKey: $privateKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$X25519KeyPairImpl &&
            const DeepCollectionEquality().equals(other.publicKey, publicKey) &&
            const DeepCollectionEquality().equals(
              other.privateKey,
              privateKey,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(publicKey),
    const DeepCollectionEquality().hash(privateKey),
  );

  /// Create a copy of X25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$X25519KeyPairImplCopyWith<_$X25519KeyPairImpl> get copyWith =>
      __$$X25519KeyPairImplCopyWithImpl<_$X25519KeyPairImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$X25519KeyPairImplToJson(this);
  }
}

abstract class _X25519KeyPair implements X25519KeyPair {
  const factory _X25519KeyPair({
    @Uint8ListConverter() required final Uint8List publicKey,
    @Uint8ListConverter() required final Uint8List privateKey,
  }) = _$X25519KeyPairImpl;

  factory _X25519KeyPair.fromJson(Map<String, dynamic> json) =
      _$X25519KeyPairImpl.fromJson;

  @override
  @Uint8ListConverter()
  Uint8List get publicKey;
  @override
  @Uint8ListConverter()
  Uint8List get privateKey;

  /// Create a copy of X25519KeyPair
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$X25519KeyPairImplCopyWith<_$X25519KeyPairImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
