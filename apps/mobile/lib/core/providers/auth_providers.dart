import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/meshlink_core.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import 'storage_providers.dart';
import 'matrix_providers.dart';
import 'identity_providers.dart';
import '../../data/services/kinu_relying_party.dart';

/// Auth service configuration
class AuthConfig {
  // Production URL for Kinu auth service
  // For local development, override via AUTH_BASE_URL environment variable
  static const String defaultBaseUrl = 'https://auth.kinuchat.com';

  /// Get the auth service base URL from environment or use default
  static String get baseUrl {
    // In production, this would come from environment config
    return const String.fromEnvironment(
      'AUTH_BASE_URL',
      defaultValue: defaultBaseUrl,
    );
  }
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(baseUrl: AuthConfig.baseUrl);
});

/// Account state
enum AccountStatus {
  unknown,
  unauthenticated,
  authenticated,
}

/// Account state with optional account data
class AccountState {
  const AccountState({
    required this.status,
    this.account,
    this.error,
  });

  final AccountStatus status;
  final Account? account;
  final String? error;

  const AccountState.initial()
      : status = AccountStatus.unknown,
        account = null,
        error = null;

  const AccountState.unauthenticated()
      : status = AccountStatus.unauthenticated,
        account = null,
        error = null;

  AccountState.authenticated(Account this.account)
      : status = AccountStatus.authenticated,
        error = null;

  AccountState.error(String this.error)
      : status = AccountStatus.unauthenticated,
        account = null;

  bool get isAuthenticated => status == AccountStatus.authenticated;
  bool get isUnauthenticated => status == AccountStatus.unauthenticated;
  bool get isLoading => status == AccountStatus.unknown;
}

/// StateNotifier for managing account state
class AccountNotifier extends StateNotifier<AccountState> {
  AccountNotifier(this._authService, this._secureStorage, this._ref)
      : super(const AccountState.initial()) {
    _initialize();
  }

  final AuthService _authService;
  final SecureStorage _secureStorage;
  final Ref _ref;

  static const _tokenKey = 'auth_access_token';
  static const _deviceIdKey = 'auth_device_id';

  /// Initialize - check for stored token and device ID
  Future<void> _initialize() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final deviceId = await _secureStorage.read(key: _deviceIdKey);

      if (token != null) {
        _authService.setAccessToken(token);
        if (deviceId != null) {
          _authService.setDeviceId(deviceId);
        }
        try {
          final account = await _authService.getCurrentAccount();
          state = AccountState.authenticated(account);
        } catch (e) {
          // Token invalid, clear it
          await _secureStorage.delete(key: _tokenKey);
          await _secureStorage.delete(key: _deviceIdKey);
          _authService.setAccessToken(null);
          _authService.setDeviceId(null);
          state = const AccountState.unauthenticated();
        }
      } else {
        state = const AccountState.unauthenticated();
      }
    } catch (e) {
      state = const AccountState.unauthenticated();
    }
  }

  /// Get device name and platform for device tracking
  Future<({String name, String platform})> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return (
          name: iosInfo.name,
          platform: 'iOS',
        );
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return (
          name: '${androidInfo.brand} ${androidInfo.model}',
          platform: 'Android',
        );
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
    }
    return (name: 'Unknown Device', platform: 'Unknown');
  }

  /// Check handle availability
  Future<HandleCheckResponse> checkHandle(String handle) async {
    return await _authService.checkHandle(handle);
  }

  /// Register a new account
  /// Also creates Matrix account automatically if password provided
  Future<void> register({
    required String handle,
    required String displayName,
    String? password,
    String? email,
  }) async {
    try {
      // Get device info for device tracking
      final deviceInfo = await _getDeviceInfo();

      final request = RegisterRequest(
        handle: handle,
        displayName: displayName,
        password: password,
        email: email,
        deviceName: deviceInfo.name,
        devicePlatform: deviceInfo.platform,
      );

      final response = await _authService.register(request);

      // Store token and device ID
      await _secureStorage.write(key: _tokenKey, value: response.token);
      await _secureStorage.write(key: _deviceIdKey, value: response.deviceId);

      state = AccountState.authenticated(response.account);

      // Auto-login to Matrix if credentials were returned
      if (response.matrix != null && response.matrix!.accessToken.isNotEmpty) {
        try {
          await _ref.read(matrixAuthProvider.notifier).loginWithToken(
                accessToken: response.matrix!.accessToken,
                userId: response.matrix!.userId,
                deviceId: response.matrix!.deviceId,
                homeserverUrl: response.matrix!.homeserverUrl,
              );
          debugPrint('Auto-logged into Matrix as ${response.matrix!.userId}');
        } catch (e) {
          // Matrix login failed, but Kinu auth succeeded - log but don't fail
          debugPrint('Matrix auto-login failed: $e');
        }
      }

      // Auto-create mesh identity for local encryption
      try {
        final hasIdentity = _ref.read(hasIdentityProvider);
        if (!hasIdentity) {
          await _ref.read(identityProvider.notifier).generateIdentity(
                displayName: displayName,
              );
          debugPrint('Created mesh identity for $handle');
        }
      } catch (e) {
        debugPrint('Failed to create mesh identity: $e');
      }
    } on AuthException catch (e) {
      state = AccountState.error(e.message);
      rethrow;
    }
  }

  /// Login with password
  /// Also logs into Matrix with same credentials
  Future<void> login({
    required String handle,
    required String password,
    String? totpCode,
  }) async {
    try {
      // Get device info for device tracking
      final deviceInfo = await _getDeviceInfo();

      final request = LoginRequest(
        handle: handle,
        password: password,
        totpCode: totpCode,
        deviceName: deviceInfo.name,
        devicePlatform: deviceInfo.platform,
      );

      final response = await _authService.login(request);

      // Store token and device ID
      await _secureStorage.write(key: _tokenKey, value: response.token);
      await _secureStorage.write(key: _deviceIdKey, value: response.deviceId);

      state = AccountState.authenticated(response.account);

      // Auto-login to Matrix with same credentials
      // Server returns Matrix user ID, we use same password
      if (response.matrix != null) {
        try {
          // Extract username from Matrix user ID (@handle:server -> handle)
          final matrixUserId = response.matrix!.userId;
          final username = matrixUserId.startsWith('@')
              ? matrixUserId.substring(1).split(':').first
              : matrixUserId.split(':').first;

          await _ref.read(matrixAuthProvider.notifier).login(
                username: username,
                password: password,
              );
          debugPrint('Auto-logged into Matrix as $matrixUserId');
        } catch (e) {
          // Matrix login failed, but Kinu auth succeeded - log but don't fail
          debugPrint('Matrix auto-login failed: $e');
        }
      }

      // Ensure mesh identity exists (create if needed for existing accounts)
      try {
        final hasIdentity = _ref.read(hasIdentityProvider);
        if (!hasIdentity) {
          await _ref.read(identityProvider.notifier).generateIdentity(
                displayName: response.account.displayName,
              );
          debugPrint('Created mesh identity for $handle');
        }
      } catch (e) {
        debugPrint('Failed to create mesh identity: $e');
      }
    } on AuthException catch (e) {
      state = AccountState.error(e.message);
      rethrow;
    }
  }

  /// Update account
  Future<void> updateAccount({String? displayName}) async {
    try {
      final account = await _authService.updateAccount(displayName: displayName);
      state = AccountState.authenticated(account);
    } on AuthException catch (e) {
      state = AccountState.error(e.message);
      rethrow;
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String displayName) async {
    await updateAccount(displayName: displayName);
  }

  /// Logout - clears all auth state including Matrix and identity
  Future<void> logout() async {
    // Clear Kinu auth tokens
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _deviceIdKey);
    _authService.logout();

    // Logout from Matrix
    try {
      await _ref.read(matrixAuthProvider.notifier).logout();
      debugPrint('Logged out of Matrix');
    } catch (e) {
      debugPrint('Matrix logout failed: $e');
    }

    // Delete local identity (user will create new one on next registration)
    try {
      await _ref.read(identityProvider.notifier).deleteIdentity();
      debugPrint('Deleted local identity');
    } catch (e) {
      debugPrint('Identity deletion failed: $e');
    }

    state = const AccountState.unauthenticated();
  }

  /// Refresh account data
  Future<void> refresh() async {
    if (state.isAuthenticated) {
      try {
        final account = await _authService.getCurrentAccount();
        state = AccountState.authenticated(account);
      } catch (e) {
        // If refresh fails, stay authenticated but don't update
      }
    }
  }
}

/// Provider for account state
final accountProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AccountNotifier(authService, secureStorage, ref);
});

/// Provider for KinuRelyingParty
final kinuRelyingPartyProvider = Provider<KinuRelyingParty>((ref) {
  return KinuRelyingParty(baseUrl: AuthConfig.baseUrl);
});

/// Provider for PasskeyAuthenticator
final passkeyAuthenticatorProvider = Provider<PasskeyAuthenticator>((ref) {
  return PasskeyAuthenticator();
});

/// Provider for PasskeyService
final passkeyServiceProvider = Provider<PasskeyServiceWrapper>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authenticator = ref.watch(passkeyAuthenticatorProvider);
  final relyingParty = ref.watch(kinuRelyingPartyProvider);
  return PasskeyServiceWrapper(
    authService: authService,
    authenticator: authenticator,
    relyingParty: relyingParty,
  );
});

/// Wrapper for PasskeyService with simplified API
/// Uses the passkeys package to handle WebAuthn authentication
class PasskeyServiceWrapper {
  PasskeyServiceWrapper({
    required this.authService,
    required this.authenticator,
    required this.relyingParty,
  });

  final AuthService authService;
  final PasskeyAuthenticator authenticator;
  final KinuRelyingParty relyingParty;

  /// Register a new passkey for the current user
  /// This handles the full WebAuthn flow with platform APIs
  Future<void> registerPasskey({required String email}) async {
    // Sync token from auth service
    relyingParty.setAccessToken(authService.accessToken);

    try {
      // Get WebAuthn options from server
      final (jsonOptions, sessionId) = await relyingParty.startRegistration();

      // Parse options and invoke platform authenticator
      final request = RegisterRequestType.fromJsonString(jsonOptions);
      final response = await authenticator.register(request);

      // Send response back to server
      await relyingParty.finishRegistration(
        sessionId: sessionId,
        responseJson: response.toJsonString(),
      );

      debugPrint('Passkey registered successfully for $email');
    } catch (e) {
      debugPrint('Passkey registration failed: $e');
      throw PasskeyException(
        message: 'Passkey registration failed: $e',
        code: 'REGISTRATION_FAILED',
      );
    }
  }

  /// Authenticate with passkey
  /// Returns the auth token on success
  Future<String> authenticateWithPasskey(String handle) async {
    try {
      // Get WebAuthn options from server
      final (jsonOptions, sessionId) = await relyingParty.startAuthentication(
        handle: handle,
      );

      // Parse options and invoke platform authenticator
      final request = AuthenticateRequestType.fromJsonString(jsonOptions);
      final response = await authenticator.authenticate(request);

      // Send response back to server and get auth token
      final authResponse = await relyingParty.finishAuthentication(
        sessionId: sessionId,
        responseJson: response.toJsonString(),
      );

      final token = authResponse['token'] as String? ?? '';
      debugPrint('Passkey authentication successful for $handle');
      return token;
    } catch (e) {
      debugPrint('Passkey authentication failed: $e');
      throw PasskeyException(
        message: 'Passkey authentication failed: $e',
        code: 'AUTHENTICATION_FAILED',
      );
    }
  }
}

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(accountProvider).isAuthenticated;
});

/// Provider for current account (nullable)
final currentAccountProvider = Provider<Account?>((ref) {
  return ref.watch(accountProvider).account;
});
