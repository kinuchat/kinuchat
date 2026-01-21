import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/database/app_database.dart';

import '../../../core/providers/group_providers.dart';
import '../../../core/providers/database_providers.dart';
import '../../widgets/contact_picker_dialog.dart';
import '../../widgets/avatar_picker.dart';

/// Screen for creating a new group chat
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _topicController = TextEditingController();
  final List<String> _selectedMembers = [];
  File? _selectedAvatar;

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createGroupProvider);

    ref.listen<AsyncValue<ConversationEntity?>>(createGroupProvider,
        (previous, next) {
      next.whenData((group) {
        if (group != null) {
          // Navigate to the new group chat
          Navigator.of(context).pop(group);
        }
      });

      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: createState.isLoading ? null : _createGroup,
            child: createState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group avatar
            Center(
              child: AvatarPickerWidget(
                selectedFile: _selectedAvatar,
                placeholderIcon: Icons.group,
                onImageSelected: (file) {
                  setState(() {
                    _selectedAvatar = file;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Group name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Group topic/description
            TextFormField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this group about?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 24),

            // Add members section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Members',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _showMemberPicker,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_selectedMembers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No members added yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You can add members now or later',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildSelectedMembersList(),

            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End-to-End Encrypted',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          'All messages in this group will be encrypted',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMembersList() {
    final contactsAsync = ref.watch(_selectedContactsProvider(_selectedMembers));

    return contactsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Column(
        children: _selectedMembers.map((memberId) {
          return ListTile(
            leading: CircleAvatar(
              child: Text(memberId[0].toUpperCase()),
            ),
            title: Text(memberId),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
              onPressed: () {
                setState(() {
                  _selectedMembers.remove(memberId);
                });
              },
            ),
          );
        }).toList(),
      ),
      data: (contacts) {
        return Column(
          children: _selectedMembers.map((memberId) {
            final contact = contacts
                .where((c) => c.id == memberId)
                .firstOrNull;
            final displayName = contact?.displayName ?? memberId;
            final avatar = contact?.avatar;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(displayName[0].toUpperCase())
                    : null,
              ),
              title: Text(displayName),
              subtitle: contact != null ? Text(memberId) : null,
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    _selectedMembers.remove(memberId);
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showMemberPicker() async {
    final selectedIds = await showContactPickerDialog(
      context,
      excludeIds: _selectedMembers,
      title: 'Add Members',
    );

    if (selectedIds != null && selectedIds.isNotEmpty) {
      setState(() {
        _selectedMembers.addAll(selectedIds);
      });
    }
  }

  void _createGroup() {
    if (_formKey.currentState!.validate()) {
      ref.read(createGroupProvider.notifier).createGroup(
            name: _nameController.text.trim(),
            memberIds: _selectedMembers.isEmpty ? null : _selectedMembers,
            topic: _topicController.text.trim().isEmpty
                ? null
                : _topicController.text.trim(),
          );
    }
  }
}

/// Provider to get contact info for selected member IDs
final _selectedContactsProvider = FutureProvider.family
    .autoDispose<List<ContactEntity>, List<String>>((ref, memberIds) async {
  if (memberIds.isEmpty) return [];
  final database = ref.watch(databaseProvider);
  final allContacts = await database.getAllContacts();
  return allContacts.where((c) => memberIds.contains(c.id)).toList();
});
