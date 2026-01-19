import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/transport/transport_manager.dart';
import '../../core/providers/providers.dart';

/// Transport indicator widget that shows current transport mode
class TransportIndicator extends ConsumerWidget {
  const TransportIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if database is ready first
    final dbPathAsync = ref.watch(databasePathProvider);

    // Wait for database to be ready
    if (!dbPathAsync.hasValue) {
      return const SizedBox.shrink();
    }

    final statusAsync = ref.watch(transportStatusProvider);

    return statusAsync.when(
      data: (status) {
        final transport = status.currentTransport;
        final icon = _getTransportIcon(transport);
        final label = _getTransportLabel(transport);
        final color = _getTransportColor(transport, status);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  IconData _getTransportIcon(Transport transport) {
    switch (transport) {
      case Transport.cloud:
        return Icons.cloud;
      case Transport.mesh:
        return Icons.cast;
      case Transport.bridge:
        return Icons.swap_horizontal_circle;
    }
  }

  String _getTransportLabel(Transport transport) {
    switch (transport) {
      case Transport.cloud:
        return 'Cloud';
      case Transport.mesh:
        return 'Mesh';
      case Transport.bridge:
        return 'Bridge';
    }
  }

  Color _getTransportColor(Transport transport, TransportStatus status) {
    switch (transport) {
      case Transport.cloud:
        return status.isOnline ? Colors.blue : Colors.grey;
      case Transport.mesh:
        return status.meshPeerCount > 0 ? Colors.cyan : Colors.grey;
      case Transport.bridge:
        return status.isBridgeActive ? Colors.amber : Colors.grey;
    }
  }
}
