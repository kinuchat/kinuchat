import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import '../../data/services/matrix_service.dart';
import 'storage_providers.dart';

/// Provider for MatrixService
final matrixServiceProvider = Provider<MatrixService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final service = MatrixService(
    secureStorage: secureStorage,
    // Production Matrix server
    homeserverUrl: 'https://matrix.kinuchat.com',
  );

  // Initialize service
  service.initialize();

  // Dispose when provider is destroyed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// StateNotifier for Matrix authentication state
class MatrixAuthNotifier extends StateNotifier<AsyncValue<bool>> {
  MatrixAuthNotifier(this._matrixService) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  final MatrixService _matrixService;

  /// Check if user is authenticated
  Future<void> _checkAuthStatus() async {
    state = const AsyncValue.loading();
    try {
      await _matrixService.initialize();
      state = AsyncValue.data(_matrixService.isLoggedIn);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Register a new Matrix account
  Future<void> register({
    required String username,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _matrixService.register(
        username: username,
        password: password,
      );
      state = const AsyncValue.data(true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Login to existing account
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _matrixService.login(
        username: username,
        password: password,
      );
      state = const AsyncValue.data(true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Login with token from Kinu auth response
  /// Used for auto-login after registration
  Future<void> loginWithToken({
    required String accessToken,
    required String userId,
    required String deviceId,
    String? homeserverUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _matrixService.loginWithToken(
        accessToken: accessToken,
        userId: userId,
        deviceId: deviceId,
        homeserverUrl: homeserverUrl,
      );
      state = const AsyncValue.data(true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _matrixService.logout();
      state = const AsyncValue.data(false);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for Matrix authentication state
final matrixAuthProvider =
    StateNotifierProvider<MatrixAuthNotifier, AsyncValue<bool>>((ref) {
  final matrixService = ref.watch(matrixServiceProvider);
  return MatrixAuthNotifier(matrixService);
});

/// Provider for Matrix rooms (conversations)
final matrixRoomsProvider = StreamProvider<List<Room>>((ref) {
  final matrixService = ref.watch(matrixServiceProvider);

  return matrixService.onSync.map((_) {
    return matrixService.getRooms();
  });
});

/// Provider for checking if Matrix is authenticated
final isMatrixAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(matrixAuthProvider);
  return authState.maybeWhen(
    data: (isAuthenticated) => isAuthenticated,
    orElse: () => false,
  );
});
