import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meshlink_core/crypto/secure_storage.dart';
import '../../data/services/flutter_secure_storage_impl.dart';

/// Provider for FlutterSecureStorage instance
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
});

/// Provider for SecureStorage abstraction
final secureStorageProvider = Provider<SecureStorage>((ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return FlutterSecureStorageImpl(storage: storage);
});
