import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import '../../core/providers/providers.dart';

/// Offline status banner with mesh mode prompt
/// 
/// Shows when device is offline with option to enable mesh networking.
/// When mesh is active, shows peer count.
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transportStatusAsync = ref.watch(transportStatusProvider);
    final meshState = ref.watch(meshNetworkProvider);
    final meshPeerCountAsync = ref.watch(meshPeerCountProvider);

    return transportStatusAsync.when(
      data: (status) {
        // If online via internet, don't show banner
        if (status.isOnline) {
          return const SizedBox.shrink();
        }

        // Offline - check if mesh is active
        final meshActive = meshState.status == MeshNetworkStatus.active;
        final peerCount = meshPeerCountAsync.valueOrNull ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: meshActive ? Colors.cyan.shade50 : Colors.orange.shade50,
            border: Border(
              bottom: BorderSide(
                color: meshActive ? Colors.cyan.shade200 : Colors.orange.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                meshActive ? Icons.bluetooth_connected : Icons.wifi_off,
                size: 20,
                color: meshActive ? Colors.cyan.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meshActive 
                          ? 'Mesh Mode Active'
                          : 'You\'re Offline',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: meshActive ? Colors.cyan.shade900 : Colors.orange.shade900,
                      ),
                    ),
                    Text(
                      meshActive
                          ? '$peerCount peer${peerCount == 1 ? '' : 's'} nearby • Messages via Bluetooth'
                          : 'Enable mesh to chat without internet',
                      style: TextStyle(
                        fontSize: 12,
                        color: meshActive ? Colors.cyan.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!meshActive)
                FilledButton.tonal(
                  onPressed: () => _enableMeshMode(ref),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Enable Mesh'),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _enableMeshMode(WidgetRef ref) async {
    try {
      await ref.read(meshNetworkProvider.notifier).start();
    } catch (e) {
      debugPrint('Failed to start mesh: $e');
    }
  }
}
