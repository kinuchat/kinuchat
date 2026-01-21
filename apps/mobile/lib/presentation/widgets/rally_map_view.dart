import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/providers.dart';
import '../../data/repositories/rally_repository.dart';
import '../screens/rally/rally_channel_screen.dart';

/// Rally map view widget
///
/// Displays a map with Rally channel markers.
/// Users can tap markers to join channels.
class RallyMapView extends ConsumerStatefulWidget {
  const RallyMapView({super.key});

  @override
  ConsumerState<RallyMapView> createState() => _RallyMapViewState();
}

class _RallyMapViewState extends ConsumerState<RallyMapView> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);
    final channelsAsync = ref.watch(nearbyRallyChannelsProvider);

    return locationAsync.when(
      data: (location) {
        if (location == null) {
          return _buildNoLocation();
        }

        return channelsAsync.when(
          data: (channels) => _buildMap(
            userLocation: LatLng(location.latitude, location.longitude),
            channels: channels,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Failed to load channels: $error'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildNoLocation(),
    );
  }

  Widget _buildNoLocation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Location not available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMap({
    required LatLng userLocation,
    required List<RallyChannel> channels,
  }) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userLocation,
        initialZoom: 13.0,
        minZoom: 10.0,
        maxZoom: 18.0,
        onTap: (_, __) {
          // Close any open popups
        },
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.kinuchat.app',
          maxZoom: 19,
        ),

        // User location marker
        MarkerLayer(
          markers: [
            Marker(
              point: userLocation,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 32,
              ),
            ),
          ],
        ),

        // Rally channel markers
        MarkerLayer(
          markers: channels.map((channel) {
            return Marker(
              point: LatLng(channel.latitude, channel.longitude),
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () => _onChannelTapped(channel),
                child: _buildChannelMarker(channel),
              ),
            );
          }).toList(),
        ),

        // Attribution
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {}, // Could open OSM website
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelMarker(RallyChannel channel) {
    // Color based on participant count
    final color = _getMarkerColor(channel.participantCount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              if (channel.participantCount > 0)
                Text(
                  '${channel.participantCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getMarkerColor(int participantCount) {
    if (participantCount == 0) {
      return Colors.grey;
    } else if (participantCount < 5) {
      return Colors.orange;
    } else if (participantCount < 10) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  Future<void> _onChannelTapped(RallyChannel channel) async {
    // Show bottom sheet with channel info
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => _ChannelBottomSheet(channel: channel),
    );

    if (result == true && mounted) {
      // Join and navigate to channel
      final repository = ref.read(rallyRepositoryProvider);
      final userId = ref.read(rallyUserIdProvider);
      final displayName = ref.read(rallyDisplayNameProvider);
      final identityType = ref.read(rallyIdentityTypeProvider);

      try {
        await repository.joinExistingChannel(
          channelId: channel.id,
          userId: userId,
          displayName: displayName,
          identityType: identityType,
        );

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RallyChannelScreen(channel: channel),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join channel: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Bottom sheet shown when tapping a channel marker
class _ChannelBottomSheet extends StatelessWidget {
  const _ChannelBottomSheet({required this.channel});

  final RallyChannel channel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${channel.formattedDistance} away',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                icon: Icons.people,
                label: '${channel.participantCount} active',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.timer,
                label: 'Expires in ${_formatTTL(channel)}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Join'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTTL(RallyChannel channel) {
    final remaining = channel.timeUntilExpiration;
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h';
    } else {
      return '${remaining.inMinutes}m';
    }
  }
}

/// Info chip widget
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
