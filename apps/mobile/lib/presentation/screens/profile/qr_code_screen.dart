import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/providers/providers.dart';

/// QR code screen for sharing and scanning user profiles
class QrCodeScreen extends ConsumerStatefulWidget {
  const QrCodeScreen({super.key});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileScannerController? _scannerController;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      // Initialize scanner when switching to scan tab
      _scannerController ??= MobileScannerController();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final handle = accountState.account?.handle ?? 'unknown';
    final displayName = accountState.account?.displayName ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Code', icon: Icon(Icons.qr_code)),
            Tab(text: 'Scan', icon: Icon(Icons.qr_code_scanner)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyQrCode(context, handle, displayName),
          _buildScanner(context),
        ],
      ),
    );
  }

  Widget _buildMyQrCode(
      BuildContext context, String handle, String displayName) {
    // Format: kinu:@handle (simple format for scanning)
    final qrData = 'kinu:@$handle';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              style: AppTypography.title,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              '@$handle',
              style: AppTypography.body.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
                errorStateBuilder: (ctx, err) {
                  return const Center(
                    child: Text('Error generating QR code'),
                  );
                },
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'Others can scan this code to add you as a contact',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '@$handle'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Handle copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Handle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner(BuildContext context) {
    return Stack(
      children: [
        if (_scannerController != null)
          MobileScanner(
            controller: _scannerController!,
            onDetect: (capture) {
              if (_hasScanned) return;

              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final value = barcode.rawValue;
                if (value != null && value.startsWith('kinu:@')) {
                  _hasScanned = true;
                  final handle = value.substring(6); // Remove 'kinu:@'
                  _onHandleScanned(context, handle);
                  break;
                }
              }
            },
          )
        else
          const Center(child: CircularProgressIndicator()),
        // Overlay with scanning frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Instructions at bottom
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Scan a Kinu QR code to add a contact',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextButton.icon(
                    onPressed: () => _showManualEntryDialog(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Enter handle manually'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onHandleScanned(BuildContext context, String handle) {
    _scannerController?.stop();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: Text('Would you like to add @$handle as a contact?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _hasScanned = false;
              _scannerController?.start();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _addContact(handle);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Handle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '@username',
            prefixText: '@',
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              _addContact(value.replaceFirst('@', ''));
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final handle = controller.text.replaceFirst('@', '');
              if (handle.isNotEmpty) {
                Navigator.pop(context);
                _addContact(handle);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addContact(String handle) async {
    // TODO: Implement actual contact addition via Matrix
    // For now, show a confirmation
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact request sent to @$handle'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Navigate to contacts/chat
          },
        ),
      ),
    );

    // Go back to previous screen
    Navigator.pop(context);
  }
}
