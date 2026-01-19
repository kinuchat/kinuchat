import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// MeshLink account model
@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    required String handle,
    required String displayName,
    required bool hasPasskey,
    required bool hasPassword,
    required bool hasEmail,
    required bool emailVerified,
    required bool totpEnabled,
    required DateTime createdAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
}

/// Registration request
@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String handle,
    required String displayName,
    String? password,
    String? email,
    /// Device name (e.g., "John's iPhone 15")
    String? deviceName,
    /// Device platform (e.g., "iOS", "Android")
    String? devicePlatform,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

/// Login request
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String handle,
    required String password,
    String? totpCode,
    /// Device name (e.g., "John's iPhone 15")
    String? deviceName,
    /// Device platform (e.g., "iOS", "Android")
    String? devicePlatform,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

/// Auth response containing token and account
@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String token,
    required Account account,
    /// Device ID for this session (used for device management)
    required String deviceId,
    /// Matrix credentials for cloud messaging (auto-created on registration)
    MatrixCredentials? matrix,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

/// Matrix server credentials
@freezed
class MatrixCredentials with _$MatrixCredentials {
  const factory MatrixCredentials({
    /// Full Matrix user ID (e.g., @handle:kinu.chat)
    required String userId,
    /// Matrix access token (empty if app should login separately)
    required String accessToken,
    /// Device ID
    required String deviceId,
    /// Homeserver URL
    required String homeserverUrl,
  }) = _MatrixCredentials;

  factory MatrixCredentials.fromJson(Map<String, dynamic> json) =>
      _$MatrixCredentialsFromJson(json);
}

/// Handle availability check response
@freezed
class HandleCheckResponse with _$HandleCheckResponse {
  const factory HandleCheckResponse({
    required bool available,
    required String handle,
  }) = _HandleCheckResponse;

  factory HandleCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$HandleCheckResponseFromJson(json);
}

/// TOTP setup response
@freezed
class TotpSetupResponse with _$TotpSetupResponse {
  const factory TotpSetupResponse({
    required String secret,
    @JsonKey(name: 'otpauth_url') required String otpauthUrl,
    @JsonKey(name: 'qr_code_base64') required String qrCodeBase64,
  }) = _TotpSetupResponse;

  factory TotpSetupResponse.fromJson(Map<String, dynamic> json) =>
      _$TotpSetupResponseFromJson(json);
}

/// Backup codes response
@freezed
class BackupCodesResponse with _$BackupCodesResponse {
  const factory BackupCodesResponse({
    required List<String> codes,
  }) = _BackupCodesResponse;

  factory BackupCodesResponse.fromJson(Map<String, dynamic> json) =>
      _$BackupCodesResponseFromJson(json);
}

/// API error response
@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    required String error,
    required String code,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}

/// Device information
@freezed
class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String id,
    required String name,
    required String type,
    required DateTime lastActiveAt,
    required bool isCurrent,
    String? location,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}

/// Data export response (GDPR compliance)
@freezed
class DataExportResponse with _$DataExportResponse {
  const factory DataExportResponse({
    required DateTime exportedAt,
    required AccountExportData account,
    required List<DeviceExportData> devices,
    required SecurityExportData security,
  }) = _DataExportResponse;

  factory DataExportResponse.fromJson(Map<String, dynamic> json) =>
      _$DataExportResponseFromJson(json);
}

/// Account data for export
@freezed
class AccountExportData with _$AccountExportData {
  const factory AccountExportData({
    required String id,
    required String handle,
    required String displayName,
    required bool hasEmail,
    required bool emailVerified,
    required String createdAt,
  }) = _AccountExportData;

  factory AccountExportData.fromJson(Map<String, dynamic> json) =>
      _$AccountExportDataFromJson(json);
}

/// Device data for export
@freezed
class DeviceExportData with _$DeviceExportData {
  const factory DeviceExportData({
    required String id,
    required String name,
    required String platform,
    required String firstSeen,
    required String lastActive,
  }) = _DeviceExportData;

  factory DeviceExportData.fromJson(Map<String, dynamic> json) =>
      _$DeviceExportDataFromJson(json);
}

/// Security settings for export
@freezed
class SecurityExportData with _$SecurityExportData {
  const factory SecurityExportData({
    required bool hasPasskey,
    required bool hasPassword,
    required bool totpEnabled,
    required int backupCodesRemaining,
  }) = _SecurityExportData;

  factory SecurityExportData.fromJson(Map<String, dynamic> json) =>
      _$SecurityExportDataFromJson(json);
}
