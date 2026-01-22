import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:meshlink_core/crypto/secure_storage.dart';
import 'package:mime/mime.dart' as mime_lookup;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

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
    // Get persistent directory for database and file storage
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/matrix_sdk.db';
    final fileStoragePath = Uri.directory('${appDir.path}/matrix_files/');

    // Create client with encryption database (required for E2EE)
    _client = Client(
      'Kinu',
      databaseBuilder: (client) async {
        // Open SQLite database for encryption key storage
        final database = await sqflite.openDatabase(dbPath);
        final db = MatrixSdkDatabase(
          client.clientName,
          database: database,
          fileStorageLocation: fileStoragePath,
        );
        await db.open();
        return db;
      },
    );

    // Register default commands (required for sendTextEvent to work!)
    _client!.registerDefaultCommands();

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

      // Verify encryption is available after session restore
      if (_client!.encryptionEnabled) {
        debugPrint('[Matrix] Encryption enabled (session restored)');
      } else {
        debugPrint('[Matrix] WARNING: Encryption not available (session restored)');
      }
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

      // Wait for encryption to initialize
      if (_client!.encryptionEnabled) {
        debugPrint('[Matrix] Encryption enabled (registration)');
      } else {
        debugPrint('[Matrix] WARNING: Encryption not available (registration)');
      }

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

      // Wait for encryption to initialize
      if (_client!.encryptionEnabled) {
        debugPrint('[Matrix] Encryption enabled');
      } else {
        debugPrint('[Matrix] WARNING: Encryption not available');
      }

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

      // Wait for encryption to initialize
      if (_client!.encryptionEnabled) {
        debugPrint('[Matrix] Encryption enabled (token login)');
      } else {
        debugPrint('[Matrix] WARNING: Encryption not available (token login)');
      }

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

      // Sync multiple times to ensure room is in local state
      // Sometimes first sync doesn't include the new room
      for (var i = 0; i < 3; i++) {
        await _client!.sync();
        final room = _client!.getRoomById(roomId);
        if (room != null) {
          debugPrint('Room synced after ${i + 1} sync(s)');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

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

      // Check if we need to join the room (we might only be invited)
      if (room.membership == Membership.invite) {
        debugPrint('Auto-joining room we were invited to: $roomId');
        await room.join();
        await _client!.sync();
      }

      // Retry logic for sendTextEvent - sometimes returns null on first try
      String? eventId;
      for (var attempt = 0; attempt < 3; attempt++) {
        eventId = await room.sendTextEvent(message);
        if (eventId != null) break;

        // Wait and sync before retry
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        await _client!.sync();
        debugPrint('Retry sendTextEvent attempt ${attempt + 1}');
      }

      if (eventId == null) {
        throw MatrixServiceException('Failed to get event ID after 3 attempts');
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

  bool _isSyncing = false;

  /// Start continuous sync loop
  /// Calls sync() repeatedly with timeout for long-polling
  Future<void> startSync() async {
    if (_client == null || !isLoggedIn || _isSyncing) {
      return;
    }

    _isSyncing = true;
    debugPrint('Matrix background sync starting...');

    while (_isSyncing && _client != null && isLoggedIn) {
      try {
        // Long-poll - will wait up to 30s for new events
        await _client!.sync(timeout: 30000);
        // Small delay between syncs to prevent tight loop
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Matrix sync error: $e');
        // Wait before retrying on error
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    debugPrint('Matrix sync loop exited');
  }

  /// Stop sync loop
  void stopSync() {
    _isSyncing = false;
    debugPrint('Matrix sync stopped');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _client?.dispose();
    _client = null;
  }

  // ============================================================================
  // Group Chat Methods (Phase 6)
  // ============================================================================

  /// Create a group chat room
  Future<String> createGroup({
    required String name,
    List<String>? initialMembers,
    bool isEncrypted = true,
    String? topic,
    String? avatarUrl,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      // Prepare initial state events
      final initialState = <StateEvent>[];

      // Enable encryption by default
      if (isEncrypted) {
        initialState.add(
          StateEvent(
            type: EventTypes.Encryption,
            stateKey: '',
            content: {'algorithm': AlgorithmTypes.megolmV1AesSha2},
          ),
        );
      }

      // Set room topic if provided
      if (topic != null) {
        initialState.add(
          StateEvent(
            type: EventTypes.RoomTopic,
            stateKey: '',
            content: {'topic': topic},
          ),
        );
      }

      // Set room avatar if provided
      if (avatarUrl != null) {
        initialState.add(
          StateEvent(
            type: EventTypes.RoomAvatar,
            stateKey: '',
            content: {'url': avatarUrl},
          ),
        );
      }

      // Create the room
      final roomId = await _client!.createRoom(
        name: name,
        invite: initialMembers,
        preset: CreateRoomPreset.privateChat,
        initialState: initialState,
      );

      debugPrint('Created group room: $roomId');

      // Sync to get the room in local state
      await _client!.sync();

      return roomId;
    } catch (e) {
      throw MatrixServiceException('Failed to create group: $e');
    }
  }

  /// Invite a user to a group
  Future<void> inviteToGroup({
    required String roomId,
    required String userId,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      await room.invite(userId);
      debugPrint('Invited $userId to $roomId');
    } catch (e) {
      throw MatrixServiceException('Failed to invite to group: $e');
    }
  }

  /// Kick a user from a group
  Future<void> kickFromGroup({
    required String roomId,
    required String userId,
    String? reason,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      await room.kick(userId);
      debugPrint('Kicked $userId from $roomId');
    } catch (e) {
      throw MatrixServiceException('Failed to kick from group: $e');
    }
  }

  /// Ban a user from a group
  Future<void> banFromGroup({
    required String roomId,
    required String userId,
    String? reason,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      await room.ban(userId);
      debugPrint('Banned $userId from $roomId');
    } catch (e) {
      throw MatrixServiceException('Failed to ban from group: $e');
    }
  }

  /// Leave a group
  Future<void> leaveGroup(String roomId) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      await room.leave();
      debugPrint('Left group $roomId');
    } catch (e) {
      throw MatrixServiceException('Failed to leave group: $e');
    }
  }

  /// Update group settings
  Future<void> updateGroupSettings({
    required String roomId,
    String? name,
    String? topic,
    String? avatarUrl,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      if (name != null) {
        await room.setName(name);
      }

      if (topic != null) {
        await room.setDescription(topic);
      }

      // Note: setAvatar requires MatrixFile, not Uri
      // Avatar URL setting would need to download and reupload the file
      // For now, avatar updates are not supported via URL string
      if (avatarUrl != null) {
        debugPrint('Avatar URL update not yet implemented: $avatarUrl');
      }

      debugPrint('Updated group settings for $roomId');
    } catch (e) {
      throw MatrixServiceException('Failed to update group settings: $e');
    }
  }

  /// Get members of a group
  Future<List<User>> getGroupMembers(String roomId) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      // Request full member list
      await room.requestParticipants();

      return room.getParticipants();
    } catch (e) {
      throw MatrixServiceException('Failed to get group members: $e');
    }
  }

  /// Set a member's power level (role)
  Future<void> setMemberRole({
    required String roomId,
    required String userId,
    required GroupRole role,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      final powerLevel = switch (role) {
        GroupRole.owner => 100,
        GroupRole.admin => 50,
        GroupRole.member => 0,
      };

      await room.setPower(userId, powerLevel);
      debugPrint('Set $userId power level to $powerLevel in $roomId');
    } catch (e) {
      throw MatrixServiceException('Failed to set member role: $e');
    }
  }

  /// Check if current user is admin/owner of a room
  bool isGroupAdmin(String roomId) {
    if (_client == null || !isLoggedIn) {
      return false;
    }

    final room = _client!.getRoomById(roomId);
    if (room == null) {
      return false;
    }

    return room.canSendEvent(EventTypes.RoomPowerLevels);
  }

  /// Check if room is a group (not a DM)
  bool isGroup(String roomId) {
    if (_client == null) {
      return false;
    }

    final room = _client!.getRoomById(roomId);
    if (room == null) {
      return false;
    }

    // DMs have a direct chat mapping
    return !room.isDirectChat;
  }

  /// Check if room has encryption enabled
  bool isRoomEncrypted(String roomId) {
    if (_client == null) {
      return false;
    }

    final room = _client!.getRoomById(roomId);
    if (room == null) {
      return false;
    }

    return room.encrypted;
  }

  // ============================================================================
  // Media Methods (Phase 7)
  // ============================================================================

  /// Upload a file to the Matrix media repository
  /// Returns the MXC URI (mxc://server/media_id)
  Future<Uri> uploadMedia({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final contentType = mimeType ?? mime_lookup.lookupMimeType(fileName) ?? 'application/octet-stream';

      final uri = await _client!.uploadContent(
        bytes,
        filename: fileName,
        contentType: contentType,
      );

      return uri;
    } catch (e) {
      throw MatrixServiceException('Failed to upload media: $e');
    }
  }

  /// Upload a file from disk
  Future<Uri> uploadFile(File file) async {
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;
    return uploadMedia(bytes: bytes, fileName: fileName);
  }

  /// Send an image message
  Future<String> sendImageMessage({
    required String roomId,
    required File imageFile,
    String? caption,
    int? width,
    int? height,
    Uint8List? thumbnailBytes,
    int? thumbnailWidth,
    int? thumbnailHeight,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;
      final mimeType = mime_lookup.lookupMimeType(fileName) ?? 'image/jpeg';

      // Upload the image
      final imageUri = await uploadMedia(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      // Upload thumbnail if provided
      Uri? thumbnailUri;
      if (thumbnailBytes != null) {
        thumbnailUri = await uploadMedia(
          bytes: thumbnailBytes,
          fileName: 'thumb_$fileName',
          mimeType: mimeType,
        );
      }

      // Build message content
      final content = <String, dynamic>{
        'msgtype': 'm.image',
        'body': caption ?? fileName,
        'url': imageUri.toString(),
        'info': {
          'mimetype': mimeType,
          'size': bytes.length,
          if (width != null) 'w': width,
          if (height != null) 'h': height,
          if (thumbnailUri != null) 'thumbnail_url': thumbnailUri.toString(),
          if (thumbnailWidth != null && thumbnailHeight != null)
            'thumbnail_info': {
              'w': thumbnailWidth,
              'h': thumbnailHeight,
              'mimetype': mimeType,
              'size': thumbnailBytes?.length,
            },
        },
      };

      final eventId = await room.sendEvent(content);
      return eventId ?? '';
    } catch (e) {
      throw MatrixServiceException('Failed to send image: $e');
    }
  }

  /// Send a video message
  Future<String> sendVideoMessage({
    required String roomId,
    required File videoFile,
    String? caption,
    int? width,
    int? height,
    int? duration,
    Uint8List? thumbnailBytes,
    int? thumbnailWidth,
    int? thumbnailHeight,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      final bytes = await videoFile.readAsBytes();
      final fileName = videoFile.path.split('/').last;
      final mimeType = mime_lookup.lookupMimeType(fileName) ?? 'video/mp4';

      // Upload the video
      final videoUri = await uploadMedia(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      // Upload thumbnail if provided
      Uri? thumbnailUri;
      if (thumbnailBytes != null) {
        thumbnailUri = await uploadMedia(
          bytes: thumbnailBytes,
          fileName: 'thumb_$fileName.jpg',
          mimeType: 'image/jpeg',
        );
      }

      // Build message content
      final content = <String, dynamic>{
        'msgtype': 'm.video',
        'body': caption ?? fileName,
        'url': videoUri.toString(),
        'info': {
          'mimetype': mimeType,
          'size': bytes.length,
          if (width != null) 'w': width,
          if (height != null) 'h': height,
          if (duration != null) 'duration': duration,
          if (thumbnailUri != null) 'thumbnail_url': thumbnailUri.toString(),
          if (thumbnailWidth != null && thumbnailHeight != null)
            'thumbnail_info': {
              'w': thumbnailWidth,
              'h': thumbnailHeight,
              'mimetype': 'image/jpeg',
              'size': thumbnailBytes?.length,
            },
        },
      };

      final eventId = await room.sendEvent(content);
      return eventId ?? '';
    } catch (e) {
      throw MatrixServiceException('Failed to send video: $e');
    }
  }

  /// Send an audio/voice message
  Future<String> sendAudioMessage({
    required String roomId,
    required File audioFile,
    int? duration,
    bool isVoiceMessage = false,
    List<int>? waveform,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      final bytes = await audioFile.readAsBytes();
      final fileName = audioFile.path.split('/').last;
      final mimeType = mime_lookup.lookupMimeType(fileName) ?? 'audio/ogg';

      // Upload the audio
      final audioUri = await uploadMedia(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      // Build message content
      final content = <String, dynamic>{
        'msgtype': 'm.audio',
        'body': isVoiceMessage ? 'Voice message' : fileName,
        'url': audioUri.toString(),
        'info': {
          'mimetype': mimeType,
          'size': bytes.length,
          if (duration != null) 'duration': duration,
        },
        // Voice message indicator (MSC3245)
        if (isVoiceMessage) 'org.matrix.msc3245.voice': {},
        if (waveform != null) 'org.matrix.msc1767.audio': {
          'duration': duration,
          'waveform': waveform,
        },
      };

      final eventId = await room.sendEvent(content);
      return eventId ?? '';
    } catch (e) {
      throw MatrixServiceException('Failed to send audio: $e');
    }
  }

  /// Send a file attachment
  Future<String> sendFileMessage({
    required String roomId,
    required File file,
    String? caption,
  }) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final room = _client!.getRoomById(roomId);
      if (room == null) {
        throw MatrixServiceException('Room not found: $roomId');
      }

      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      final mimeType = mime_lookup.lookupMimeType(fileName) ?? 'application/octet-stream';

      // Upload the file
      final fileUri = await uploadMedia(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      // Build message content
      final content = <String, dynamic>{
        'msgtype': 'm.file',
        'body': caption ?? fileName,
        'filename': fileName,
        'url': fileUri.toString(),
        'info': {
          'mimetype': mimeType,
          'size': bytes.length,
        },
      };

      final eventId = await room.sendEvent(content);
      return eventId ?? '';
    } catch (e) {
      throw MatrixServiceException('Failed to send file: $e');
    }
  }

  /// Download media from MXC URI
  Future<Uint8List?> downloadMedia(Uri mxcUri) async {
    if (_client == null || !isLoggedIn) {
      throw MatrixServiceException('Not logged in');
    }

    try {
      final downloadUrl = await getDownloadUri(mxcUri);
      if (downloadUrl == null) {
        throw MatrixServiceException('Failed to get download URL');
      }
      final response = await _client!.httpClient.get(downloadUrl);
      return response.bodyBytes;
    } catch (e) {
      throw MatrixServiceException('Failed to download media: $e');
    }
  }

  /// Get thumbnail URL for media
  Future<Uri?> getThumbnailUri(
    Uri mxcUri, {
    int width = 200,
    int height = 200,
    ThumbnailMethod method = ThumbnailMethod.scale,
  }) async {
    if (_client?.homeserver == null) return null;
    return mxcUri.getThumbnailUri(
      _client!,
      width: width,
      height: height,
      method: method,
    );
  }

  /// Get download URL for media
  Future<Uri?> getDownloadUri(Uri mxcUri) async {
    if (_client?.homeserver == null) return null;
    return mxcUri.getDownloadUri(_client!);
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

/// Group member roles
enum GroupRole {
  /// Room creator with full permissions (power level 100)
  owner,

  /// Admin with elevated permissions (power level 50)
  admin,

  /// Regular member (power level 0)
  member,
}

/// Extension to convert power level to GroupRole
extension GroupRoleExtension on int {
  GroupRole toGroupRole() {
    if (this >= 100) return GroupRole.owner;
    if (this >= 50) return GroupRole.admin;
    return GroupRole.member;
  }
}
