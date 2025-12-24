import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../services/local_storage_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: ListView(
        children: [
          // Profile Section
          _buildSection(context, 'Profile', [
            _buildTile(context, 'My Profile', Icons.person, () => context.push('/settings/profile')),
            _buildTile(context, 'Company Settings', Icons.business, () => context.push('/settings/company')),
          ]),

          // App Settings
          _buildSection(context, 'App Settings', [
            _buildTile(context, 'Notifications', Icons.notifications, () {}),
            _buildTile(context, 'Theme', Icons.palette, () {}),
            _buildTile(context, 'Language', Icons.language, () {}),
          ]),

          // Data & Privacy
          _buildSection(context, 'Data & Privacy', [
            _buildTile(context, 'Data Management', Icons.storage, () {}),
            _buildTile(context, 'Privacy Policy', Icons.privacy_tip, () {}),
            _buildTile(context, 'Terms of Service', Icons.description, () {}),
          ]),

          // Danger Zone
          _buildSection(context, 'Danger Zone', [
            _buildTile(
              context,
              'Clear Cache',
              Icons.delete_sweep,
              () => _showClearCacheDialog(context),
              color: AppTheme.warning,
            ),
            _buildTile(
              context,
              'Reset App',
              Icons.restart_alt,
              () => _showResetDialog(context, ref),
              color: AppTheme.error,
            ),
          ]),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Version 1.0.0+1',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTile(BuildContext context, String title, IconData icon, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textPrimary),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right, color: color ?? AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await LocalStorageService.clearCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    }
  }

  Future<void> _showResetDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App'),
        content: const Text('This will delete all data and reset the app. You will need to go through onboarding again. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await LocalStorageService.clearAllData();
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/onboarding');
      }
    }
  }
}
