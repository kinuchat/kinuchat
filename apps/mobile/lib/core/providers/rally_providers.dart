import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/database/app_database.dart';
import 'package:meshlink_core/utils/anonymous_identity.dart';
import '../../data/repositories/rally_repository.dart';
import 'database_providers.dart';
import 'identity_providers.dart';
import 'location_providers.dart';

// ============================================================================
// Repository Provider
// ============================================================================

/// Rally repository provider
///
/// Provides access to Rally channel operations.
final rallyRepositoryProvider = Provider<RallyRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return RallyRepository(database: database);
});

// ============================================================================
// Channel Discovery Providers
// ============================================================================

/// Nearby Rally channels provider
///
/// Automatically discovers channels near the user's current location.
/// Returns empty list if location permission is not granted.
///
/// Updates when:
/// - Location changes
/// - New channels are created nearby
final nearbyRallyChannelsProvider = FutureProvider<List<RallyChannel>>((ref) async {
  final repository = ref.watch(rallyRepositoryProvider);

  // Get current location
  final locationAsync = await ref.watch(currentLocationProvider.future);
  if (locationAsync == null) {
    return []; // No location permission
  }

  // Discover channels within 5km
  return await repository.discoverChannelsNear(
    latitude: locationAsync.latitude,
    longitude: locationAsync.longitude,
    radiusMeters: 5000,
  );
});

/// Selected Rally channel ID provider
///
/// Tracks which channel the user is currently viewing.
final selectedRallyChannelProvider = StateProvider<String?>((ref) => null);

/// Selected Rally channel provider
///
/// Provides the full channel object for the selected channel.
final selectedRallyChannelDetailsProvider = FutureProvider<RallyChannel?>((ref) async {
  final channelId = ref.watch(selectedRallyChannelProvider);
  if (channelId == null) return null;

  final repository = ref.watch(rallyRepositoryProvider);
  return await repository.getChannelById(channelId);
});

// ============================================================================
// Message Providers
// ============================================================================

/// Messages for selected Rally channel
///
/// Provides messages for the currently selected channel.
/// Automatically filters out expired messages.
final rallyMessagesProvider = FutureProvider.family<List<MessageEntity>, String>(
  (ref, channelId) async {
    final repository = ref.watch(rallyRepositoryProvider);
    return await repository.getChannelMessages(channelId, limit: 100);
  },
);

/// Channel members provider
///
/// Provides list of members for a specific channel.
final rallyChannelMembersProvider = FutureProvider.family<List<RallyChannelMemberEntity>, String>(
  (ref, channelId) async {
    final repository = ref.watch(rallyRepositoryProvider);
    return await repository.getChannelMembers(channelId);
  },
);

// ============================================================================
// Identity Providers
// ============================================================================

/// Current Rally identity type provider
///
/// Tracks which type of identity the user wants to use in Rally Mode.
/// Default: anonymous
final rallyIdentityTypeProvider = StateProvider<RallyIdentityType>((ref) {
  return RallyIdentityType.anonymous;
});

/// Current Rally display name provider
///
/// Generates or retrieves the display name based on selected identity type.
final rallyDisplayNameProvider = Provider<String>((ref) {
  final identityType = ref.watch(rallyIdentityTypeProvider);

  switch (identityType) {
    case RallyIdentityType.anonymous:
      // Generate a new anonymous identity each time
      return AnonymousIdentity.generate();

    case RallyIdentityType.pseudonymous:
      // TODO: Get from user settings/preferences
      return 'User'; // Placeholder

    case RallyIdentityType.verified:
      // Use identity from cloud account
      final identity = ref.watch(identityProvider).value;
      return identity?.displayName ?? 'User';
  }
});

/// Current Rally user ID provider
///
/// Generates or retrieves the user ID based on selected identity type.
final rallyUserIdProvider = Provider<String>((ref) {
  final identityType = ref.watch(rallyIdentityTypeProvider);

  switch (identityType) {
    case RallyIdentityType.anonymous:
      // Generate anonymous user ID
      return AnonymousIdentity.generateUserId();

    case RallyIdentityType.pseudonymous:
    case RallyIdentityType.verified:
      // Use mesh peer ID
      final identity = ref.watch(identityProvider).value;
      return identity?.meshPeerIdHex ?? AnonymousIdentity.generateUserId();
  }
});

// ============================================================================
// Background Tasks
// ============================================================================

/// Periodic cleanup of expired Rally messages
///
/// Runs every 10 minutes to delete messages older than their channel's TTL.
final rallyCleanupProvider = StreamProvider<int>((ref) async* {
  final repository = ref.watch(rallyRepositoryProvider);

  while (true) {
    await Future.delayed(const Duration(minutes: 10));

    try {
      final deletedCount = await repository.cleanupExpiredMessages();
      yield deletedCount;
    } catch (e) {
      yield 0;
    }
  }
});

// ============================================================================
// Action Providers (for UI interactions)
// ============================================================================

/// Create or join Rally channel action
///
/// Creates a new channel at the user's current location or joins existing one.
///
/// Example:
/// ```dart
/// final result = await ref.read(createOrJoinRallyChannelProvider(
///   latitude: 37.7749,
///   longitude: -122.4194,
/// ).future);
/// ```
final createOrJoinRallyChannelProvider = FutureProvider.family<RallyChannel, ({double latitude, double longitude})>(
  (ref, location) async {
    final repository = ref.watch(rallyRepositoryProvider);
    final userId = ref.read(rallyUserIdProvider);
    final displayName = ref.read(rallyDisplayNameProvider);
    final identityType = ref.read(rallyIdentityTypeProvider);

    return await repository.createOrJoinChannelAt(
      latitude: location.latitude,
      longitude: location.longitude,
      userId: userId,
      displayName: displayName,
      identityType: identityType,
    );
  },
);

/// Post message to Rally channel action
///
/// Example:
/// ```dart
/// await ref.read(postRallyMessageProvider({
///   channelId: 'rally_123',
///   content: 'Hello!',
/// }).future);
/// ```
final postRallyMessageProvider = FutureProvider.family<void, ({String channelId, String content})>(
  (ref, params) async {
    final repository = ref.watch(rallyRepositoryProvider);
    final userId = ref.read(rallyUserIdProvider);
    final locationAsync = await ref.read(currentLocationProvider.future);

    await repository.postToChannel(
      channelId: params.channelId,
      content: params.content,
      senderId: userId,
      latitude: locationAsync?.latitude,
      longitude: locationAsync?.longitude,
    );

    // Invalidate messages to trigger refresh
    ref.invalidate(rallyMessagesProvider(params.channelId));
  },
);

/// Leave Rally channel action
///
/// Example:
/// ```dart
/// await ref.read(leaveRallyChannelProvider('rally_123').future);
/// ```
final leaveRallyChannelProvider = FutureProvider.family<void, String>(
  (ref, channelId) async {
    final repository = ref.watch(rallyRepositoryProvider);
    final userId = ref.read(rallyUserIdProvider);

    await repository.leaveChannel(
      channelId: channelId,
      userId: userId,
    );

    // Clear selected channel if it's the one we just left
    if (ref.read(selectedRallyChannelProvider) == channelId) {
      ref.read(selectedRallyChannelProvider.notifier).state = null;
    }

    // Invalidate nearby channels to update participant count
    ref.invalidate(nearbyRallyChannelsProvider);
  },
);

/// Report user action
///
/// Example:
/// ```dart
/// await ref.read(reportRallyUserProvider({
///   reportedUserId: 'baduser123',
///   category: 'spam',
/// }).future);
/// ```
final reportRallyUserProvider = FutureProvider.family<void, ({String reportedUserId, String category, String? messageId, String? notes})>(
  (ref, params) async {
    final repository = ref.watch(rallyRepositoryProvider);
    final reporterId = ref.read(rallyUserIdProvider);

    await repository.reportUser(
      reporterId: reporterId,
      reportedUserId: params.reportedUserId,
      category: params.category,
      messageId: params.messageId,
      notes: params.notes,
    );
  },
);

// ============================================================================
// UI State Providers
// ============================================================================

/// Rally screen loading state
///
/// Tracks if the Rally screen is currently loading data.
final rallyLoadingProvider = StateProvider<bool>((ref) => false);

/// Rally error message provider
///
/// Stores error messages to display in the UI.
final rallyErrorProvider = StateProvider<String?>((ref) => null);

/// Rally refresh trigger
///
/// Increment this to manually trigger a refresh of Rally data.
final rallyRefreshTriggerProvider = StateProvider<int>((ref) => 0);
