import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

/// Mesh status banner that shows mesh network status and peer count
class MeshStatusBanner extends ConsumerWidget {
  const MeshStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if database is ready first
    final dbPathAsync = ref.watch(databasePathProvider);

    // Wait for database to be ready
    if (!dbPathAsync.hasValue) {
      return const SizedBox.shrink();
    }

    final meshState = ref.watch(meshNetworkProvider);
    final peerCountAsync = ref.watch(meshPeerCountProvider);

    // Only show if mesh is active
    if (meshState.status != MeshNetworkStatus.active) {
      return const SizedBox.shrink();
    }

    return peerCountAsync.when(
      data: (peerCount) {
        if (peerCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.cyan.shade50,
            border: Border(
              bottom: BorderSide(
                color: Colors.cyan.shade100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cast_connected,
                size: 20,
                color: Colors.cyan.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mesh Active • $peerCount peer${peerCount == 1 ? '' : 's'} nearby',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.cyan.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.cyan.shade700,
                ),
                onPressed: () {
                  _showMeshInfo(context, peerCount);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showMeshInfo(BuildContext context, int peerCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cast, color: Colors.cyan),
            SizedBox(width: 8),
            Text('Mesh Network'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are connected to $peerCount nearby peer${peerCount == 1 ? '' : 's'} via Bluetooth mesh networking.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Messages sent over mesh are:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('End-to-end encrypted'),
            _buildFeatureItem('Internet-free'),
            _buildFeatureItem('Multi-hop (up to 7 hops)'),
            _buildFeatureItem('Within ~30m range'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
