import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:meshlink_core/crypto/secure_storage.dart';

/// Matrix service for cloud messaging
/// Based on Phase 1 implementation requirements
class MatrixService {
  MatrixService({
    required SecureStorage secureStorage,
    String? homeserverUrl,
  })  : _secureStorage = secureStorage,
        _homeserverUrl = homeserverUrl ?? 'https://matrix.kinuchat.com';

  final SecureStorage _secureStorage;
  final String _homeserverUrl;
  Client? _client;

  /// Get the Matrix client instance
  Client? get client => _client;

  /// Check if logged in
  bool get isLoggedIn => _client?.isLogged() ?? false;

  /// Check if Matrix transport is available (logged in and connected)
  Future<bool> isAvailable() async {
    return isLoggedIn;
  }

  /// Initialize Matrix client
  Future<void> initialize() async {
    _client = Client('Kinu');

    // Check for stored credentials
    final accessToken = await _secureStorage.read(
      key: SecureStorageKeys.matrixAccessToken,
    );
    final deviceId = await _secureStorage.read(
      key: SecureStorageKeys.matrixDeviceId,
    );
    final userId = await _secureStorage.read(
      key: SecureStorageKeys.matrixUserId,
    );

    if (accessToken != null && deviceId != null && userId != null) {
      // Restore session - all parameters required
      await _client!.init(
        newToken: accessToken,
        newDeviceID: deviceId,
        newDeviceName: 'Kinu Mobile',
        newHomeserver: Uri.parse(_homeserverUrl),
        newUserID: userId,
      );
    }
  }

  /// Register a new account
  /// Uses the identity's public key as username
  Future<void> register({
    required String username,
    required String password,
  }) async {
    if (_client == null) {
      throw MatrixServiceException('Client not initialized');
    }

    try {
      await _client!.checkHomeserver(Uri.parse(_homeserverUrl));

      // Register account
      await _client!.register(
        username: username,
        password: password,
      );

      // Store credentials
      await _storeCredentials();
    } catch (e) {
      throw MatrixServiceException('Registration failed: $e');
    }
  }

  /// Login to existing account
  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (_client == null) {
      throw MatrixServiceException('Client not initialized');
    }

    try {
      await _client!.checkHomeserver(Uri.parse(_homeserverUrl));

      // Login
      await _client!.login(
        LoginType.mLoginPassword,
        identifier: AuthenticationUserIdentifier(user: username),
        password: password,
      );

      // Store credentials
      await _storeCredentials();
    } catch (e) {
      throw MatrixServiceException('Login failed: $e');
    }
  }

  /// Login with access token from Kinu auth
  /// Used when Matrix account was auto-created during registration
  Future<void> loginWithToken({
    required String accessToken,
    required String userId,
    required String deviceId,
    String? homeserverUrl,
  }) async {
    if (_client == null) {
      throw MatrixServiceException('Client not initialized');
    }

    try {
      final serverUrl = homeserverUrl ?? _homeserverUrl;

      await _client!.init(
        newToken: accessToken,
        newDeviceID: deviceId,
        newDeviceName: 'Kinu Mobile',
        newHomeserver: Uri.parse(serverUrl),
        newUserID: userId,
      );

      // Store credentials
      await _storeCredentials();
    } catch (e) {
      throw MatrixServiceException('Token login failed: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    if (_client == null) {
      return;
    }

    try {
      await _client!.logout();

      // Clear stored credentials
      await _secureStorage.delete(key: SecureStorageKeys.matrixAccessToken);
      await _secureStorage.delete(key: SecureStorageKeys.matrixDeviceId);
      await _secureStorage.delete(key: SecureStorageKeys.matrixUserId);
    } catch (e) {
      throw MatrixServiceException('Logout failed: $e');
    }
  }

  /// Create a direct message room
  /// Returns existing room if one already exists with this user
  Future<String> createDirectMessageRoom({
    required String userId,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      // First sync to get latest room state
      await _client!.sync();

      // Check if we already have a DM with this user
      final existingRoomId = _client!.getDirectChatFromUserId(userId);
      if (existingRoomId != null) {
        debugPrint('Found existing DM room with $userId: $existingRoomId');
        return existingRoomId;
      }

      // Create new DM room
      final roomId = await _client!.startDirectChat(userId);
      debugPrint('Created new DM room with $userId: $roomId');

      // Sync again to ensure room is in local state
      await _client!.sync();

      return roomId;
    } catch (e) {
      throw MatrixServiceException('Failed to create DM room: $e');
    }
  }

  /// Send a text message
  Future<String> sendTextMessage({
    required String roomId,
    required String message,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      var room = _client!.getRoomById(roomId);

      // If room not in cache, try to sync and wait for it
      if (room == null) {
        // Trigger a sync to get latest rooms
        await _client!.sync();

        // Try again after sync
        room = _client!.getRoomById(roomId);

        // If still not found, try joining the room directly
        if (room == null) {
          try {
            await _client!.joinRoom(roomId);
            await _client!.sync();
            room = _client!.getRoomById(roomId);
          } catch (e) {
            // Room might already be joined, just not synced
            debugPrint('Join room attempt: $e');
          }
        }

        if (room == null) {
          throw MatrixServiceException('Room not found after sync: $roomId');
        }
      }

      final eventId = await room.sendTextEvent(message);
      if (eventId == null) {
        throw MatrixServiceException('Failed to get event ID');
      }
      return eventId;
    } catch (e) {
      throw MatrixServiceException('Failed to send message: $e');
    }
  }

  /// Get all rooms (conversations)
  List<Room> getRooms() {
    if (_client == null) {
      return [];
    }
    return _client!.rooms;
  }

  /// Get room by ID
  Room? getRoomById(String roomId) {
    if (_client == null) {
      return null;
    }
    return _client!.getRoomById(roomId);
  }

  /// Start listening to sync events
  Stream<SyncUpdate> get onSync {
    if (_client == null) {
      return const Stream.empty();
    }
    return _client!.onSync.stream;
  }

  /// Start listening to room updates
  Stream<EventUpdate> get onEvent {
    if (_client == null) {
      return const Stream.empty();
    }
    return _client!.onEvent.stream;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _client?.dispose();
    _client = null;
  }

  // ============================================================================
  // Private Methods
  // ============================================================================

  /// Store Matrix credentials in secure storage
  Future<void> _storeCredentials() async {
    if (_client?.accessToken != null) {
      await _secureStorage.write(
        key: SecureStorageKeys.matrixAccessToken,
        value: _client!.accessToken!,
      );
    }

    if (_client?.deviceID != null) {
      await _secureStorage.write(
        key: SecureStorageKeys.matrixDeviceId,
        value: _client!.deviceID!,
      );
    }

    if (_client?.userID != null) {
      await _secureStorage.write(
        key: SecureStorageKeys.matrixUserId,
        value: _client!.userID!,
      );
    }
  }
}

/// Exception thrown when Matrix operations fail
class MatrixServiceException implements Exception {
  MatrixServiceException(this.message);

  final String message;

  @override
  String toString() => 'MatrixServiceException: $message';
}
