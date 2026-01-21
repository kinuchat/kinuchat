import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/demo_providers.dart';
import '../../../data/repositories/rally_repository.dart';
import '../../widgets/rally_map_view.dart';
import 'rally_channel_screen.dart';

/// Rally Mode main screen
///
/// Displays nearby Rally channels and allows users to:
/// - Discover channels based on location
/// - Create new channels
/// - Join existing channels
/// - View channel participants
class RallyScreen extends ConsumerStatefulWidget {
  const RallyScreen({super.key});

  @override
  ConsumerState<RallyScreen> createState() => _RallyScreenState();
}

class _RallyScreenState extends ConsumerState<RallyScreen> {
  bool _isMapView = false;

  @override
  Widget build(BuildContext context) {
    final locationPermissionAsync = ref.watch(locationPermissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rally Mode'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _isMapView = !_isMapView),
            tooltip: _isMapView ? 'List View' : 'Map View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(nearbyRallyChannelsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showRallyInfo,
          ),
        ],
      ),
      body: ref.watch(appDemoModeProvider)
          ? _buildChannelList()  // Skip permission check in demo mode
          : locationPermissionAsync.when(
              data: (permission) {
                if (permission == LocationPermission.denied ||
                    permission == LocationPermission.deniedForever) {
                  return _buildPermissionRequest();
                }
                return _isMapView ? const RallyMapView() : _buildChannelList();
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildError(error),
            ),
      floatingActionButton: _buildCreateChannelButton(),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Location Access Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Rally Mode uses your location to discover nearby channels and connect you with people in your area.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.location_on),
              label: const Text('Enable Location'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelList() {
    final demoMode = ref.watch(appDemoModeProvider);

    // Show demo channels when in demo mode
    if (demoMode) {
      final demoChannels = ref.watch(demoRallyChannelsProvider);
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demoChannels.length,
        itemBuilder: (context, index) {
          final channel = demoChannels[index];
          return DemoRallyChannelListItem(channel: channel);
        },
      );
    }

    final channelsAsync = ref.watch(nearbyRallyChannelsProvider);

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(nearbyRallyChannelsProvider);
            await ref.read(nearbyRallyChannelsProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              return RallyChannelListItem(
                channel: channels[index],
                onTap: () => _joinChannel(channels[index]),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildError(error),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Rally Channels Nearby',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Be the first to create a Rally channel in your area!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _createChannel,
              icon: const Icon(Icons.add),
              label: const Text('Create Channel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load channels',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.invalidate(nearbyRallyChannelsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildCreateChannelButton() {
    final locationPermission = ref.watch(locationPermissionProvider).value;
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever) {
      return null; // Don't show button if no permission
    }

    return FloatingActionButton.extended(
      onPressed: _createChannel,
      icon: const Icon(Icons.add),
      label: const Text('Create Channel'),
    );
  }

  Future<void> _requestPermission() async {
    final newPermission = await requestLocationPermission();
    if (newPermission == LocationPermission.whileInUse ||
        newPermission == LocationPermission.always) {
      ref.invalidate(locationPermissionProvider);
      ref.invalidate(nearbyRallyChannelsProvider);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required for Rally Mode'),
        ),
      );
    }
  }

  Future<void> _createChannel() async {
    try {
      final locationAsync = await ref.read(currentLocationProvider.future);
      if (locationAsync == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get your location'),
          ),
        );
        return;
      }

      final repository = ref.read(rallyRepositoryProvider);
      final userId = ref.read(rallyUserIdProvider);
      final displayName = ref.read(rallyDisplayNameProvider);
      final identityType = ref.read(rallyIdentityTypeProvider);

      final channel = await repository.createOrJoinChannelAt(
        latitude: locationAsync.latitude,
        longitude: locationAsync.longitude,
        userId: userId,
        displayName: displayName,
        identityType: identityType,
      );

      if (!mounted) return;

      // Navigate to channel
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RallyChannelScreen(channel: channel),
        ),
      );

      // Refresh channel list
      ref.invalidate(nearbyRallyChannelsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create channel: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _joinChannel(RallyChannel channel) async {
    try {
      final repository = ref.read(rallyRepositoryProvider);
      final userId = ref.read(rallyUserIdProvider);
      final displayName = ref.read(rallyDisplayNameProvider);
      final identityType = ref.read(rallyIdentityTypeProvider);

      await repository.joinExistingChannel(
        channelId: channel.id,
        userId: userId,
        displayName: displayName,
        identityType: identityType,
      );

      if (!mounted) return;

      // Navigate to channel
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

  void _showRallyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Rally Mode'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rally Mode creates location-based public channels where you can connect with people nearby.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('• Channels are tied to your location (~1.2km radius)'),
              Text('• Messages expire after 4 hours'),
              Text('• Choose to be anonymous, pseudonymous, or verified'),
              Text('• Channels refresh every 4 hours'),
              SizedBox(height: 16),
              Text(
                'Privacy Note: Your exact location is never shared. Only the general area is used for channel discovery.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Rally channel list item widget
class RallyChannelListItem extends StatelessWidget {
  const RallyChannelListItem({
    required this.channel,
    required this.onTap,
    super.key,
  });

  final RallyChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Icon(
            Icons.location_on,
            color: Colors.purple.shade700,
          ),
        ),
        title: Text(channel.name),
        subtitle: Text(
          '${channel.formattedDistance} • ${channel.participantCount} active',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Demo rally channel list item widget
class DemoRallyChannelListItem extends StatelessWidget {
  const DemoRallyChannelListItem({
    required this.channel,
    super.key,
  });

  final DemoRallyChannel channel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Icon(
            Icons.location_on,
            color: Colors.purple.shade700,
          ),
        ),
        title: Text(channel.name),
        subtitle: Text(
          '${channel.formattedDistance} • ${channel.participantCount} active',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Demo channel: ${channel.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
