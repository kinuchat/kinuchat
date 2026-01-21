import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/database/app_database.dart';

import '../../core/providers/database_providers.dart';

/// Dialog for selecting contacts
/// Returns a list of selected contact IDs when closed
class ContactPickerDialog extends ConsumerStatefulWidget {
  /// IDs of contacts to exclude from the list
  final List<String> excludeIds;

  /// Whether to allow selecting multiple contacts
  final bool multiSelect;

  /// Title of the dialog
  final String title;

  const ContactPickerDialog({
    super.key,
    this.excludeIds = const [],
    this.multiSelect = true,
    this.title = 'Select Contacts',
  });

  @override
  ConsumerState<ContactPickerDialog> createState() =>
      _ContactPickerDialogState();
}

class _ContactPickerDialogState extends ConsumerState<ContactPickerDialog> {
  final Set<String> _selectedIds = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(_contactsProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Selected chips
            if (_selectedIds.isNotEmpty)
              contactsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (contacts) {
                  final selectedContacts = contacts
                      .where((c) => _selectedIds.contains(c.id))
                      .toList();
                  return Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: selectedContacts.map((contact) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(contact.displayName),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedIds.remove(contact.id);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

            const Divider(),

            // Contact list
            Expanded(
              child: contactsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (contacts) {
                  // Filter contacts
                  final filtered = contacts
                      .where((c) => !widget.excludeIds.contains(c.id))
                      .where((c) =>
                          _searchQuery.isEmpty ||
                          c.displayName.toLowerCase().contains(_searchQuery) ||
                          c.id.toLowerCase().contains(_searchQuery))
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No contacts found'
                                : 'No contacts available',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final contact = filtered[index];
                      final isSelected = _selectedIds.contains(contact.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              if (!widget.multiSelect) {
                                _selectedIds.clear();
                              }
                              _selectedIds.add(contact.id);
                            } else {
                              _selectedIds.remove(contact.id);
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
                        subtitle: Text(
                          contact.id,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selectedIds.toList()),
                    child: Text('Add (${_selectedIds.length})'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider for contacts in the picker
final _contactsProvider =
    FutureProvider.autoDispose<List<ContactEntity>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.getAllContacts();
});

/// Helper function to show the contact picker dialog
Future<List<String>?> showContactPickerDialog(
  BuildContext context, {
  List<String> excludeIds = const [],
  bool multiSelect = true,
  String title = 'Select Contacts',
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => ContactPickerDialog(
      excludeIds: excludeIds,
      multiSelect: multiSelect,
      title: title,
    ),
  );
}
