import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/database/app_database.dart';

import '../../../core/providers/group_providers.dart';
import '../../../core/providers/database_providers.dart';

/// Screen for selecting contacts to invite to a group
class InviteMembersScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<String> existingMemberIds;

  const InviteMembersScreen({
    super.key,
    required this.groupId,
    this.existingMemberIds = const [],
  });

  @override
  ConsumerState<InviteMembersScreen> createState() =>
      _InviteMembersScreenState();
}

class _InviteMembersScreenState extends ConsumerState<InviteMembersScreen> {
  final Set<String> _selectedContacts = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final actionState = ref.watch(groupActionsProvider);

    // Filter out existing members
    final availableContacts = contactsAsync.when(
      loading: () => <ContactEntity>[],
      error: (_, __) => <ContactEntity>[],
      data: (contacts) => contacts
          .where((c) => !widget.existingMemberIds.contains(c.id))
          .where((c) => _searchQuery.isEmpty ||
              c.displayName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Members'),
        actions: [
          if (_selectedContacts.isNotEmpty)
            TextButton(
              onPressed: actionState.isLoading ? null : _inviteSelected,
              child: actionState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Invite (${_selectedContacts.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Selected contacts chips
          if (_selectedContacts.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _selectedContacts.map((id) {
                  final contact = availableContacts
                      .where((c) => c.id == id)
                      .firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(contact?.displayName ?? id),
                      onDeleted: () {
                        setState(() {
                          _selectedContacts.remove(id);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          // Contact list
          Expanded(
            child: contactsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (_) {
                if (availableContacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No contacts found'
                              : 'No contacts to invite',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: availableContacts.length,
                  itemBuilder: (context, index) {
                    final contact = availableContacts[index];
                    final isSelected = _selectedContacts.contains(contact.id);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedContacts.add(contact.id);
                          } else {
                            _selectedContacts.remove(contact.id);
                          }
                        });
                      },
                      secondary: CircleAvatar(
                        backgroundImage: contact.avatar != null
                            ? NetworkImage(contact.avatar!)
                            : null,
                        child: contact.avatar == null
                            ? Text(contact.displayName[0].toUpperCase())
                            : null,
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(contact.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteSelected() async {
    final actionsNotifier = ref.read(groupActionsProvider.notifier);

    for (final userId in _selectedContacts) {
      await actionsNotifier.inviteMember(
        groupId: widget.groupId,
        userId: userId,
      );
    }

    if (mounted) {
      Navigator.pop(context, _selectedContacts.toList());
    }
  }
}

/// Provider for contacts
final contactsProvider =
    FutureProvider.autoDispose<List<ContactEntity>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.getAllContacts();
});
