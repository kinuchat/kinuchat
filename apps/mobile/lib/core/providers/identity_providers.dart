import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/crypto/identity_service.dart';
import 'package:meshlink_core/models/identity.dart';
import 'storage_providers.dart';

/// Provider for IdentityService
final identityServiceProvider = Provider<IdentityService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return IdentityService(secureStorage);
});

/// StateNotifier for managing identity state
class IdentityNotifier extends StateNotifier<AsyncValue<Identity?>> {
  IdentityNotifier(this._identityService) : super(const AsyncValue.loading()) {
    loadIdentity();
  }

  final IdentityService _identityService;

  /// Load identity from storage
  Future<void> loadIdentity() async {
    state = const AsyncValue.loading();
    try {
      final identity = await _identityService.loadIdentity();
      state = AsyncValue.data(identity);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Generate a new identity
  Future<void> generateIdentity({
    String? displayName,
    String? avatar,
  }) async {
    state = const AsyncValue.loading();
    try {
      final identity = await _identityService.generateIdentity(
        displayName: displayName,
        avatar: avatar,
      );
      state = AsyncValue.data(identity);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update identity metadata
  Future<void> updateMetadata({
    String? displayName,
    String? avatar,
  }) async {
    final currentIdentity = state.value;
    if (currentIdentity == null) {
      return;
    }

    try {
      await _identityService.updateIdentityMetadata(
        identity: currentIdentity,
        displayName: displayName,
        avatar: avatar,
      );
      await loadIdentity();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete identity
  Future<void> deleteIdentity() async {
    try {
      await _identityService.deleteIdentity();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Export identity to encrypted backup
  Future<String> exportIdentity(String password) async {
    final currentIdentity = state.value;
    if (currentIdentity == null) {
      throw Exception('No identity to export');
    }

    return await _identityService.exportIdentity(currentIdentity, password);
  }

  /// Import identity from encrypted backup
  Future<void> importIdentity(String backup, String password) async {
    state = const AsyncValue.loading();
    try {
      final identity = await _identityService.importIdentity(backup, password);
      state = AsyncValue.data(identity);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for identity state
final identityProvider =
    StateNotifierProvider<IdentityNotifier, AsyncValue<Identity?>>((ref) {
  final identityService = ref.watch(identityServiceProvider);
  return IdentityNotifier(identityService);
});

/// Provider to check if identity exists
final hasIdentityProvider = Provider<bool>((ref) {
  final identityState = ref.watch(identityProvider);
  return identityState.maybeWhen(
    data: (identity) => identity != null,
    orElse: () => false,
  );
});
