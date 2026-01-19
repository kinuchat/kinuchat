import 'dart:convert';
import 'dart:typed_data';
import '../../lib/crypto/secure_storage.dart';

/// Mock implementation of SecureStorage for testing
class MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String value,
  }) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> writeBytes({
    required String key,
    required Uint8List value,
  }) async {
    _storage[key] = base64.encode(value);
  }

  @override
  Future<Uint8List?> readBytes({required String key}) async {
    final value = _storage[key];
    if (value == null) {
      return null;
    }
    return base64.decode(value);
  }

  /// Clear all storage (for test cleanup)
  void clear() {
    _storage.clear();
  }
}
