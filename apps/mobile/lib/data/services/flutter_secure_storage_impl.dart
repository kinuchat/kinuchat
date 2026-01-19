import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meshlink_core/crypto/secure_storage.dart';

/// Concrete implementation of SecureStorage using flutter_secure_storage
///
/// Security considerations per Section 17.2:
/// - iOS: Uses kSecAttrAccessibleAfterFirstUnlock
/// - Android: Uses EncryptedSharedPreferences
class FlutterSecureStorageImpl implements SecureStorage {
  FlutterSecureStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to write to secure storage', e);
    }
  }

  @override
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to read from secure storage', e);
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete from secure storage', e);
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to delete all from secure storage', e);
    }
  }

  @override
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to check key in secure storage', e);
    }
  }

  @override
  Future<void> writeBytes({
    required String key,
    required Uint8List value,
  }) async {
    try {
      final encoded = base64.encode(value);
      await _storage.write(key: key, value: encoded);
    } catch (e) {
      throw SecureStorageException('Failed to write bytes to secure storage', e);
    }
  }

  @override
  Future<Uint8List?> readBytes({required String key}) async {
    try {
      final encoded = await _storage.read(key: key);
      if (encoded == null) {
        return null;
      }
      return base64.decode(encoded);
    } catch (e) {
      throw SecureStorageException('Failed to read bytes from secure storage', e);
    }
  }
}
