import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/bridge_mode_service.dart';

/// Banner showing bridge mode status
class BridgeStatusBanner extends ConsumerWidget {
  const BridgeStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get state from bridgeModeService provider
    const state = BridgeModeState.disabled;
    const messagesRelayed = 0;
    const bandwidthUsedMb = 0.0;

    if (state == BridgeModeState.disabled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(state),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _buildIcon(state),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTitle(state),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(state),
                    ),
                  ),
                  Text(
                    _getSubtitle(state, messagesRelayed, bandwidthUsedMb),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTextColor(state).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (state == BridgeModeState.active)
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 20,
              )
            else if (state == BridgeModeState.paused)
              Icon(
                Icons.pause_circle,
                color: Colors.orange.shade700,
                size: 20,
              )
            else if (state == BridgeModeState.error)
              Icon(
                Icons.error,
                color: Colors.red.shade700,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BridgeModeState state) {
    final color = _getIconColor(state);

    if (state == BridgeModeState.starting || state == BridgeModeState.stopping) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Icon(
      Icons.hub,
      color: color,
      size: 24,
    );
  }

  Color _getBackgroundColor(BridgeModeState state) {
    switch (state) {
      case BridgeModeState.active:
        return Colors.green.shade50;
      case BridgeModeState.paused:
        return Colors.orange.shade50;
      case BridgeModeState.error:
        return Colors.red.shade50;
      case BridgeModeState.starting:
      case BridgeModeState.stopping:
        return Colors.blue.shade50;
      case BridgeModeState.disabled:
        return Colors.grey.shade100;
    }
  }

  Color _getTextColor(BridgeModeState state) {
    switch (state) {
      case BridgeModeState.active:
        return Colors.green.shade900;
      case BridgeModeState.paused:
        return Colors.orange.shade900;
      case BridgeModeState.error:
        return Colors.red.shade900;
      case BridgeModeState.starting:
      case BridgeModeState.stopping:
        return Colors.blue.shade900;
      case BridgeModeState.disabled:
        return Colors.grey.shade700;
    }
  }

  Color _getIconColor(BridgeModeState state) {
    switch (state) {
      case BridgeModeState.active:
        return Colors.green.shade700;
      case BridgeModeState.paused:
        return Colors.orange.shade700;
      case BridgeModeState.error:
        return Colors.red.shade700;
      case BridgeModeState.starting:
      case BridgeModeState.stopping:
        return Colors.blue.shade700;
      case BridgeModeState.disabled:
        return Colors.grey.shade500;
    }
  }

  String _getTitle(BridgeModeState state) {
    switch (state) {
      case BridgeModeState.active:
        return 'Bridge Mode Active';
      case BridgeModeState.paused:
        return 'Bridge Mode Paused';
      case BridgeModeState.error:
        return 'Bridge Mode Error';
      case BridgeModeState.starting:
        return 'Starting Bridge Mode...';
      case BridgeModeState.stopping:
        return 'Stopping Bridge Mode...';
      case BridgeModeState.disabled:
        return 'Bridge Mode Disabled';
    }
  }

  String _getSubtitle(BridgeModeState state, int messages, double bandwidth) {
    switch (state) {
      case BridgeModeState.active:
        return 'Relayed $messages messages (${bandwidth.toStringAsFixed(1)} MB)';
      case BridgeModeState.paused:
        return 'Waiting for conditions to resume';
      case BridgeModeState.error:
        return 'Tap to retry';
      case BridgeModeState.starting:
        return 'Connecting to relay server...';
      case BridgeModeState.stopping:
        return 'Cleaning up...';
      case BridgeModeState.disabled:
        return '';
    }
  }
}

/// Compact bridge status indicator for use in app bar or status area
class BridgeStatusIndicator extends ConsumerWidget {
  const BridgeStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get state from bridgeModeService provider
    const state = BridgeModeState.disabled;

    if (state == BridgeModeState.disabled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(state).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hub,
            size: 16,
            color: _getColor(state),
          ),
          const SizedBox(width: 4),
          Text(
            _getLabel(state),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getColor(state),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(BridgeModeState state) {
    switch (state) {
      case BridgeModeState.active:
        return Colors.green;
      case BridgeModeState.paused:
        return Colors.orange;
      case BridgeModeState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLabel(BridgeModeState state) {
    switch (state) {
      case BridgeModeState.active:
        return 'Bridge';
      case BridgeModeState.paused:
        return 'Paused';
      case BridgeModeState.error:
        return 'Error';
      default:
        return '';
    }
  }
}
