import 'package:dio/dio.dart';

import 'account.dart';

/// Authentication service for MeshLink account management
class AuthService {
  AuthService({
    required String baseUrl,
    Dio? dio,
  })  : _baseUrl = baseUrl,
        _dio = dio ?? Dio();

  final String _baseUrl;
  final Dio _dio;

  String? _accessToken;
  String? _deviceId;

  /// Get the current access token
  String? get accessToken => _accessToken;

  /// Get the current device ID
  String? get deviceId => _deviceId;

  /// Set the access token (e.g., from secure storage)
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Set the device ID (e.g., from secure storage)
  void setDeviceId(String? id) {
    _deviceId = id;
  }

  /// Get authorization headers including device ID
  Map<String, String> get _authHeaders {
    final headers = <String, String>{};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (_deviceId != null) {
      headers['X-Device-ID'] = _deviceId!;
    }
    return headers;
  }

  /// Check if a handle is available
  Future<HandleCheckResponse> checkHandle(String handle) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/accounts/check-handle',
        queryParameters: {'handle': handle},
      );

      return HandleCheckResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register a new account
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/accounts/register',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      _accessToken = authResponse.token;
      _deviceId = authResponse.deviceId;
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login with password
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/accounts/login',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      _accessToken = authResponse.token;
      _deviceId = authResponse.deviceId;
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current account
  Future<Account> getCurrentAccount() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/accounts/me',
        options: Options(headers: _authHeaders),
      );

      return Account.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update account
  Future<Account> updateAccount({String? displayName}) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/accounts/me',
        data: {
          if (displayName != null) 'display_name': displayName,
        },
        options: Options(headers: _authHeaders),
      );

      return Account.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Request account recovery via email
  Future<void> requestRecovery(String handle) async {
    try {
      await _dio.post(
        '$_baseUrl/api/v1/recovery/request',
        data: {'handle': handle},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify recovery token
  Future<Map<String, dynamic>> verifyRecoveryToken(String token) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/recovery/verify',
        data: {'token': token},
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reset account with recovery token
  Future<AuthResponse> resetAccount({
    required String token,
    String? newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/recovery/reset',
        data: {
          'token': token,
          if (newPassword != null) 'new_password': newPassword,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      _accessToken = authResponse.token;
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Set up TOTP 2FA
  Future<TotpSetupResponse> setupTotp() async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/2fa/setup',
        options: Options(headers: _authHeaders),
      );

      return TotpSetupResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify TOTP code and enable 2FA
  Future<BackupCodesResponse> verifyTotp(String code) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/2fa/verify',
        data: {'code': code},
        options: Options(headers: _authHeaders),
      );

      return BackupCodesResponse.fromJson({
        'codes': response.data['backup_codes'] ?? [],
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Disable TOTP 2FA
  Future<void> disableTotp(String code) async {
    try {
      await _dio.post(
        '$_baseUrl/api/v1/2fa/disable',
        data: {'code': code},
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get new backup codes
  Future<BackupCodesResponse> getBackupCodes() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/2fa/backup-codes',
        options: Options(headers: _authHeaders),
      );

      return BackupCodesResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout - clear local token and device ID
  void logout() {
    _accessToken = null;
    _deviceId = null;
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/api/v1/accounts/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update email
  Future<void> updateEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/api/v1/accounts/update-email',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _dio.post(
        '$_baseUrl/api/v1/accounts/resend-verification',
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove recovery email
  Future<void> removeEmail() async {
    try {
      await _dio.delete(
        '$_baseUrl/api/v1/accounts/email',
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get list of devices
  Future<List<DeviceInfo>> getDevices() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/devices',
        options: Options(headers: _authHeaders),
      );

      final devices = response.data['devices'] as List<dynamic>;
      return devices
          .map((d) => DeviceInfo.fromJson(d as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Revoke a specific device
  Future<void> revokeDevice(String deviceId) async {
    try {
      await _dio.delete(
        '$_baseUrl/api/v1/devices/$deviceId',
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Revoke all other devices
  Future<void> revokeAllOtherDevices() async {
    try {
      await _dio.post(
        '$_baseUrl/api/v1/devices/revoke-all',
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete account
  Future<void> deleteAccount(String password) async {
    try {
      await _dio.delete(
        '$_baseUrl/api/v1/accounts/me',
        data: {'password': password},
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Export user data (GDPR compliance)
  Future<DataExportResponse> exportData() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/accounts/export',
        options: Options(headers: _authHeaders),
      );

      return DataExportResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors
  AuthException _handleError(DioException e) {
    if (e.response != null) {
      try {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          final apiError = ApiError.fromJson(data);
          return AuthException(
            message: apiError.error,
            code: apiError.code,
            statusCode: e.response!.statusCode,
          );
        }
      } catch (_) {}

      return AuthException(
        message: e.response?.statusMessage ?? 'Unknown error',
        code: 'HTTP_ERROR',
        statusCode: e.response?.statusCode,
      );
    }

    return AuthException(
      message: e.message ?? 'Network error',
      code: 'NETWORK_ERROR',
    );
  }
}

/// Authentication exception
class AuthException implements Exception {
  const AuthException({
    required this.message,
    required this.code,
    this.statusCode,
  });

  final String message;
  final String code;
  final int? statusCode;

  /// Check if this is a 2FA required error
  bool get is2FARequired => code == '2FA_REQUIRED';

  /// Check if this is an invalid credentials error
  bool get isInvalidCredentials => code == 'INVALID_CREDENTIALS';

  /// Check if this is a handle taken error
  bool get isHandleTaken => code == 'HANDLE_TAKEN';

  @override
  String toString() => 'AuthException: $message (code: $code)';
}
