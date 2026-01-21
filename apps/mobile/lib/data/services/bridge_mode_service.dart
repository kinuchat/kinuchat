import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:meshlink_core/database/app_database.dart';
import 'package:meshlink_core/transport/bridge_transport_impl.dart';

/// Bridge mode lifecycle states
enum BridgeModeState {
  /// Bridge mode is disabled
  disabled,

  /// Bridge mode is starting up
  starting,

  /// Bridge mode is active and relaying
  active,

  /// Bridge mode is paused (low battery, bandwidth limit, etc.)
  paused,

  /// Bridge mode is stopping
  stopping,

  /// Bridge mode encountered an error
  error,
}

/// Reason why bridge mode is paused
enum BridgePauseReason {
  /// Low battery
  lowBattery,

  /// Bandwidth limit reached
  bandwidthLimit,

  /// No internet connection
  noInternet,

  /// User manually paused
  userPaused,
}

/// Relay request received from mesh (for relay-for-others)
class RelayRequest {
  final String messageId;
  final String recipientKeyHash;
  final String encryptedPayload;
  final int ttlHours;
  final String priority;
  final String? senderPeerId;

  const RelayRequest({
    required this.messageId,
    required this.recipientKeyHash,
    required this.encryptedPayload,
    this.ttlHours = 4,
    this.priority = 'normal',
    this.senderPeerId,
  });

  factory RelayRequest.fromJson(Map<String, dynamic> json) {
    return RelayRequest(
      messageId: json['message_id'] as String,
      recipientKeyHash: json['recipient_key_hash'] as String,
      encryptedPayload: json['encrypted_payload'] as String,
      ttlHours: json['ttl_hours'] as int? ?? 4,
      priority: json['priority'] as String? ?? 'normal',
      senderPeerId: json['sender_peer_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'recipient_key_hash': recipientKeyHash,
        'encrypted_payload': encryptedPayload,
        'ttl_hours': ttlHours,
        'priority': priority,
        if (senderPeerId != null) 'sender_peer_id': senderPeerId,
      };
}

/// Bridge mode service - manages the bridge relay lifecycle
///
/// This service handles two main functions:
/// 1. Receiving messages addressed TO this user from the relay server
/// 2. Relaying messages FOR other users (AirTag-style relay)
class BridgeModeService {
  final AppDatabase _database;
  final String _relayServerUrl;
  final String _myPublicKey;

  BridgeTransportImpl? _bridgeTransport;
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  BridgeModeState _state = BridgeModeState.disabled;
  BridgePauseReason? _pauseReason;
  BridgeSettingsEntity? _settings;

  StreamSubscription? _batterySubscription;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _relayRequestSubscription;
  Timer? _pollTimer;
  Timer? _uploadTimer;

  // Statistics
  int _messagesRelayed = 0;
  double _bandwidthUsedMb = 0;
  int _messagesRelayedForOthers = 0;

  // Stream for relay requests from mesh
  StreamController<RelayRequest>? _relayRequestController;

  BridgeModeService({
    required AppDatabase database,
    required String relayServerUrl,
    required String myPublicKey,
  })  : _database = database,
        _relayServerUrl = relayServerUrl,
        _myPublicKey = myPublicKey;

  /// Current bridge mode state
  BridgeModeState get state => _state;

  /// Current pause reason (if paused)
  BridgePauseReason? get pauseReason => _pauseReason;

  /// Current settings
  BridgeSettingsEntity? get settings => _settings;

  /// Messages relayed this session (for self)
  int get messagesRelayed => _messagesRelayed;

  /// Messages relayed for others this session
  int get messagesRelayedForOthers => _messagesRelayedForOthers;

  /// Total messages handled
  int get totalMessagesHandled => _messagesRelayed + _messagesRelayedForOthers;

  /// Bandwidth used today (MB)
  double get bandwidthUsedMb => _bandwidthUsedMb;

  /// Stream of state changes
  final _stateController = StreamController<BridgeModeState>.broadcast();
  Stream<BridgeModeState> get stateStream => _stateController.stream;

  /// Sink for relay requests from mesh transport
  /// Call this to submit a relay request received from a mesh peer
  void submitRelayRequest(RelayRequest request) {
    _relayRequestController?.add(request);
  }

  /// Initialize and load settings
  Future<void> initialize() async {
    _settings = await _database.getBridgeSettings();

    // Initialize relay request controller
    _relayRequestController = StreamController<RelayRequest>.broadcast();

    if (_settings?.isEnabled ?? false) {
      await start();
    }
  }

  /// Start bridge mode
  Future<void> start() async {
    if (_state == BridgeModeState.active || _state == BridgeModeState.starting) {
      return;
    }

    _setState(BridgeModeState.starting);

    try {
      // Check prerequisites
      final canStart = await _checkPrerequisites();
      if (!canStart) {
        return;
      }

      // Initialize bridge transport
      _bridgeTransport = BridgeTransportImpl(
        relayServerUrl: _relayServerUrl,
        myPublicKey: _myPublicKey,
      );

      // Check relay server availability
      final available = await _bridgeTransport!.isAvailable();
      if (!available) {
        _setState(BridgeModeState.paused);
        _pauseReason = BridgePauseReason.noInternet;
        return;
      }

      // Connect WebSocket for real-time messages (for this user)
      await _bridgeTransport!.connectWebSocket();

      // Start listening for incoming messages (addressed to self)
      _messageSubscription = _bridgeTransport!.messageStream.listen(
        _handleIncomingMessage,
        onError: (error) {
          print('Bridge message error: $error');
        },
      );

      // Start listening for relay requests from mesh (relay for others)
      _relayRequestSubscription = _relayRequestController?.stream.listen(
        _handleRelayRequest,
        onError: (error) {
          print('Relay request error: $error');
        },
      );

      // Start upload timer for queued messages
      _uploadTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _uploadPendingMessages(),
      );

      // Monitor battery level
      _batterySubscription = _battery.onBatteryStateChanged.listen((_) {
        _checkBatteryLevel();
      });

      // Monitor connectivity
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
      );

      _setState(BridgeModeState.active);
    } catch (e) {
      print('Failed to start bridge mode: $e');
      _setState(BridgeModeState.error);
    }
  }

  /// Stop bridge mode
  Future<void> stop() async {
    if (_state == BridgeModeState.disabled || _state == BridgeModeState.stopping) {
      return;
    }

    _setState(BridgeModeState.stopping);

    try {
      // Cancel subscriptions
      await _batterySubscription?.cancel();
      await _connectivitySubscription?.cancel();
      await _messageSubscription?.cancel();
      await _relayRequestSubscription?.cancel();

      _batterySubscription = null;
      _connectivitySubscription = null;
      _messageSubscription = null;
      _relayRequestSubscription = null;

      // Cancel timers
      _pollTimer?.cancel();
      _uploadTimer?.cancel();
      _pollTimer = null;
      _uploadTimer = null;

      // Disconnect bridge transport
      await _bridgeTransport?.disconnect();
      _bridgeTransport = null;

      _setState(BridgeModeState.disabled);
    } catch (e) {
      print('Error stopping bridge mode: $e');
      _setState(BridgeModeState.error);
    }
  }

  /// Update bridge settings
  Future<void> updateSettings({
    bool? isEnabled,
    bool? relayForContactsOnly,
    int? maxBandwidthMbPerDay,
    int? minBatteryPercent,
  }) async {
    await _database.saveBridgeSettings(
      isEnabled: isEnabled,
      relayForContactsOnly: relayForContactsOnly,
      maxBandwidthMbPerDay: maxBandwidthMbPerDay,
      minBatteryPercent: minBatteryPercent,
    );

    _settings = await _database.getBridgeSettings();

    // Start/stop based on new settings
    if (isEnabled == true && _state == BridgeModeState.disabled) {
      await start();
    } else if (isEnabled == false && _state != BridgeModeState.disabled) {
      await stop();
    }
  }

  /// Queue a message for relay (used when sending via bridge transport)
  Future<void> queueMessageForRelay({
    required String messageId,
    required String recipientKeyHash,
    required String encryptedPayload,
    int ttlHours = 4,
    String priority = 'normal',
  }) async {
    await _database.insertBridgeMessage(
      messageId: messageId,
      recipientKeyHash: recipientKeyHash,
      encryptedPayload: encryptedPayload,
      ttlHours: ttlHours,
      priority: priority,
    );

    // Try to upload immediately if active
    if (_state == BridgeModeState.active) {
      await _uploadPendingMessages();
    }
  }

  /// Handle relay request from mesh peer (relay-for-others)
  /// This is the AirTag-style relay feature
  Future<void> _handleRelayRequest(RelayRequest request) async {
    if (_state != BridgeModeState.active) {
      print('Bridge not active, ignoring relay request');
      return;
    }

    // Check if we should relay for this sender
    if (_settings?.relayForContactsOnly == true) {
      // TODO: Check if sender is in contacts
      // For now, we'll relay for everyone when this setting is false
      // and skip when true (conservative approach)
      print('Relay for contacts only enabled, checking sender...');
      // If not a contact, we could skip:
      // return;
    }

    // Check bandwidth limit before relaying
    final maxBandwidth = _settings?.maxBandwidthMbPerDay ?? 50;
    if (_bandwidthUsedMb >= maxBandwidth) {
      print('Bandwidth limit reached, cannot relay');
      return;
    }

    try {
      // Upload to relay server
      final serverId = await _bridgeTransport!.sendEncryptedMessage(
        recipientKeyHash: request.recipientKeyHash,
        encryptedPayload: request.encryptedPayload,
        ttlHours: request.ttlHours,
        priority: _parsePriority(request.priority),
      );

      print('Relayed message ${request.messageId} for others, server ID: $serverId');

      // Track statistics
      _messagesRelayedForOthers++;
      final payloadSizeMb = request.encryptedPayload.length / (1024 * 1024);
      _bandwidthUsedMb += payloadSizeMb;
      await _database.updateBridgeBandwidthUsage(payloadSizeMb);

      // Check if we've hit bandwidth limit
      if (_bandwidthUsedMb >= maxBandwidth) {
        _setState(BridgeModeState.paused);
        _pauseReason = BridgePauseReason.bandwidthLimit;
      }
    } catch (e) {
      print('Failed to relay message for others: $e');
    }
  }

  RelayPriority _parsePriority(String priority) {
    return switch (priority.toLowerCase()) {
      'urgent' => RelayPriority.urgent,
      'emergency' => RelayPriority.emergency,
      _ => RelayPriority.normal,
    };
  }

  /// Check if we can start bridge mode
  Future<bool> _checkPrerequisites() async {
    // Check battery level
    final batteryLevel = await _battery.batteryLevel;
    final minBattery = _settings?.minBatteryPercent ?? 30;

    if (batteryLevel < minBattery) {
      _setState(BridgeModeState.paused);
      _pauseReason = BridgePauseReason.lowBattery;
      return false;
    }

    // Check bandwidth limit
    final maxBandwidth = _settings?.maxBandwidthMbPerDay ?? 50;
    final usedBandwidth = _settings?.bandwidthUsedTodayMb ?? 0;

    if (usedBandwidth >= maxBandwidth) {
      _setState(BridgeModeState.paused);
      _pauseReason = BridgePauseReason.bandwidthLimit;
      return false;
    }

    // Check internet connectivity
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      _setState(BridgeModeState.paused);
      _pauseReason = BridgePauseReason.noInternet;
      return false;
    }

    return true;
  }

  /// Check battery level and pause if needed
  Future<void> _checkBatteryLevel() async {
    if (_state != BridgeModeState.active) return;

    final batteryLevel = await _battery.batteryLevel;
    final minBattery = _settings?.minBatteryPercent ?? 30;

    if (batteryLevel < minBattery) {
      _setState(BridgeModeState.paused);
      _pauseReason = BridgePauseReason.lowBattery;
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      if (_state == BridgeModeState.active) {
        _setState(BridgeModeState.paused);
        _pauseReason = BridgePauseReason.noInternet;
      }
    } else {
      // Connection restored - try to resume if we were paused for no internet
      if (_state == BridgeModeState.paused &&
          _pauseReason == BridgePauseReason.noInternet) {
        _pauseReason = null;
        start();
      }
    }
  }

  /// Handle incoming message from relay (messages addressed to self)
  Future<void> _handleIncomingMessage(StoredEnvelope envelope) async {
    // Track statistics
    _messagesRelayed++;

    // Track bandwidth (approximate payload size)
    final payloadSizeMb = envelope.envelope.encryptedPayload.length / (1024 * 1024);
    _bandwidthUsedMb += payloadSizeMb;
    await _database.updateBridgeBandwidthUsage(payloadSizeMb);

    // Check if we've hit bandwidth limit
    final maxBandwidth = _settings?.maxBandwidthMbPerDay ?? 50;
    if (_bandwidthUsedMb >= maxBandwidth) {
      _setState(BridgeModeState.paused);
      _pauseReason = BridgePauseReason.bandwidthLimit;
    }

    // TODO: Decrypt and process the message
    // The encrypted payload needs to be decrypted using Noise protocol
    // and then processed as a regular message
  }

  /// Upload pending messages to relay (messages this user wants to send)
  Future<void> _uploadPendingMessages() async {
    if (_state != BridgeModeState.active || _bridgeTransport == null) {
      return;
    }

    try {
      final pendingMessages = await _database.getPendingBridgeMessages();

      for (final msg in pendingMessages) {
        try {
          final serverId = await _bridgeTransport!.sendEncryptedMessage(
            recipientKeyHash: msg.recipientKeyHash,
            encryptedPayload: msg.encryptedPayload,
            ttlHours: msg.ttlHours,
          );

          await _database.updateBridgeMessageStatus(
            messageId: msg.messageId,
            uploadStatus: 'uploaded',
            serverId: serverId,
          );

          // Track bandwidth
          final payloadSizeMb = msg.encryptedPayload.length / (1024 * 1024);
          _bandwidthUsedMb += payloadSizeMb;
          await _database.updateBridgeBandwidthUsage(payloadSizeMb);
        } catch (e) {
          print('Failed to upload message ${msg.messageId}: $e');
          await _database.incrementBridgeMessageRetry(msg.messageId);

          // Mark as failed after 5 retries
          if (msg.retryCount >= 5) {
            await _database.updateBridgeMessageStatus(
              messageId: msg.messageId,
              uploadStatus: 'failed',
            );
          }
        }
      }
    } catch (e) {
      print('Error uploading pending messages: $e');
    }
  }

  void _setState(BridgeModeState newState) {
    _state = newState;
    _stateController.add(newState);

    if (newState != BridgeModeState.paused) {
      _pauseReason = null;
    }
  }

  /// Dispose resources
  void dispose() {
    stop();
    _stateController.close();
    _relayRequestController?.close();
  }
}
