// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Account _$AccountFromJson(Map<String, dynamic> json) {
  return _Account.fromJson(json);
}

/// @nodoc
mixin _$Account {
  String get id => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  bool get hasPasskey => throw _privateConstructorUsedError;
  bool get hasPassword => throw _privateConstructorUsedError;
  bool get hasEmail => throw _privateConstructorUsedError;
  bool get emailVerified => throw _privateConstructorUsedError;
  bool get totpEnabled => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountCopyWith<Account> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountCopyWith<$Res> {
  factory $AccountCopyWith(Account value, $Res Function(Account) then) =
      _$AccountCopyWithImpl<$Res, Account>;
  @useResult
  $Res call({
    String id,
    String handle,
    String displayName,
    bool hasPasskey,
    bool hasPassword,
    bool hasEmail,
    bool emailVerified,
    bool totpEnabled,
    DateTime createdAt,
  });
}

/// @nodoc
class _$AccountCopyWithImpl<$Res, $Val extends Account>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handle = null,
    Object? displayName = null,
    Object? hasPasskey = null,
    Object? hasPassword = null,
    Object? hasEmail = null,
    Object? emailVerified = null,
    Object? totpEnabled = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            handle: null == handle
                ? _value.handle
                : handle // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            hasPasskey: null == hasPasskey
                ? _value.hasPasskey
                : hasPasskey // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasPassword: null == hasPassword
                ? _value.hasPassword
                : hasPassword // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasEmail: null == hasEmail
                ? _value.hasEmail
                : hasEmail // ignore: cast_nullable_to_non_nullable
                      as bool,
            emailVerified: null == emailVerified
                ? _value.emailVerified
                : emailVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            totpEnabled: null == totpEnabled
                ? _value.totpEnabled
                : totpEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountImplCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$$AccountImplCopyWith(
    _$AccountImpl value,
    $Res Function(_$AccountImpl) then,
  ) = __$$AccountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String handle,
    String displayName,
    bool hasPasskey,
    bool hasPassword,
    bool hasEmail,
    bool emailVerified,
    bool totpEnabled,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$AccountImplCopyWithImpl<$Res>
    extends _$AccountCopyWithImpl<$Res, _$AccountImpl>
    implements _$$AccountImplCopyWith<$Res> {
  __$$AccountImplCopyWithImpl(
    _$AccountImpl _value,
    $Res Function(_$AccountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handle = null,
    Object? displayName = null,
    Object? hasPasskey = null,
    Object? hasPassword = null,
    Object? hasEmail = null,
    Object? emailVerified = null,
    Object? totpEnabled = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$AccountImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        handle: null == handle
            ? _value.handle
            : handle // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        hasPasskey: null == hasPasskey
            ? _value.hasPasskey
            : hasPasskey // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasPassword: null == hasPassword
            ? _value.hasPassword
            : hasPassword // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasEmail: null == hasEmail
            ? _value.hasEmail
            : hasEmail // ignore: cast_nullable_to_non_nullable
                  as bool,
        emailVerified: null == emailVerified
            ? _value.emailVerified
            : emailVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        totpEnabled: null == totpEnabled
            ? _value.totpEnabled
            : totpEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountImpl implements _Account {
  const _$AccountImpl({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.hasPasskey,
    required this.hasPassword,
    required this.hasEmail,
    required this.emailVerified,
    required this.totpEnabled,
    required this.createdAt,
  });

  factory _$AccountImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountImplFromJson(json);

  @override
  final String id;
  @override
  final String handle;
  @override
  final String displayName;
  @override
  final bool hasPasskey;
  @override
  final bool hasPassword;
  @override
  final bool hasEmail;
  @override
  final bool emailVerified;
  @override
  final bool totpEnabled;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Account(id: $id, handle: $handle, displayName: $displayName, hasPasskey: $hasPasskey, hasPassword: $hasPassword, hasEmail: $hasEmail, emailVerified: $emailVerified, totpEnabled: $totpEnabled, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.hasPasskey, hasPasskey) ||
                other.hasPasskey == hasPasskey) &&
            (identical(other.hasPassword, hasPassword) ||
                other.hasPassword == hasPassword) &&
            (identical(other.hasEmail, hasEmail) ||
                other.hasEmail == hasEmail) &&
            (identical(other.emailVerified, emailVerified) ||
                other.emailVerified == emailVerified) &&
            (identical(other.totpEnabled, totpEnabled) ||
                other.totpEnabled == totpEnabled) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    handle,
    displayName,
    hasPasskey,
    hasPassword,
    hasEmail,
    emailVerified,
    totpEnabled,
    createdAt,
  );

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      __$$AccountImplCopyWithImpl<_$AccountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountImplToJson(this);
  }
}

abstract class _Account implements Account {
  const factory _Account({
    required final String id,
    required final String handle,
    required final String displayName,
    required final bool hasPasskey,
    required final bool hasPassword,
    required final bool hasEmail,
    required final bool emailVerified,
    required final bool totpEnabled,
    required final DateTime createdAt,
  }) = _$AccountImpl;

  factory _Account.fromJson(Map<String, dynamic> json) = _$AccountImpl.fromJson;

  @override
  String get id;
  @override
  String get handle;
  @override
  String get displayName;
  @override
  bool get hasPasskey;
  @override
  bool get hasPassword;
  @override
  bool get hasEmail;
  @override
  bool get emailVerified;
  @override
  bool get totpEnabled;
  @override
  DateTime get createdAt;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) {
  return _RegisterRequest.fromJson(json);
}

/// @nodoc
mixin _$RegisterRequest {
  String get handle => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get password => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;

  /// Device name (e.g., "John's iPhone 15")
  String? get deviceName => throw _privateConstructorUsedError;

  /// Device platform (e.g., "iOS", "Android")
  String? get devicePlatform => throw _privateConstructorUsedError;

  /// Serializes this RegisterRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RegisterRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegisterRequestCopyWith<RegisterRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegisterRequestCopyWith<$Res> {
  factory $RegisterRequestCopyWith(
    RegisterRequest value,
    $Res Function(RegisterRequest) then,
  ) = _$RegisterRequestCopyWithImpl<$Res, RegisterRequest>;
  @useResult
  $Res call({
    String handle,
    String displayName,
    String? password,
    String? email,
    String? deviceName,
    String? devicePlatform,
  });
}

/// @nodoc
class _$RegisterRequestCopyWithImpl<$Res, $Val extends RegisterRequest>
    implements $RegisterRequestCopyWith<$Res> {
  _$RegisterRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegisterRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? handle = null,
    Object? displayName = null,
    Object? password = freezed,
    Object? email = freezed,
    Object? deviceName = freezed,
    Object? devicePlatform = freezed,
  }) {
    return _then(
      _value.copyWith(
            handle: null == handle
                ? _value.handle
                : handle // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            password: freezed == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceName: freezed == deviceName
                ? _value.deviceName
                : deviceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            devicePlatform: freezed == devicePlatform
                ? _value.devicePlatform
                : devicePlatform // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RegisterRequestImplCopyWith<$Res>
    implements $RegisterRequestCopyWith<$Res> {
  factory _$$RegisterRequestImplCopyWith(
    _$RegisterRequestImpl value,
    $Res Function(_$RegisterRequestImpl) then,
  ) = __$$RegisterRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String handle,
    String displayName,
    String? password,
    String? email,
    String? deviceName,
    String? devicePlatform,
  });
}

/// @nodoc
class __$$RegisterRequestImplCopyWithImpl<$Res>
    extends _$RegisterRequestCopyWithImpl<$Res, _$RegisterRequestImpl>
    implements _$$RegisterRequestImplCopyWith<$Res> {
  __$$RegisterRequestImplCopyWithImpl(
    _$RegisterRequestImpl _value,
    $Res Function(_$RegisterRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RegisterRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? handle = null,
    Object? displayName = null,
    Object? password = freezed,
    Object? email = freezed,
    Object? deviceName = freezed,
    Object? devicePlatform = freezed,
  }) {
    return _then(
      _$RegisterRequestImpl(
        handle: null == handle
            ? _value.handle
            : handle // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        password: freezed == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceName: freezed == deviceName
            ? _value.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        devicePlatform: freezed == devicePlatform
            ? _value.devicePlatform
            : devicePlatform // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RegisterRequestImpl implements _RegisterRequest {
  const _$RegisterRequestImpl({
    required this.handle,
    required this.displayName,
    this.password,
    this.email,
    this.deviceName,
    this.devicePlatform,
  });

  factory _$RegisterRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegisterRequestImplFromJson(json);

  @override
  final String handle;
  @override
  final String displayName;
  @override
  final String? password;
  @override
  final String? email;

  /// Device name (e.g., "John's iPhone 15")
  @override
  final String? deviceName;

  /// Device platform (e.g., "iOS", "Android")
  @override
  final String? devicePlatform;

  @override
  String toString() {
    return 'RegisterRequest(handle: $handle, displayName: $displayName, password: $password, email: $email, deviceName: $deviceName, devicePlatform: $devicePlatform)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterRequestImpl &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.devicePlatform, devicePlatform) ||
                other.devicePlatform == devicePlatform));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    handle,
    displayName,
    password,
    email,
    deviceName,
    devicePlatform,
  );

  /// Create a copy of RegisterRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegisterRequestImplCopyWith<_$RegisterRequestImpl> get copyWith =>
      __$$RegisterRequestImplCopyWithImpl<_$RegisterRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RegisterRequestImplToJson(this);
  }
}

abstract class _RegisterRequest implements RegisterRequest {
  const factory _RegisterRequest({
    required final String handle,
    required final String displayName,
    final String? password,
    final String? email,
    final String? deviceName,
    final String? devicePlatform,
  }) = _$RegisterRequestImpl;

  factory _RegisterRequest.fromJson(Map<String, dynamic> json) =
      _$RegisterRequestImpl.fromJson;

  @override
  String get handle;
  @override
  String get displayName;
  @override
  String? get password;
  @override
  String? get email;

  /// Device name (e.g., "John's iPhone 15")
  @override
  String? get deviceName;

  /// Device platform (e.g., "iOS", "Android")
  @override
  String? get devicePlatform;

  /// Create a copy of RegisterRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegisterRequestImplCopyWith<_$RegisterRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) {
  return _LoginRequest.fromJson(json);
}

/// @nodoc
mixin _$LoginRequest {
  String get handle => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;
  String? get totpCode => throw _privateConstructorUsedError;

  /// Device name (e.g., "John's iPhone 15")
  String? get deviceName => throw _privateConstructorUsedError;

  /// Device platform (e.g., "iOS", "Android")
  String? get devicePlatform => throw _privateConstructorUsedError;

  /// Serializes this LoginRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginRequestCopyWith<LoginRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginRequestCopyWith<$Res> {
  factory $LoginRequestCopyWith(
    LoginRequest value,
    $Res Function(LoginRequest) then,
  ) = _$LoginRequestCopyWithImpl<$Res, LoginRequest>;
  @useResult
  $Res call({
    String handle,
    String password,
    String? totpCode,
    String? deviceName,
    String? devicePlatform,
  });
}

/// @nodoc
class _$LoginRequestCopyWithImpl<$Res, $Val extends LoginRequest>
    implements $LoginRequestCopyWith<$Res> {
  _$LoginRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? handle = null,
    Object? password = null,
    Object? totpCode = freezed,
    Object? deviceName = freezed,
    Object? devicePlatform = freezed,
  }) {
    return _then(
      _value.copyWith(
            handle: null == handle
                ? _value.handle
                : handle // ignore: cast_nullable_to_non_nullable
                      as String,
            password: null == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String,
            totpCode: freezed == totpCode
                ? _value.totpCode
                : totpCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceName: freezed == deviceName
                ? _value.deviceName
                : deviceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            devicePlatform: freezed == devicePlatform
                ? _value.devicePlatform
                : devicePlatform // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LoginRequestImplCopyWith<$Res>
    implements $LoginRequestCopyWith<$Res> {
  factory _$$LoginRequestImplCopyWith(
    _$LoginRequestImpl value,
    $Res Function(_$LoginRequestImpl) then,
  ) = __$$LoginRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String handle,
    String password,
    String? totpCode,
    String? deviceName,
    String? devicePlatform,
  });
}

/// @nodoc
class __$$LoginRequestImplCopyWithImpl<$Res>
    extends _$LoginRequestCopyWithImpl<$Res, _$LoginRequestImpl>
    implements _$$LoginRequestImplCopyWith<$Res> {
  __$$LoginRequestImplCopyWithImpl(
    _$LoginRequestImpl _value,
    $Res Function(_$LoginRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? handle = null,
    Object? password = null,
    Object? totpCode = freezed,
    Object? deviceName = freezed,
    Object? devicePlatform = freezed,
  }) {
    return _then(
      _$LoginRequestImpl(
        handle: null == handle
            ? _value.handle
            : handle // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        totpCode: freezed == totpCode
            ? _value.totpCode
            : totpCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceName: freezed == deviceName
            ? _value.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        devicePlatform: freezed == devicePlatform
            ? _value.devicePlatform
            : devicePlatform // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginRequestImpl implements _LoginRequest {
  const _$LoginRequestImpl({
    required this.handle,
    required this.password,
    this.totpCode,
    this.deviceName,
    this.devicePlatform,
  });

  factory _$LoginRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginRequestImplFromJson(json);

  @override
  final String handle;
  @override
  final String password;
  @override
  final String? totpCode;

  /// Device name (e.g., "John's iPhone 15")
  @override
  final String? deviceName;

  /// Device platform (e.g., "iOS", "Android")
  @override
  final String? devicePlatform;

  @override
  String toString() {
    return 'LoginRequest(handle: $handle, password: $password, totpCode: $totpCode, deviceName: $deviceName, devicePlatform: $devicePlatform)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginRequestImpl &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.totpCode, totpCode) ||
                other.totpCode == totpCode) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.devicePlatform, devicePlatform) ||
                other.devicePlatform == devicePlatform));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    handle,
    password,
    totpCode,
    deviceName,
    devicePlatform,
  );

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginRequestImplCopyWith<_$LoginRequestImpl> get copyWith =>
      __$$LoginRequestImplCopyWithImpl<_$LoginRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginRequestImplToJson(this);
  }
}

abstract class _LoginRequest implements LoginRequest {
  const factory _LoginRequest({
    required final String handle,
    required final String password,
    final String? totpCode,
    final String? deviceName,
    final String? devicePlatform,
  }) = _$LoginRequestImpl;

  factory _LoginRequest.fromJson(Map<String, dynamic> json) =
      _$LoginRequestImpl.fromJson;

  @override
  String get handle;
  @override
  String get password;
  @override
  String? get totpCode;

  /// Device name (e.g., "John's iPhone 15")
  @override
  String? get deviceName;

  /// Device platform (e.g., "iOS", "Android")
  @override
  String? get devicePlatform;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginRequestImplCopyWith<_$LoginRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) {
  return _AuthResponse.fromJson(json);
}

/// @nodoc
mixin _$AuthResponse {
  String get token => throw _privateConstructorUsedError;
  Account get account => throw _privateConstructorUsedError;

  /// Device ID for this session (used for device management)
  String get deviceId => throw _privateConstructorUsedError;

  /// Matrix credentials for cloud messaging (auto-created on registration)
  MatrixCredentials? get matrix => throw _privateConstructorUsedError;

  /// Serializes this AuthResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthResponseCopyWith<AuthResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResponseCopyWith<$Res> {
  factory $AuthResponseCopyWith(
    AuthResponse value,
    $Res Function(AuthResponse) then,
  ) = _$AuthResponseCopyWithImpl<$Res, AuthResponse>;
  @useResult
  $Res call({
    String token,
    Account account,
    String deviceId,
    MatrixCredentials? matrix,
  });

  $AccountCopyWith<$Res> get account;
  $MatrixCredentialsCopyWith<$Res>? get matrix;
}

/// @nodoc
class _$AuthResponseCopyWithImpl<$Res, $Val extends AuthResponse>
    implements $AuthResponseCopyWith<$Res> {
  _$AuthResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? account = null,
    Object? deviceId = null,
    Object? matrix = freezed,
  }) {
    return _then(
      _value.copyWith(
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
            account: null == account
                ? _value.account
                : account // ignore: cast_nullable_to_non_nullable
                      as Account,
            deviceId: null == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String,
            matrix: freezed == matrix
                ? _value.matrix
                : matrix // ignore: cast_nullable_to_non_nullable
                      as MatrixCredentials?,
          )
          as $Val,
    );
  }

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AccountCopyWith<$Res> get account {
    return $AccountCopyWith<$Res>(_value.account, (value) {
      return _then(_value.copyWith(account: value) as $Val);
    });
  }

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MatrixCredentialsCopyWith<$Res>? get matrix {
    if (_value.matrix == null) {
      return null;
    }

    return $MatrixCredentialsCopyWith<$Res>(_value.matrix!, (value) {
      return _then(_value.copyWith(matrix: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthResponseImplCopyWith<$Res>
    implements $AuthResponseCopyWith<$Res> {
  factory _$$AuthResponseImplCopyWith(
    _$AuthResponseImpl value,
    $Res Function(_$AuthResponseImpl) then,
  ) = __$$AuthResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String token,
    Account account,
    String deviceId,
    MatrixCredentials? matrix,
  });

  @override
  $AccountCopyWith<$Res> get account;
  @override
  $MatrixCredentialsCopyWith<$Res>? get matrix;
}

/// @nodoc
class __$$AuthResponseImplCopyWithImpl<$Res>
    extends _$AuthResponseCopyWithImpl<$Res, _$AuthResponseImpl>
    implements _$$AuthResponseImplCopyWith<$Res> {
  __$$AuthResponseImplCopyWithImpl(
    _$AuthResponseImpl _value,
    $Res Function(_$AuthResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? account = null,
    Object? deviceId = null,
    Object? matrix = freezed,
  }) {
    return _then(
      _$AuthResponseImpl(
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        account: null == account
            ? _value.account
            : account // ignore: cast_nullable_to_non_nullable
                  as Account,
        deviceId: null == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        matrix: freezed == matrix
            ? _value.matrix
            : matrix // ignore: cast_nullable_to_non_nullable
                  as MatrixCredentials?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthResponseImpl implements _AuthResponse {
  const _$AuthResponseImpl({
    required this.token,
    required this.account,
    required this.deviceId,
    this.matrix,
  });

  factory _$AuthResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthResponseImplFromJson(json);

  @override
  final String token;
  @override
  final Account account;

  /// Device ID for this session (used for device management)
  @override
  final String deviceId;

  /// Matrix credentials for cloud messaging (auto-created on registration)
  @override
  final MatrixCredentials? matrix;

  @override
  String toString() {
    return 'AuthResponse(token: $token, account: $account, deviceId: $deviceId, matrix: $matrix)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResponseImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.account, account) || other.account == account) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.matrix, matrix) || other.matrix == matrix));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, token, account, deviceId, matrix);

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      __$$AuthResponseImplCopyWithImpl<_$AuthResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthResponseImplToJson(this);
  }
}

abstract class _AuthResponse implements AuthResponse {
  const factory _AuthResponse({
    required final String token,
    required final Account account,
    required final String deviceId,
    final MatrixCredentials? matrix,
  }) = _$AuthResponseImpl;

  factory _AuthResponse.fromJson(Map<String, dynamic> json) =
      _$AuthResponseImpl.fromJson;

  @override
  String get token;
  @override
  Account get account;

  /// Device ID for this session (used for device management)
  @override
  String get deviceId;

  /// Matrix credentials for cloud messaging (auto-created on registration)
  @override
  MatrixCredentials? get matrix;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MatrixCredentials _$MatrixCredentialsFromJson(Map<String, dynamic> json) {
  return _MatrixCredentials.fromJson(json);
}

/// @nodoc
mixin _$MatrixCredentials {
  /// Full Matrix user ID (e.g., @handle:kinu.chat)
  String get userId => throw _privateConstructorUsedError;

  /// Matrix access token (empty if app should login separately)
  String get accessToken => throw _privateConstructorUsedError;

  /// Device ID
  String get deviceId => throw _privateConstructorUsedError;

  /// Homeserver URL
  String get homeserverUrl => throw _privateConstructorUsedError;

  /// Serializes this MatrixCredentials to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MatrixCredentials
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MatrixCredentialsCopyWith<MatrixCredentials> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MatrixCredentialsCopyWith<$Res> {
  factory $MatrixCredentialsCopyWith(
    MatrixCredentials value,
    $Res Function(MatrixCredentials) then,
  ) = _$MatrixCredentialsCopyWithImpl<$Res, MatrixCredentials>;
  @useResult
  $Res call({
    String userId,
    String accessToken,
    String deviceId,
    String homeserverUrl,
  });
}

/// @nodoc
class _$MatrixCredentialsCopyWithImpl<$Res, $Val extends MatrixCredentials>
    implements $MatrixCredentialsCopyWith<$Res> {
  _$MatrixCredentialsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MatrixCredentials
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? accessToken = null,
    Object? deviceId = null,
    Object? homeserverUrl = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceId: null == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String,
            homeserverUrl: null == homeserverUrl
                ? _value.homeserverUrl
                : homeserverUrl // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MatrixCredentialsImplCopyWith<$Res>
    implements $MatrixCredentialsCopyWith<$Res> {
  factory _$$MatrixCredentialsImplCopyWith(
    _$MatrixCredentialsImpl value,
    $Res Function(_$MatrixCredentialsImpl) then,
  ) = __$$MatrixCredentialsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String accessToken,
    String deviceId,
    String homeserverUrl,
  });
}

/// @nodoc
class __$$MatrixCredentialsImplCopyWithImpl<$Res>
    extends _$MatrixCredentialsCopyWithImpl<$Res, _$MatrixCredentialsImpl>
    implements _$$MatrixCredentialsImplCopyWith<$Res> {
  __$$MatrixCredentialsImplCopyWithImpl(
    _$MatrixCredentialsImpl _value,
    $Res Function(_$MatrixCredentialsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MatrixCredentials
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? accessToken = null,
    Object? deviceId = null,
    Object? homeserverUrl = null,
  }) {
    return _then(
      _$MatrixCredentialsImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        homeserverUrl: null == homeserverUrl
            ? _value.homeserverUrl
            : homeserverUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MatrixCredentialsImpl implements _MatrixCredentials {
  const _$MatrixCredentialsImpl({
    required this.userId,
    required this.accessToken,
    required this.deviceId,
    required this.homeserverUrl,
  });

  factory _$MatrixCredentialsImpl.fromJson(Map<String, dynamic> json) =>
      _$$MatrixCredentialsImplFromJson(json);

  /// Full Matrix user ID (e.g., @handle:kinu.chat)
  @override
  final String userId;

  /// Matrix access token (empty if app should login separately)
  @override
  final String accessToken;

  /// Device ID
  @override
  final String deviceId;

  /// Homeserver URL
  @override
  final String homeserverUrl;

  @override
  String toString() {
    return 'MatrixCredentials(userId: $userId, accessToken: $accessToken, deviceId: $deviceId, homeserverUrl: $homeserverUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MatrixCredentialsImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.homeserverUrl, homeserverUrl) ||
                other.homeserverUrl == homeserverUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, accessToken, deviceId, homeserverUrl);

  /// Create a copy of MatrixCredentials
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MatrixCredentialsImplCopyWith<_$MatrixCredentialsImpl> get copyWith =>
      __$$MatrixCredentialsImplCopyWithImpl<_$MatrixCredentialsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MatrixCredentialsImplToJson(this);
  }
}

abstract class _MatrixCredentials implements MatrixCredentials {
  const factory _MatrixCredentials({
    required final String userId,
    required final String accessToken,
    required final String deviceId,
    required final String homeserverUrl,
  }) = _$MatrixCredentialsImpl;

  factory _MatrixCredentials.fromJson(Map<String, dynamic> json) =
      _$MatrixCredentialsImpl.fromJson;

  /// Full Matrix user ID (e.g., @handle:kinu.chat)
  @override
  String get userId;

  /// Matrix access token (empty if app should login separately)
  @override
  String get accessToken;

  /// Device ID
  @override
  String get deviceId;

  /// Homeserver URL
  @override
  String get homeserverUrl;

  /// Create a copy of MatrixCredentials
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MatrixCredentialsImplCopyWith<_$MatrixCredentialsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HandleCheckResponse _$HandleCheckResponseFromJson(Map<String, dynamic> json) {
  return _HandleCheckResponse.fromJson(json);
}

/// @nodoc
mixin _$HandleCheckResponse {
  bool get available => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;

  /// Serializes this HandleCheckResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HandleCheckResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HandleCheckResponseCopyWith<HandleCheckResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HandleCheckResponseCopyWith<$Res> {
  factory $HandleCheckResponseCopyWith(
    HandleCheckResponse value,
    $Res Function(HandleCheckResponse) then,
  ) = _$HandleCheckResponseCopyWithImpl<$Res, HandleCheckResponse>;
  @useResult
  $Res call({bool available, String handle});
}

/// @nodoc
class _$HandleCheckResponseCopyWithImpl<$Res, $Val extends HandleCheckResponse>
    implements $HandleCheckResponseCopyWith<$Res> {
  _$HandleCheckResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HandleCheckResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? available = null, Object? handle = null}) {
    return _then(
      _value.copyWith(
            available: null == available
                ? _value.available
                : available // ignore: cast_nullable_to_non_nullable
                      as bool,
            handle: null == handle
                ? _value.handle
                : handle // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HandleCheckResponseImplCopyWith<$Res>
    implements $HandleCheckResponseCopyWith<$Res> {
  factory _$$HandleCheckResponseImplCopyWith(
    _$HandleCheckResponseImpl value,
    $Res Function(_$HandleCheckResponseImpl) then,
  ) = __$$HandleCheckResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool available, String handle});
}

/// @nodoc
class __$$HandleCheckResponseImplCopyWithImpl<$Res>
    extends _$HandleCheckResponseCopyWithImpl<$Res, _$HandleCheckResponseImpl>
    implements _$$HandleCheckResponseImplCopyWith<$Res> {
  __$$HandleCheckResponseImplCopyWithImpl(
    _$HandleCheckResponseImpl _value,
    $Res Function(_$HandleCheckResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HandleCheckResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? available = null, Object? handle = null}) {
    return _then(
      _$HandleCheckResponseImpl(
        available: null == available
            ? _value.available
            : available // ignore: cast_nullable_to_non_nullable
                  as bool,
        handle: null == handle
            ? _value.handle
            : handle // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HandleCheckResponseImpl implements _HandleCheckResponse {
  const _$HandleCheckResponseImpl({
    required this.available,
    required this.handle,
  });

  factory _$HandleCheckResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HandleCheckResponseImplFromJson(json);

  @override
  final bool available;
  @override
  final String handle;

  @override
  String toString() {
    return 'HandleCheckResponse(available: $available, handle: $handle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HandleCheckResponseImpl &&
            (identical(other.available, available) ||
                other.available == available) &&
            (identical(other.handle, handle) || other.handle == handle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, available, handle);

  /// Create a copy of HandleCheckResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HandleCheckResponseImplCopyWith<_$HandleCheckResponseImpl> get copyWith =>
      __$$HandleCheckResponseImplCopyWithImpl<_$HandleCheckResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HandleCheckResponseImplToJson(this);
  }
}

abstract class _HandleCheckResponse implements HandleCheckResponse {
  const factory _HandleCheckResponse({
    required final bool available,
    required final String handle,
  }) = _$HandleCheckResponseImpl;

  factory _HandleCheckResponse.fromJson(Map<String, dynamic> json) =
      _$HandleCheckResponseImpl.fromJson;

  @override
  bool get available;
  @override
  String get handle;

  /// Create a copy of HandleCheckResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HandleCheckResponseImplCopyWith<_$HandleCheckResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TotpSetupResponse _$TotpSetupResponseFromJson(Map<String, dynamic> json) {
  return _TotpSetupResponse.fromJson(json);
}

/// @nodoc
mixin _$TotpSetupResponse {
  String get secret => throw _privateConstructorUsedError;
  @JsonKey(name: 'otpauth_url')
  String get otpauthUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'qr_code_base64')
  String get qrCodeBase64 => throw _privateConstructorUsedError;

  /// Serializes this TotpSetupResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TotpSetupResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TotpSetupResponseCopyWith<TotpSetupResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TotpSetupResponseCopyWith<$Res> {
  factory $TotpSetupResponseCopyWith(
    TotpSetupResponse value,
    $Res Function(TotpSetupResponse) then,
  ) = _$TotpSetupResponseCopyWithImpl<$Res, TotpSetupResponse>;
  @useResult
  $Res call({
    String secret,
    @JsonKey(name: 'otpauth_url') String otpauthUrl,
    @JsonKey(name: 'qr_code_base64') String qrCodeBase64,
  });
}

/// @nodoc
class _$TotpSetupResponseCopyWithImpl<$Res, $Val extends TotpSetupResponse>
    implements $TotpSetupResponseCopyWith<$Res> {
  _$TotpSetupResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TotpSetupResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? secret = null,
    Object? otpauthUrl = null,
    Object? qrCodeBase64 = null,
  }) {
    return _then(
      _value.copyWith(
            secret: null == secret
                ? _value.secret
                : secret // ignore: cast_nullable_to_non_nullable
                      as String,
            otpauthUrl: null == otpauthUrl
                ? _value.otpauthUrl
                : otpauthUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            qrCodeBase64: null == qrCodeBase64
                ? _value.qrCodeBase64
                : qrCodeBase64 // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TotpSetupResponseImplCopyWith<$Res>
    implements $TotpSetupResponseCopyWith<$Res> {
  factory _$$TotpSetupResponseImplCopyWith(
    _$TotpSetupResponseImpl value,
    $Res Function(_$TotpSetupResponseImpl) then,
  ) = __$$TotpSetupResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String secret,
    @JsonKey(name: 'otpauth_url') String otpauthUrl,
    @JsonKey(name: 'qr_code_base64') String qrCodeBase64,
  });
}

/// @nodoc
class __$$TotpSetupResponseImplCopyWithImpl<$Res>
    extends _$TotpSetupResponseCopyWithImpl<$Res, _$TotpSetupResponseImpl>
    implements _$$TotpSetupResponseImplCopyWith<$Res> {
  __$$TotpSetupResponseImplCopyWithImpl(
    _$TotpSetupResponseImpl _value,
    $Res Function(_$TotpSetupResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TotpSetupResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? secret = null,
    Object? otpauthUrl = null,
    Object? qrCodeBase64 = null,
  }) {
    return _then(
      _$TotpSetupResponseImpl(
        secret: null == secret
            ? _value.secret
            : secret // ignore: cast_nullable_to_non_nullable
                  as String,
        otpauthUrl: null == otpauthUrl
            ? _value.otpauthUrl
            : otpauthUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        qrCodeBase64: null == qrCodeBase64
            ? _value.qrCodeBase64
            : qrCodeBase64 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TotpSetupResponseImpl implements _TotpSetupResponse {
  const _$TotpSetupResponseImpl({
    required this.secret,
    @JsonKey(name: 'otpauth_url') required this.otpauthUrl,
    @JsonKey(name: 'qr_code_base64') required this.qrCodeBase64,
  });

  factory _$TotpSetupResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$TotpSetupResponseImplFromJson(json);

  @override
  final String secret;
  @override
  @JsonKey(name: 'otpauth_url')
  final String otpauthUrl;
  @override
  @JsonKey(name: 'qr_code_base64')
  final String qrCodeBase64;

  @override
  String toString() {
    return 'TotpSetupResponse(secret: $secret, otpauthUrl: $otpauthUrl, qrCodeBase64: $qrCodeBase64)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TotpSetupResponseImpl &&
            (identical(other.secret, secret) || other.secret == secret) &&
            (identical(other.otpauthUrl, otpauthUrl) ||
                other.otpauthUrl == otpauthUrl) &&
            (identical(other.qrCodeBase64, qrCodeBase64) ||
                other.qrCodeBase64 == qrCodeBase64));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, secret, otpauthUrl, qrCodeBase64);

  /// Create a copy of TotpSetupResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TotpSetupResponseImplCopyWith<_$TotpSetupResponseImpl> get copyWith =>
      __$$TotpSetupResponseImplCopyWithImpl<_$TotpSetupResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TotpSetupResponseImplToJson(this);
  }
}

abstract class _TotpSetupResponse implements TotpSetupResponse {
  const factory _TotpSetupResponse({
    required final String secret,
    @JsonKey(name: 'otpauth_url') required final String otpauthUrl,
    @JsonKey(name: 'qr_code_base64') required final String qrCodeBase64,
  }) = _$TotpSetupResponseImpl;

  factory _TotpSetupResponse.fromJson(Map<String, dynamic> json) =
      _$TotpSetupResponseImpl.fromJson;

  @override
  String get secret;
  @override
  @JsonKey(name: 'otpauth_url')
  String get otpauthUrl;
  @override
  @JsonKey(name: 'qr_code_base64')
  String get qrCodeBase64;

  /// Create a copy of TotpSetupResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TotpSetupResponseImplCopyWith<_$TotpSetupResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BackupCodesResponse _$BackupCodesResponseFromJson(Map<String, dynamic> json) {
  return _BackupCodesResponse.fromJson(json);
}

/// @nodoc
mixin _$BackupCodesResponse {
  List<String> get codes => throw _privateConstructorUsedError;

  /// Serializes this BackupCodesResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BackupCodesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BackupCodesResponseCopyWith<BackupCodesResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupCodesResponseCopyWith<$Res> {
  factory $BackupCodesResponseCopyWith(
    BackupCodesResponse value,
    $Res Function(BackupCodesResponse) then,
  ) = _$BackupCodesResponseCopyWithImpl<$Res, BackupCodesResponse>;
  @useResult
  $Res call({List<String> codes});
}

/// @nodoc
class _$BackupCodesResponseCopyWithImpl<$Res, $Val extends BackupCodesResponse>
    implements $BackupCodesResponseCopyWith<$Res> {
  _$BackupCodesResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BackupCodesResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? codes = null}) {
    return _then(
      _value.copyWith(
            codes: null == codes
                ? _value.codes
                : codes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BackupCodesResponseImplCopyWith<$Res>
    implements $BackupCodesResponseCopyWith<$Res> {
  factory _$$BackupCodesResponseImplCopyWith(
    _$BackupCodesResponseImpl value,
    $Res Function(_$BackupCodesResponseImpl) then,
  ) = __$$BackupCodesResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> codes});
}

/// @nodoc
class __$$BackupCodesResponseImplCopyWithImpl<$Res>
    extends _$BackupCodesResponseCopyWithImpl<$Res, _$BackupCodesResponseImpl>
    implements _$$BackupCodesResponseImplCopyWith<$Res> {
  __$$BackupCodesResponseImplCopyWithImpl(
    _$BackupCodesResponseImpl _value,
    $Res Function(_$BackupCodesResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BackupCodesResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? codes = null}) {
    return _then(
      _$BackupCodesResponseImpl(
        codes: null == codes
            ? _value._codes
            : codes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupCodesResponseImpl implements _BackupCodesResponse {
  const _$BackupCodesResponseImpl({required final List<String> codes})
    : _codes = codes;

  factory _$BackupCodesResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupCodesResponseImplFromJson(json);

  final List<String> _codes;
  @override
  List<String> get codes {
    if (_codes is EqualUnmodifiableListView) return _codes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_codes);
  }

  @override
  String toString() {
    return 'BackupCodesResponse(codes: $codes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupCodesResponseImpl &&
            const DeepCollectionEquality().equals(other._codes, _codes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_codes));

  /// Create a copy of BackupCodesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupCodesResponseImplCopyWith<_$BackupCodesResponseImpl> get copyWith =>
      __$$BackupCodesResponseImplCopyWithImpl<_$BackupCodesResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupCodesResponseImplToJson(this);
  }
}

abstract class _BackupCodesResponse implements BackupCodesResponse {
  const factory _BackupCodesResponse({required final List<String> codes}) =
      _$BackupCodesResponseImpl;

  factory _BackupCodesResponse.fromJson(Map<String, dynamic> json) =
      _$BackupCodesResponseImpl.fromJson;

  @override
  List<String> get codes;

  /// Create a copy of BackupCodesResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackupCodesResponseImplCopyWith<_$BackupCodesResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) {
  return _ApiError.fromJson(json);
}

/// @nodoc
mixin _$ApiError {
  String get error => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;

  /// Serializes this ApiError to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApiErrorCopyWith<ApiError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiErrorCopyWith<$Res> {
  factory $ApiErrorCopyWith(ApiError value, $Res Function(ApiError) then) =
      _$ApiErrorCopyWithImpl<$Res, ApiError>;
  @useResult
  $Res call({String error, String code});
}

/// @nodoc
class _$ApiErrorCopyWithImpl<$Res, $Val extends ApiError>
    implements $ApiErrorCopyWith<$Res> {
  _$ApiErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? error = null, Object? code = null}) {
    return _then(
      _value.copyWith(
            error: null == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ApiErrorImplCopyWith<$Res>
    implements $ApiErrorCopyWith<$Res> {
  factory _$$ApiErrorImplCopyWith(
    _$ApiErrorImpl value,
    $Res Function(_$ApiErrorImpl) then,
  ) = __$$ApiErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String error, String code});
}

/// @nodoc
class __$$ApiErrorImplCopyWithImpl<$Res>
    extends _$ApiErrorCopyWithImpl<$Res, _$ApiErrorImpl>
    implements _$$ApiErrorImplCopyWith<$Res> {
  __$$ApiErrorImplCopyWithImpl(
    _$ApiErrorImpl _value,
    $Res Function(_$ApiErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? error = null, Object? code = null}) {
    return _then(
      _$ApiErrorImpl(
        error: null == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiErrorImpl implements _ApiError {
  const _$ApiErrorImpl({required this.error, required this.code});

  factory _$ApiErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiErrorImplFromJson(json);

  @override
  final String error;
  @override
  final String code;

  @override
  String toString() {
    return 'ApiError(error: $error, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiErrorImpl &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.code, code) || other.code == code));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, error, code);

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiErrorImplCopyWith<_$ApiErrorImpl> get copyWith =>
      __$$ApiErrorImplCopyWithImpl<_$ApiErrorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiErrorImplToJson(this);
  }
}

abstract class _ApiError implements ApiError {
  const factory _ApiError({
    required final String error,
    required final String code,
  }) = _$ApiErrorImpl;

  factory _ApiError.fromJson(Map<String, dynamic> json) =
      _$ApiErrorImpl.fromJson;

  @override
  String get error;
  @override
  String get code;

  /// Create a copy of ApiError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiErrorImplCopyWith<_$ApiErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) {
  return _DeviceInfo.fromJson(json);
}

/// @nodoc
mixin _$DeviceInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  DateTime get lastActiveAt => throw _privateConstructorUsedError;
  bool get isCurrent => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;

  /// Serializes this DeviceInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceInfoCopyWith<DeviceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceInfoCopyWith<$Res> {
  factory $DeviceInfoCopyWith(
    DeviceInfo value,
    $Res Function(DeviceInfo) then,
  ) = _$DeviceInfoCopyWithImpl<$Res, DeviceInfo>;
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    DateTime lastActiveAt,
    bool isCurrent,
    String? location,
  });
}

/// @nodoc
class _$DeviceInfoCopyWithImpl<$Res, $Val extends DeviceInfo>
    implements $DeviceInfoCopyWith<$Res> {
  _$DeviceInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? lastActiveAt = null,
    Object? isCurrent = null,
    Object? location = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            lastActiveAt: null == lastActiveAt
                ? _value.lastActiveAt
                : lastActiveAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isCurrent: null == isCurrent
                ? _value.isCurrent
                : isCurrent // ignore: cast_nullable_to_non_nullable
                      as bool,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeviceInfoImplCopyWith<$Res>
    implements $DeviceInfoCopyWith<$Res> {
  factory _$$DeviceInfoImplCopyWith(
    _$DeviceInfoImpl value,
    $Res Function(_$DeviceInfoImpl) then,
  ) = __$$DeviceInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    DateTime lastActiveAt,
    bool isCurrent,
    String? location,
  });
}

/// @nodoc
class __$$DeviceInfoImplCopyWithImpl<$Res>
    extends _$DeviceInfoCopyWithImpl<$Res, _$DeviceInfoImpl>
    implements _$$DeviceInfoImplCopyWith<$Res> {
  __$$DeviceInfoImplCopyWithImpl(
    _$DeviceInfoImpl _value,
    $Res Function(_$DeviceInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? lastActiveAt = null,
    Object? isCurrent = null,
    Object? location = freezed,
  }) {
    return _then(
      _$DeviceInfoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        lastActiveAt: null == lastActiveAt
            ? _value.lastActiveAt
            : lastActiveAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isCurrent: null == isCurrent
            ? _value.isCurrent
            : isCurrent // ignore: cast_nullable_to_non_nullable
                  as bool,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceInfoImpl implements _DeviceInfo {
  const _$DeviceInfoImpl({
    required this.id,
    required this.name,
    required this.type,
    required this.lastActiveAt,
    required this.isCurrent,
    this.location,
  });

  factory _$DeviceInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String type;
  @override
  final DateTime lastActiveAt;
  @override
  final bool isCurrent;
  @override
  final String? location;

  @override
  String toString() {
    return 'DeviceInfo(id: $id, name: $name, type: $type, lastActiveAt: $lastActiveAt, isCurrent: $isCurrent, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt) &&
            (identical(other.isCurrent, isCurrent) ||
                other.isCurrent == isCurrent) &&
            (identical(other.location, location) ||
                other.location == location));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    type,
    lastActiveAt,
    isCurrent,
    location,
  );

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceInfoImplCopyWith<_$DeviceInfoImpl> get copyWith =>
      __$$DeviceInfoImplCopyWithImpl<_$DeviceInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceInfoImplToJson(this);
  }
}

abstract class _DeviceInfo implements DeviceInfo {
  const factory _DeviceInfo({
    required final String id,
    required final String name,
    required final String type,
    required final DateTime lastActiveAt,
    required final bool isCurrent,
    final String? location,
  }) = _$DeviceInfoImpl;

  factory _DeviceInfo.fromJson(Map<String, dynamic> json) =
      _$DeviceInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get type;
  @override
  DateTime get lastActiveAt;
  @override
  bool get isCurrent;
  @override
  String? get location;

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceInfoImplCopyWith<_$DeviceInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DataExportResponse _$DataExportResponseFromJson(Map<String, dynamic> json) {
  return _DataExportResponse.fromJson(json);
}

/// @nodoc
mixin _$DataExportResponse {
  DateTime get exportedAt => throw _privateConstructorUsedError;
  AccountExportData get account => throw _privateConstructorUsedError;
  List<DeviceExportData> get devices => throw _privateConstructorUsedError;
  SecurityExportData get security => throw _privateConstructorUsedError;

  /// Serializes this DataExportResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DataExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataExportResponseCopyWith<DataExportResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataExportResponseCopyWith<$Res> {
  factory $DataExportResponseCopyWith(
    DataExportResponse value,
    $Res Function(DataExportResponse) then,
  ) = _$DataExportResponseCopyWithImpl<$Res, DataExportResponse>;
  @useResult
  $Res call({
    DateTime exportedAt,
    AccountExportData account,
    List<DeviceExportData> devices,
    SecurityExportData security,
  });

  $AccountExportDataCopyWith<$Res> get account;
  $SecurityExportDataCopyWith<$Res> get security;
}

/// @nodoc
class _$DataExportResponseCopyWithImpl<$Res, $Val extends DataExportResponse>
    implements $DataExportResponseCopyWith<$Res> {
  _$DataExportResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DataExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exportedAt = null,
    Object? account = null,
    Object? devices = null,
    Object? security = null,
  }) {
    return _then(
      _value.copyWith(
            exportedAt: null == exportedAt
                ? _value.exportedAt
                : exportedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            account: null == account
                ? _value.account
                : account // ignore: cast_nullable_to_non_nullable
                      as AccountExportData,
            devices: null == devices
                ? _value.devices
                : devices // ignore: cast_nullable_to_non_nullable
                      as List<DeviceExportData>,
            security: null == security
                ? _value.security
                : security // ignore: cast_nullable_to_non_nullable
                      as SecurityExportData,
          )
          as $Val,
    );
  }

  /// Create a copy of DataExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AccountExportDataCopyWith<$Res> get account {
    return $AccountExportDataCopyWith<$Res>(_value.account, (value) {
      return _then(_value.copyWith(account: value) as $Val);
    });
  }

  /// Create a copy of DataExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SecurityExportDataCopyWith<$Res> get security {
    return $SecurityExportDataCopyWith<$Res>(_value.security, (value) {
      return _then(_value.copyWith(security: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DataExportResponseImplCopyWith<$Res>
    implements $DataExportResponseCopyWith<$Res> {
  factory _$$DataExportResponseImplCopyWith(
    _$DataExportResponseImpl value,
    $Res Function(_$DataExportResponseImpl) then,
  ) = __$$DataExportResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime exportedAt,
    AccountExportData account,
    List<DeviceExportData> devices,
    SecurityExportData security,
  });

  @override
  $AccountExportDataCopyWith<$Res> get account;
  @override
  $SecurityExportDataCopyWith<$Res> get security;
}

/// @nodoc
class __$$DataExportResponseImplCopyWithImpl<$Res>
    extends _$DataExportResponseCopyWithImpl<$Res, _$DataExportResponseImpl>
    implements _$$DataExportResponseImplCopyWith<$Res> {
  __$$DataExportResponseImplCopyWithImpl(
    _$DataExportResponseImpl _value,
    $Res Function(_$DataExportResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DataExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exportedAt = null,
    Object? account = null,
    Object? devices = null,
    Object? security = null,
  }) {
    return _then(
      _$DataExportResponseImpl(
        exportedAt: null == exportedAt
            ? _value.exportedAt
            : exportedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        account: null == account
            ? _value.account
            : account // ignore: cast_nullable_to_non_nullable
                  as AccountExportData,
        devices: null == devices
            ? _value._devices
            : devices // ignore: cast_nullable_to_non_nullable
                  as List<DeviceExportData>,
        security: null == security
            ? _value.security
            : security // ignore: cast_nullable_to_non_nullable
                  as SecurityExportData,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DataExportResponseImpl implements _DataExportResponse {
  const _$DataExportResponseImpl({
    required this.exportedAt,
    required this.account,
    required final List<DeviceExportData> devices,
    required this.security,
  }) : _devices = devices;

  factory _$DataExportResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataExportResponseImplFromJson(json);

  @override
  final DateTime exportedAt;
  @override
  final AccountExportData account;
  final List<DeviceExportData> _devices;
  @override
  List<DeviceExportData> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  @override
  final SecurityExportData security;

  @override
  String toString() {
    return 'DataExportResponse(exportedAt: $exportedAt, account: $account, devices: $devices, security: $security)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataExportResponseImpl &&
            (identical(other.exportedAt, exportedAt) ||
                other.exportedAt == exportedAt) &&
            (identical(other.account, account) || other.account == account) &&
            const DeepCollectionEquality().equals(other._devices, _devices) &&
            (identical(other.security, security) ||
                other.security == security));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    exportedAt,
    account,
    const DeepCollectionEquality().hash(_devices),
    security,
  );

  /// Create a copy of DataExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataExportResponseImplCopyWith<_$DataExportResponseImpl> get copyWith =>
      __$$DataExportResponseImplCopyWithImpl<_$DataExportResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DataExportResponseImplToJson(this);
  }
}

abstract class _DataExportResponse implements DataExportResponse {
  const factory _DataExportResponse({
    required final DateTime exportedAt,
    required final AccountExportData account,
    required final List<DeviceExportData> devices,
    required final SecurityExportData security,
  }) = _$DataExportResponseImpl;

  factory _DataExportResponse.fromJson(Map<String, dynamic> json) =
      _$DataExportResponseImpl.fromJson;

  @override
  DateTime get exportedAt;
  @override
  AccountExportData get account;
  @override
  List<DeviceExportData> get devices;
  @override
  SecurityExportData get security;

  /// Create a copy of DataExportResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataExportResponseImplCopyWith<_$DataExportResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AccountExportData _$AccountExportDataFromJson(Map<String, dynamic> json) {
  return _AccountExportData.fromJson(json);
}

/// @nodoc
mixin _$AccountExportData {
  String get id => throw _privateConstructorUsedError;
  String get handle => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  bool get hasEmail => throw _privateConstructorUsedError;
  bool get emailVerified => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AccountExportData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccountExportData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountExportDataCopyWith<AccountExportData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountExportDataCopyWith<$Res> {
  factory $AccountExportDataCopyWith(
    AccountExportData value,
    $Res Function(AccountExportData) then,
  ) = _$AccountExportDataCopyWithImpl<$Res, AccountExportData>;
  @useResult
  $Res call({
    String id,
    String handle,
    String displayName,
    bool hasEmail,
    bool emailVerified,
    String createdAt,
  });
}

/// @nodoc
class _$AccountExportDataCopyWithImpl<$Res, $Val extends AccountExportData>
    implements $AccountExportDataCopyWith<$Res> {
  _$AccountExportDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountExportData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handle = null,
    Object? displayName = null,
    Object? hasEmail = null,
    Object? emailVerified = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            handle: null == handle
                ? _value.handle
                : handle // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            hasEmail: null == hasEmail
                ? _value.hasEmail
                : hasEmail // ignore: cast_nullable_to_non_nullable
                      as bool,
            emailVerified: null == emailVerified
                ? _value.emailVerified
                : emailVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountExportDataImplCopyWith<$Res>
    implements $AccountExportDataCopyWith<$Res> {
  factory _$$AccountExportDataImplCopyWith(
    _$AccountExportDataImpl value,
    $Res Function(_$AccountExportDataImpl) then,
  ) = __$$AccountExportDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String handle,
    String displayName,
    bool hasEmail,
    bool emailVerified,
    String createdAt,
  });
}

/// @nodoc
class __$$AccountExportDataImplCopyWithImpl<$Res>
    extends _$AccountExportDataCopyWithImpl<$Res, _$AccountExportDataImpl>
    implements _$$AccountExportDataImplCopyWith<$Res> {
  __$$AccountExportDataImplCopyWithImpl(
    _$AccountExportDataImpl _value,
    $Res Function(_$AccountExportDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountExportData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? handle = null,
    Object? displayName = null,
    Object? hasEmail = null,
    Object? emailVerified = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$AccountExportDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        handle: null == handle
            ? _value.handle
            : handle // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        hasEmail: null == hasEmail
            ? _value.hasEmail
            : hasEmail // ignore: cast_nullable_to_non_nullable
                  as bool,
        emailVerified: null == emailVerified
            ? _value.emailVerified
            : emailVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountExportDataImpl implements _AccountExportData {
  const _$AccountExportDataImpl({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.hasEmail,
    required this.emailVerified,
    required this.createdAt,
  });

  factory _$AccountExportDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountExportDataImplFromJson(json);

  @override
  final String id;
  @override
  final String handle;
  @override
  final String displayName;
  @override
  final bool hasEmail;
  @override
  final bool emailVerified;
  @override
  final String createdAt;

  @override
  String toString() {
    return 'AccountExportData(id: $id, handle: $handle, displayName: $displayName, hasEmail: $hasEmail, emailVerified: $emailVerified, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountExportDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.hasEmail, hasEmail) ||
                other.hasEmail == hasEmail) &&
            (identical(other.emailVerified, emailVerified) ||
                other.emailVerified == emailVerified) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    handle,
    displayName,
    hasEmail,
    emailVerified,
    createdAt,
  );

  /// Create a copy of AccountExportData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountExportDataImplCopyWith<_$AccountExportDataImpl> get copyWith =>
      __$$AccountExportDataImplCopyWithImpl<_$AccountExportDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountExportDataImplToJson(this);
  }
}

abstract class _AccountExportData implements AccountExportData {
  const factory _AccountExportData({
    required final String id,
    required final String handle,
    required final String displayName,
    required final bool hasEmail,
    required final bool emailVerified,
    required final String createdAt,
  }) = _$AccountExportDataImpl;

  factory _AccountExportData.fromJson(Map<String, dynamic> json) =
      _$AccountExportDataImpl.fromJson;

  @override
  String get id;
  @override
  String get handle;
  @override
  String get displayName;
  @override
  bool get hasEmail;
  @override
  bool get emailVerified;
  @override
  String get createdAt;

  /// Create a copy of AccountExportData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountExportDataImplCopyWith<_$AccountExportDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeviceExportData _$DeviceExportDataFromJson(Map<String, dynamic> json) {
  return _DeviceExportData.fromJson(json);
}

/// @nodoc
mixin _$DeviceExportData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get platform => throw _privateConstructorUsedError;
  String get firstSeen => throw _privateConstructorUsedError;
  String get lastActive => throw _privateConstructorUsedError;

  /// Serializes this DeviceExportData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeviceExportData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceExportDataCopyWith<DeviceExportData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceExportDataCopyWith<$Res> {
  factory $DeviceExportDataCopyWith(
    DeviceExportData value,
    $Res Function(DeviceExportData) then,
  ) = _$DeviceExportDataCopyWithImpl<$Res, DeviceExportData>;
  @useResult
  $Res call({
    String id,
    String name,
    String platform,
    String firstSeen,
    String lastActive,
  });
}

/// @nodoc
class _$DeviceExportDataCopyWithImpl<$Res, $Val extends DeviceExportData>
    implements $DeviceExportDataCopyWith<$Res> {
  _$DeviceExportDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceExportData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? platform = null,
    Object? firstSeen = null,
    Object? lastActive = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            platform: null == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as String,
            firstSeen: null == firstSeen
                ? _value.firstSeen
                : firstSeen // ignore: cast_nullable_to_non_nullable
                      as String,
            lastActive: null == lastActive
                ? _value.lastActive
                : lastActive // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeviceExportDataImplCopyWith<$Res>
    implements $DeviceExportDataCopyWith<$Res> {
  factory _$$DeviceExportDataImplCopyWith(
    _$DeviceExportDataImpl value,
    $Res Function(_$DeviceExportDataImpl) then,
  ) = __$$DeviceExportDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String platform,
    String firstSeen,
    String lastActive,
  });
}

/// @nodoc
class __$$DeviceExportDataImplCopyWithImpl<$Res>
    extends _$DeviceExportDataCopyWithImpl<$Res, _$DeviceExportDataImpl>
    implements _$$DeviceExportDataImplCopyWith<$Res> {
  __$$DeviceExportDataImplCopyWithImpl(
    _$DeviceExportDataImpl _value,
    $Res Function(_$DeviceExportDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DeviceExportData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? platform = null,
    Object? firstSeen = null,
    Object? lastActive = null,
  }) {
    return _then(
      _$DeviceExportDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as String,
        firstSeen: null == firstSeen
            ? _value.firstSeen
            : firstSeen // ignore: cast_nullable_to_non_nullable
                  as String,
        lastActive: null == lastActive
            ? _value.lastActive
            : lastActive // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceExportDataImpl implements _DeviceExportData {
  const _$DeviceExportDataImpl({
    required this.id,
    required this.name,
    required this.platform,
    required this.firstSeen,
    required this.lastActive,
  });

  factory _$DeviceExportDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceExportDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String platform;
  @override
  final String firstSeen;
  @override
  final String lastActive;

  @override
  String toString() {
    return 'DeviceExportData(id: $id, name: $name, platform: $platform, firstSeen: $firstSeen, lastActive: $lastActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceExportDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.firstSeen, firstSeen) ||
                other.firstSeen == firstSeen) &&
            (identical(other.lastActive, lastActive) ||
                other.lastActive == lastActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, platform, firstSeen, lastActive);

  /// Create a copy of DeviceExportData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceExportDataImplCopyWith<_$DeviceExportDataImpl> get copyWith =>
      __$$DeviceExportDataImplCopyWithImpl<_$DeviceExportDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceExportDataImplToJson(this);
  }
}

abstract class _DeviceExportData implements DeviceExportData {
  const factory _DeviceExportData({
    required final String id,
    required final String name,
    required final String platform,
    required final String firstSeen,
    required final String lastActive,
  }) = _$DeviceExportDataImpl;

  factory _DeviceExportData.fromJson(Map<String, dynamic> json) =
      _$DeviceExportDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get platform;
  @override
  String get firstSeen;
  @override
  String get lastActive;

  /// Create a copy of DeviceExportData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceExportDataImplCopyWith<_$DeviceExportDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SecurityExportData _$SecurityExportDataFromJson(Map<String, dynamic> json) {
  return _SecurityExportData.fromJson(json);
}

/// @nodoc
mixin _$SecurityExportData {
  bool get hasPasskey => throw _privateConstructorUsedError;
  bool get hasPassword => throw _privateConstructorUsedError;
  bool get totpEnabled => throw _privateConstructorUsedError;
  int get backupCodesRemaining => throw _privateConstructorUsedError;

  /// Serializes this SecurityExportData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SecurityExportData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SecurityExportDataCopyWith<SecurityExportData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SecurityExportDataCopyWith<$Res> {
  factory $SecurityExportDataCopyWith(
    SecurityExportData value,
    $Res Function(SecurityExportData) then,
  ) = _$SecurityExportDataCopyWithImpl<$Res, SecurityExportData>;
  @useResult
  $Res call({
    bool hasPasskey,
    bool hasPassword,
    bool totpEnabled,
    int backupCodesRemaining,
  });
}

/// @nodoc
class _$SecurityExportDataCopyWithImpl<$Res, $Val extends SecurityExportData>
    implements $SecurityExportDataCopyWith<$Res> {
  _$SecurityExportDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SecurityExportData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasPasskey = null,
    Object? hasPassword = null,
    Object? totpEnabled = null,
    Object? backupCodesRemaining = null,
  }) {
    return _then(
      _value.copyWith(
            hasPasskey: null == hasPasskey
                ? _value.hasPasskey
                : hasPasskey // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasPassword: null == hasPassword
                ? _value.hasPassword
                : hasPassword // ignore: cast_nullable_to_non_nullable
                      as bool,
            totpEnabled: null == totpEnabled
                ? _value.totpEnabled
                : totpEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            backupCodesRemaining: null == backupCodesRemaining
                ? _value.backupCodesRemaining
                : backupCodesRemaining // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SecurityExportDataImplCopyWith<$Res>
    implements $SecurityExportDataCopyWith<$Res> {
  factory _$$SecurityExportDataImplCopyWith(
    _$SecurityExportDataImpl value,
    $Res Function(_$SecurityExportDataImpl) then,
  ) = __$$SecurityExportDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool hasPasskey,
    bool hasPassword,
    bool totpEnabled,
    int backupCodesRemaining,
  });
}

/// @nodoc
class __$$SecurityExportDataImplCopyWithImpl<$Res>
    extends _$SecurityExportDataCopyWithImpl<$Res, _$SecurityExportDataImpl>
    implements _$$SecurityExportDataImplCopyWith<$Res> {
  __$$SecurityExportDataImplCopyWithImpl(
    _$SecurityExportDataImpl _value,
    $Res Function(_$SecurityExportDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SecurityExportData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasPasskey = null,
    Object? hasPassword = null,
    Object? totpEnabled = null,
    Object? backupCodesRemaining = null,
  }) {
    return _then(
      _$SecurityExportDataImpl(
        hasPasskey: null == hasPasskey
            ? _value.hasPasskey
            : hasPasskey // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasPassword: null == hasPassword
            ? _value.hasPassword
            : hasPassword // ignore: cast_nullable_to_non_nullable
                  as bool,
        totpEnabled: null == totpEnabled
            ? _value.totpEnabled
            : totpEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        backupCodesRemaining: null == backupCodesRemaining
            ? _value.backupCodesRemaining
            : backupCodesRemaining // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SecurityExportDataImpl implements _SecurityExportData {
  const _$SecurityExportDataImpl({
    required this.hasPasskey,
    required this.hasPassword,
    required this.totpEnabled,
    required this.backupCodesRemaining,
  });

  factory _$SecurityExportDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SecurityExportDataImplFromJson(json);

  @override
  final bool hasPasskey;
  @override
  final bool hasPassword;
  @override
  final bool totpEnabled;
  @override
  final int backupCodesRemaining;

  @override
  String toString() {
    return 'SecurityExportData(hasPasskey: $hasPasskey, hasPassword: $hasPassword, totpEnabled: $totpEnabled, backupCodesRemaining: $backupCodesRemaining)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SecurityExportDataImpl &&
            (identical(other.hasPasskey, hasPasskey) ||
                other.hasPasskey == hasPasskey) &&
            (identical(other.hasPassword, hasPassword) ||
                other.hasPassword == hasPassword) &&
            (identical(other.totpEnabled, totpEnabled) ||
                other.totpEnabled == totpEnabled) &&
            (identical(other.backupCodesRemaining, backupCodesRemaining) ||
                other.backupCodesRemaining == backupCodesRemaining));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    hasPasskey,
    hasPassword,
    totpEnabled,
    backupCodesRemaining,
  );

  /// Create a copy of SecurityExportData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SecurityExportDataImplCopyWith<_$SecurityExportDataImpl> get copyWith =>
      __$$SecurityExportDataImplCopyWithImpl<_$SecurityExportDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SecurityExportDataImplToJson(this);
  }
}

abstract class _SecurityExportData implements SecurityExportData {
  const factory _SecurityExportData({
    required final bool hasPasskey,
    required final bool hasPassword,
    required final bool totpEnabled,
    required final int backupCodesRemaining,
  }) = _$SecurityExportDataImpl;

  factory _SecurityExportData.fromJson(Map<String, dynamic> json) =
      _$SecurityExportDataImpl.fromJson;

  @override
  bool get hasPasskey;
  @override
  bool get hasPassword;
  @override
  bool get totpEnabled;
  @override
  int get backupCodesRemaining;

  /// Create a copy of SecurityExportData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SecurityExportDataImplCopyWith<_$SecurityExportDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
