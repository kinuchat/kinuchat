import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:meshlink_core/database/app_database.dart';
import 'package:meshlink_core/transport/bridge_transport.dart';
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

/// Bridge mode service - manages the bridge relay lifecycle
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
  Timer? _pollTimer;
  Timer? _uploadTimer;

  // Statistics
  int _messagesRelayed = 0;
  double _bandwidthUsedMb = 0;

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

  /// Messages relayed this session
  int get messagesRelayed => _messagesRelayed;

  /// Bandwidth used today (MB)
  double get bandwidthUsedMb => _bandwidthUsedMb;

  /// Stream of state changes
  final _stateController = StreamController<BridgeModeState>.broadcast();
  Stream<BridgeModeState> get stateStream => _stateController.stream;

  /// Initialize and load settings
  Future<void> initialize() async {
    _settings = await _database.getBridgeSettings();

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

      // Connect WebSocket for real-time messages
      await _bridgeTransport!.connectWebSocket();

      // Start listening for incoming messages
      _messageSubscription = _bridgeTransport!.messageStream.listen(
        _handleIncomingMessage,
        onError: (error) {
          print('Bridge message error: $error');
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

      _batterySubscription = null;
      _connectivitySubscription = null;
      _messageSubscription = null;

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

  /// Queue a message for relay
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

  /// Handle incoming message from relay
  Future<void> _handleIncomingMessage(StoredEnvelope envelope) async {
    // TODO: Decrypt and process the message
    // For now, just track statistics
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
  }

  /// Upload pending messages to relay
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
  }
}
