import 'dart:convert';
import 'package:dio/dio.dart';

/// Custom Relying Party Server implementation for Kinu auth backend
/// This bridges the passkeys package with our Rust WebAuthn endpoints
///
/// Works with JSON strings as the passkeys package expects
class KinuRelyingParty {
  KinuRelyingParty({
    required String baseUrl,
    Dio? dio,
  })  : _baseUrl = baseUrl,
        _dio = dio ?? Dio();

  final String _baseUrl;
  final Dio _dio;

  String? _accessToken;
  String? _currentHandle;

  /// Set the access token for authenticated requests
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Set the handle for authentication
  void setHandle(String handle) {
    _currentHandle = handle;
  }

  Map<String, String> get _authHeaders => _accessToken != null
      ? {'Authorization': 'Bearer $_accessToken', 'Content-Type': 'application/json'}
      : {'Content-Type': 'application/json'};

  /// Start passkey registration - returns WebAuthn options as JSON string
  Future<(String jsonOptions, String sessionId)> startRegistration() async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/passkey/register/start',
        options: Options(headers: _authHeaders),
      );

      final data = response.data as Map<String, dynamic>;
      final options = data['options'] as Map<String, dynamic>;
      final sessionId = (data['sessionId'] ?? data['session_id'] ?? '') as String;

      // Return the publicKey options as JSON string
      final publicKeyOptions = options['publicKey'] ?? options;
      return (jsonEncode(publicKeyOptions), sessionId);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Finish passkey registration with authenticator response
  Future<void> finishRegistration({
    required String sessionId,
    required String responseJson,
  }) async {
    try {
      final credential = jsonDecode(responseJson) as Map<String, dynamic>;

      await _dio.post(
        '$_baseUrl/api/v1/passkey/register/finish',
        data: {
          'sessionId': sessionId,
          'credential': credential,
        },
        options: Options(headers: _authHeaders),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Start passkey authentication - returns WebAuthn options as JSON string
  Future<(String jsonOptions, String sessionId)> startAuthentication({
    required String handle,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/v1/passkey/authenticate/start',
        data: {'handle': handle},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      final options = data['options'] as Map<String, dynamic>;
      final sessionId = (data['sessionId'] ?? data['session_id'] ?? '') as String;

      // Return the publicKey options as JSON string
      final publicKeyOptions = options['publicKey'] ?? options;
      return (jsonEncode(publicKeyOptions), sessionId);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Finish passkey authentication - returns auth token
  Future<Map<String, dynamic>> finishAuthentication({
    required String sessionId,
    required String responseJson,
  }) async {
    try {
      final credential = jsonDecode(responseJson) as Map<String, dynamic>;

      final response = await _dio.post(
        '$_baseUrl/api/v1/passkey/authenticate/finish',
        data: {
          'sessionId': sessionId,
          'credential': credential,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return Exception(data['error'] ?? 'Unknown error');
      }
    }
    return Exception(e.message ?? 'Network error');
  }
}
