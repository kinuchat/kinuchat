import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_ui/meshlink_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help and support screen
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        children: [
          _buildSectionHeader(context, 'Frequently Asked Questions'),
          _buildFaqTile(
            context: context,
            question: 'What is Kinu?',
            answer:
                'Kinu is a privacy-first messaging app that uses end-to-end encryption and mesh networking to keep your conversations secure.',
          ),
          _buildFaqTile(
            context: context,
            question: 'How does mesh networking work?',
            answer:
                'Mesh networking allows devices to communicate directly via Bluetooth, even without internet access. Messages can hop through multiple devices to reach their destination.',
          ),
          _buildFaqTile(
            context: context,
            question: 'Are my messages encrypted?',
            answer:
                'Yes! All messages are end-to-end encrypted using the Matrix protocol. Only you and your contacts can read your messages.',
          ),
          _buildFaqTile(
            context: context,
            question: 'Can I use Kinu without an account?',
            answer:
                'You need an account for cloud messaging, but mesh networking can work with just a local identity for nearby communication.',
          ),
          _buildFaqTile(
            context: context,
            question: 'How do I add contacts?',
            answer:
                'You can add contacts by their handle (e.g., @username) or by scanning their QR code when nearby.',
          ),
          const Divider(height: Spacing.xl),
          _buildSectionHeader(context, 'Get Help'),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Contact Support'),
            subtitle: const Text('support@kinuchat.com'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchEmail(context),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Report a Bug'),
            subtitle: const Text('Help us improve Kinu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchBugReport(context),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Documentation'),
            subtitle: const Text('Learn more about Kinu'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchDocs(context),
          ),
          const Divider(height: Spacing.xl),
          _buildSectionHeader(context, 'Legal'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchPrivacyPolicy(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchTerms(context),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open Source Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLicenseInfo(context),
          ),
          const SizedBox(height: Spacing.xl),
          Center(
            child: Text(
              'Kinu v0.1.0',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFaqTile({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      leading: const Icon(Icons.help_outline, size: 20),
      title: Text(question, style: AppTypography.body),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg + 40,
            0,
            Spacing.lg,
            Spacing.md,
          ),
          child: Text(
            answer,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:support@kinuchat.com?subject=Kinu Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  Future<void> _launchBugReport(BuildContext context) async {
    final uri = Uri.parse('mailto:support@kinuchat.com?subject=Bug Report');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  Future<void> _launchDocs(BuildContext context) async {
    final uri = Uri.parse('https://kinuchat.com/docs');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open browser')),
      );
    }
  }

  Future<void> _launchPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse('https://kinuchat.com/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open browser')),
      );
    }
  }

  Future<void> _launchTerms(BuildContext context) async {
    final uri = Uri.parse('https://kinuchat.com/terms');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open browser')),
      );
    }
  }

  void _showLicenseInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Source'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kinu is built with open source software.',
            ),
            SizedBox(height: 16),
            Text(
              'We use the Matrix protocol for secure, end-to-end encrypted messaging, along with various open source libraries for cryptography, networking, and user interface components.',
            ),
            SizedBox(height: 16),
            Text(
              'All third-party software is used in compliance with their respective licenses (MIT, Apache 2.0, BSD, etc.).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
