import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/mesh/ble_service.dart';
import 'package:meshlink_core/mesh/routing_engine.dart';
import 'package:meshlink_core/mesh/mesh_transport_impl.dart';
import '../../data/services/mesh_background_service.dart';
import '../../data/services/bridge_mode_service.dart';
import 'database_providers.dart';
import 'identity_providers.dart';
import 'bridge_providers.dart';

/// Provider for BLE service
final bleServiceProvider = Provider<BleService>((ref) {
  return BleService();
});

/// Provider for routing engine
final routingEngineProvider = Provider<RoutingEngine>((ref) {
  final database = ref.watch(databaseProvider);
  return RoutingEngine(database);
});

/// Provider for mesh transport implementation
final meshTransportProvider = Provider<MeshTransportImpl?>((ref) {
  final identityState = ref.watch(identityProvider);

  return identityState.maybeWhen(
    data: (identity) {
      if (identity == null) return null;

      final bleService = ref.watch(bleServiceProvider);
      final routingEngine = ref.watch(routingEngineProvider);
      final database = ref.watch(databaseProvider);

      return MeshTransportImpl(
        bleService: bleService,
        routingEngine: routingEngine,
        database: database,
        localIdentity: identity,
      );
    },
    orElse: () => null,
  );
});

/// StateNotifier for managing mesh network state
class MeshNetworkNotifier extends StateNotifier<MeshNetworkState> {
  MeshNetworkNotifier(this._transport) : super(const MeshNetworkState());

  final MeshTransportImpl? _transport;

  /// Start mesh networking
  Future<void> start() async {
    if (_transport == null) {
      state = state.copyWith(
        status: MeshNetworkStatus.unavailable,
        error: 'No identity available',
      );
      return;
    }

    state = state.copyWith(status: MeshNetworkStatus.starting);

    try {
      await _transport.start();

      // Start background service to keep mesh active when app is backgrounded
      // TODO: Fix foreground service notification for Android 14+
      // Temporarily disabled due to crash on Android 14+
      // try {
      //   await _transport.startBackgroundService();
      // } catch (e) {
      //   print('Background service failed to start: $e');
      // }

      state = state.copyWith(
        status: MeshNetworkStatus.active,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        status: MeshNetworkStatus.error,
        error: error.toString(),
      );
    }
  }

  /// Stop mesh networking
  Future<void> stop() async {
    if (_transport == null) return;

    state = state.copyWith(status: MeshNetworkStatus.stopping);

    try {
      await _transport.stop();

      // Stop background service
      try {
        await _transport.stopBackgroundService();
      } catch (e) {
        // Ignore errors stopping background service
      }

      state = state.copyWith(
        status: MeshNetworkStatus.inactive,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        status: MeshNetworkStatus.error,
        error: error.toString(),
      );
    }
  }

  /// Update peer count
  void updatePeerCount(int count) {
    state = state.copyWith(peerCount: count);
  }
}

/// Mesh network state
class MeshNetworkState {
  final MeshNetworkStatus status;
  final int peerCount;
  final String? error;

  const MeshNetworkState({
    this.status = MeshNetworkStatus.inactive,
    this.peerCount = 0,
    this.error,
  });

  MeshNetworkState copyWith({
    MeshNetworkStatus? status,
    int? peerCount,
    String? error,
  }) {
    return MeshNetworkState(
      status: status ?? this.status,
      peerCount: peerCount ?? this.peerCount,
      error: error,
    );
  }
}

/// Mesh network status
enum MeshNetworkStatus {
  inactive,
  starting,
  active,
  stopping,
  error,
  unavailable,
}

/// Provider for mesh network state
final meshNetworkProvider =
    StateNotifierProvider<MeshNetworkNotifier, MeshNetworkState>((ref) {
  final transport = ref.watch(meshTransportProvider);
  return MeshNetworkNotifier(transport);
});

/// Provider for mesh peer count
final meshPeerCountProvider = StreamProvider<int>((ref) async* {
  final database = ref.watch(databaseProvider);

  // Poll for peer count every 5 seconds
  while (true) {
    await Future.delayed(const Duration(seconds: 5));

    try {
      final peers = await database.getConnectedMeshPeers();
      final peerCount = peers.length;

      yield peerCount;

      // Update mesh network state
      ref.read(meshNetworkProvider.notifier).updatePeerCount(peerCount);

      // Update background service notification
      await MeshBackgroundService.updatePeerCount(peerCount);
    } catch (e) {
      yield 0;
    }
  }
});

/// Provider to check if mesh is available
final meshAvailableProvider = Provider<bool>((ref) {
  final transport = ref.watch(meshTransportProvider);
  return transport != null;
});

/// Provider to check if mesh is active
final meshActiveProvider = Provider<bool>((ref) {
  final state = ref.watch(meshNetworkProvider);
  return state.status == MeshNetworkStatus.active;
});

/// Provider that wires mesh relay requests to bridge mode service
/// This enables the AirTag-style relay functionality
final meshBridgeRelayProvider = Provider<StreamSubscription?>((ref) {
  final meshTransport = ref.watch(meshTransportProvider);
  final bridgeModeService = ref.watch(bridgeModeServiceProvider);

  if (meshTransport == null || bridgeModeService == null) {
    return null;
  }

  // Subscribe to relay requests from mesh and forward to bridge mode service
  final subscription = meshTransport.relayRequests.listen((meshRequest) {
    // Convert MeshRelayRequest to RelayRequest for bridge mode service
    final relayRequest = RelayRequest(
      messageId: meshRequest.messageId,
      recipientKeyHash: meshRequest.recipientKeyHash,
      encryptedPayload: meshRequest.encryptedPayload,
      ttlHours: meshRequest.ttlHours,
      priority: meshRequest.priority,
      senderPeerId: meshRequest.senderPeerId,
    );

    bridgeModeService.submitRelayRequest(relayRequest);
  });

  // Clean up on dispose
  ref.onDispose(() {
    subscription.cancel();
  });

  return subscription;
});
