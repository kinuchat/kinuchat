import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/database/app_database.dart';

import '../../data/repositories/group_repository.dart';
import '../../data/services/matrix_service.dart';
import 'database_providers.dart';
import 'matrix_providers.dart';

/// Provider for the GroupRepository
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final matrixService = ref.watch(matrixServiceProvider);
  final database = ref.watch(databaseProvider);

  return GroupRepository(
    matrixService: matrixService,
    database: database,
  );
});

/// Provider for the list of groups
final groupsProvider =
    FutureProvider.autoDispose<List<ConversationEntity>>((ref) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getAllGroups();
});

/// Provider for a specific group's info
final groupInfoProvider =
    FutureProvider.family.autoDispose<GroupInfo?, String>((ref, groupId) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupInfo(groupId);
});

/// Provider for a group's members
final groupMembersProvider = FutureProvider.family
    .autoDispose<List<GroupMemberInfo>, String>((ref, groupId) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getMembers(groupId);
});

/// State notifier for creating a group
class CreateGroupNotifier extends StateNotifier<AsyncValue<ConversationEntity?>> {
  final GroupRepository _repository;

  CreateGroupNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<ConversationEntity?> createGroup({
    required String name,
    List<String>? memberIds,
    String? topic,
  }) async {
    state = const AsyncValue.loading();

    try {
      final group = await _repository.createGroup(
        name: name,
        memberIds: memberIds,
        topic: topic,
      );
      state = AsyncValue.data(group);
      return group;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for creating groups
final createGroupProvider =
    StateNotifierProvider.autoDispose<CreateGroupNotifier, AsyncValue<ConversationEntity?>>(
        (ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return CreateGroupNotifier(repository);
});

/// State notifier for group actions (invite, kick, leave, etc.)
class GroupActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final GroupRepository _repository;

  GroupActionsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> inviteMember({
    required String groupId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.inviteMember(groupId: groupId, userId: userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String userId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeMember(
        groupId: groupId,
        userId: userId,
        reason: reason,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.leaveGroup(groupId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateMemberRole(
        groupId: groupId,
        userId: userId,
        role: role,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? topic,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateGroup(
        groupId: groupId,
        name: name,
        topic: topic,
        avatarUrl: avatarUrl,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for group actions
final groupActionsProvider =
    StateNotifierProvider.autoDispose<GroupActionsNotifier, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return GroupActionsNotifier(repository);
});

/// Provider to check if current user is admin of a group
final isGroupAdminProvider =
    Provider.family.autoDispose<bool, String>((ref, groupId) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.isAdmin(groupId);
});
