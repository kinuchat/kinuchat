import 'dart:convert';

import 'package:dio/dio.dart';

/// Service for managing passkey (WebAuthn) operations
class PasskeyService {
  PasskeyService({
    required String baseUrl,
    Dio? dio,
  })  : _baseUrl = baseUrl,
        _dio = dio ?? Dio();

  final String _baseUrl;
  final Dio _dio;

  String? _accessToken;

  /// Set the access token for authenticated requests
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Map<String, String> get _authHeaders => _accessToken != null
      ? {'Authorization': 'Bearer $_accessToken'}
      : {};

  /// Start passkey registration
  /// Returns the WebAuthn options and session ID
  Future<PasskeyRegistrationOptions> startRegistration() async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/passkey/register/start',
        options: Options(headers: _authHeaders),
      );

      return PasskeyRegistrationOptions.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete passkey registration with the credential
  Future<void> finishRegistration({
    required String sessionId,
    required Map<String, dynamic> credential,
  }) async {
    try {
      await _dio.post(
        '$_baseUrl/api/v1/passkey/register/finish',
        data: {
          'session_id': sessionId,
          'credential': credential,
        },
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Start passkey authentication
  Future<PasskeyAuthenticationOptions> startAuthentication({
    required String handle,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/passkey/authenticate/start',
        data: {'handle': handle},
      );

      return PasskeyAuthenticationOptions.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete passkey authentication with the credential
  /// Returns the auth response with token and account
  Future<Map<String, dynamic>> finishAuthentication({
    required String sessionId,
    required Map<String, dynamic> credential,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/passkey/authenticate/finish',
        data: {
          'session_id': sessionId,
          'credential': credential,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  PasskeyException _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return PasskeyException(
          message: data['error'] ?? 'Unknown error',
          code: data['code'] ?? 'UNKNOWN',
          statusCode: e.response!.statusCode,
        );
      }
    }
    return PasskeyException(
      message: e.message ?? 'Network error',
      code: 'NETWORK_ERROR',
    );
  }
}

/// Options for passkey registration
class PasskeyRegistrationOptions {
  const PasskeyRegistrationOptions({
    required this.options,
    required this.sessionId,
  });

  final Map<String, dynamic> options;
  final String sessionId;

  factory PasskeyRegistrationOptions.fromJson(Map<String, dynamic> json) {
    return PasskeyRegistrationOptions(
      options: json['options'] as Map<String, dynamic>,
      sessionId: json['session_id'] as String,
    );
  }
}

/// Options for passkey authentication
class PasskeyAuthenticationOptions {
  const PasskeyAuthenticationOptions({
    required this.options,
    required this.sessionId,
  });

  final Map<String, dynamic> options;
  final String sessionId;

  factory PasskeyAuthenticationOptions.fromJson(Map<String, dynamic> json) {
    return PasskeyAuthenticationOptions(
      options: json['options'] as Map<String, dynamic>,
      sessionId: json['session_id'] as String,
    );
  }
}

/// Exception for passkey operations
class PasskeyException implements Exception {
  const PasskeyException({
    required this.message,
    required this.code,
    this.statusCode,
  });

  final String message;
  final String code;
  final int? statusCode;

  @override
  String toString() => 'PasskeyException: $message (code: $code)';
}
