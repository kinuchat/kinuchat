import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/transport/bridge_transport_impl.dart';

import '../../data/services/bridge_mode_service.dart';
import 'database_providers.dart';
import 'identity_providers.dart';

// Stats model for UI consumption
class BridgeStats {
  final int messagesRelayed;
  final double bandwidthUsedMb;
  final int nearbyPeers;

  const BridgeStats({
    this.messagesRelayed = 0,
    this.bandwidthUsedMb = 0.0,
    this.nearbyPeers = 0,
  });
}

// Demo mode toggle (for screenshots)
final bridgeDemoModeProvider = StateProvider<bool>((ref) => false);

// Demo stats for screenshots
final bridgeDemoStatsProvider = Provider<BridgeStats>((ref) {
  return const BridgeStats(
    messagesRelayed: 12,
    bandwidthUsedMb: 2.3,
    nearbyPeers: 47,
  );
});

// Relay server URL constant
const _relayServerUrl = 'https://kinu-relay.fly.dev';

// Bridge transport provider
final bridgeTransportProvider = Provider<BridgeTransportImpl?>((ref) {
  final identity = ref.watch(identityProvider).value;
  if (identity == null) return null;

  // Use X25519 exchange key (base64 encoded) per spec section 6.4
  final exchangeKeyBase64 = base64.encode(identity.exchangeKeyPair.publicKey);

  return BridgeTransportImpl(
    relayServerUrl: _relayServerUrl,
    myPublicKey: exchangeKeyBase64,
  );
});

// Service provider
final bridgeModeServiceProvider = Provider<BridgeModeService?>((ref) {
  final dbAsync = ref.watch(databasePathProvider);
  final identity = ref.watch(identityProvider).value;

  if (!dbAsync.hasValue || identity == null) return null;

  // Use X25519 exchange key (base64 encoded) per spec section 6.4
  final exchangeKeyBase64 = base64.encode(identity.exchangeKeyPair.publicKey);

  final db = ref.watch(databaseProvider);
  return BridgeModeService(
    database: db,
    relayServerUrl: _relayServerUrl,
    myPublicKey: exchangeKeyBase64,
  );
});

// State notifier for lifecycle
class BridgeModeNotifier extends StateNotifier<BridgeModeState> {
  BridgeModeNotifier(this._service) : super(BridgeModeState.disabled) {
    _init();
  }

  final BridgeModeService? _service;

  void _init() {
    _service?.stateStream.listen((s) => state = s);
    _service?.initialize();
  }

  Future<void> start() async => await _service?.start();
  Future<void> stop() async => await _service?.stop();

  Future<void> updateSettings({
    bool? isEnabled,
    bool? relayForContactsOnly,
    int? maxBandwidthMbPerDay,
    int? minBatteryPercent,
  }) async {
    await _service?.updateSettings(
      isEnabled: isEnabled,
      relayForContactsOnly: relayForContactsOnly,
      maxBandwidthMbPerDay: maxBandwidthMbPerDay,
      minBatteryPercent: minBatteryPercent,
    );
  }
}

final bridgeModeProvider = StateNotifierProvider<BridgeModeNotifier, BridgeModeState>((ref) {
  final service = ref.watch(bridgeModeServiceProvider);
  return BridgeModeNotifier(service);
});

// Stats provider (polls service every 2 seconds)
final bridgeStatsProvider = StreamProvider<BridgeStats>((ref) async* {
  final service = ref.watch(bridgeModeServiceProvider);
  final demoMode = ref.watch(bridgeDemoModeProvider);

  if (demoMode) {
    yield ref.read(bridgeDemoStatsProvider);
    return;
  }

  while (true) {
    await Future.delayed(const Duration(seconds: 2));
    if (service != null) {
      yield BridgeStats(
        messagesRelayed: service.messagesRelayed,
        bandwidthUsedMb: service.bandwidthUsedMb,
        nearbyPeers: 0, // TODO: Get from mesh peer count
      );
    } else {
      yield const BridgeStats();
    }
  }
});

// Settings provider
final bridgeSettingsProvider = FutureProvider<BridgeSettingsData?>((ref) async {
  final service = ref.watch(bridgeModeServiceProvider);
  if (service == null) return null;

  final settings = service.settings;
  if (settings == null) return null;

  return BridgeSettingsData(
    isEnabled: settings.isEnabled,
    relayForContactsOnly: settings.relayForContactsOnly,
    maxBandwidthMbPerDay: settings.maxBandwidthMbPerDay,
    minBatteryPercent: settings.minBatteryPercent,
  );
});

// Simple settings data class
class BridgeSettingsData {
  final bool isEnabled;
  final bool relayForContactsOnly;
  final int maxBandwidthMbPerDay;
  final int minBatteryPercent;

  const BridgeSettingsData({
    this.isEnabled = false,
    this.relayForContactsOnly = false,
    this.maxBandwidthMbPerDay = 10,
    this.minBatteryPercent = 30,
  });
}

// Computed helpers
final isBridgeActiveProvider = Provider<bool>((ref) {
  final demoMode = ref.watch(bridgeDemoModeProvider);
  if (demoMode) return true;
  return ref.watch(bridgeModeProvider) == BridgeModeState.active;
});

final isBridgePausedProvider = Provider<bool>((ref) {
  return ref.watch(bridgeModeProvider) == BridgeModeState.paused;
});
