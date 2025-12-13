import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../features/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: AppColors.gradientNight,
              border: Border(
                bottom: BorderSide(color: AppColors.borderGray),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null) ...[
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.purple.withOpacity(0.2),
                    child: Text(
                      '${user.firstName[0]}${user.lastName[0]}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGray,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'OpenHWY TMS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  onTap: () {
                    context.go('/dashboard');
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.local_shipping,
                  label: 'Loads',
                  onTap: () {
                    context.go('/loads');
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.person,
                  label: 'Drivers',
                  onTap: () {
                    context.go('/drivers');
                    Navigator.pop(context);
                  },
                ),
                const Divider(color: AppColors.borderGray),
                _DrawerItem(
                  icon: Icons.receipt_long,
                  label: 'Invoices',
                  onTap: () {
                    context.go('/invoices');
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.payment,
                  label: 'Payments',
                  onTap: () {
                    context.go('/payments');
                    Navigator.pop(context);
                  },
                ),
                const Divider(color: AppColors.borderGray),
                _DrawerItem(
                  icon: Icons.description,
                  label: 'Documents',
                  onTap: () {
                    context.go('/documents');
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.access_time,
                  label: 'Hours of Service',
                  onTap: () {
                    context.go('/hos');
                    Navigator.pop(context);
                  },
                ),
                const Divider(color: AppColors.borderGray),
                _DrawerItem(
                  icon: Icons.school,
                  label: 'Training',
                  onTap: () {
                    context.go('/training');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderGray),
              ),
            ),
            child: Column(
              children: [
                _DrawerItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: AppColors.textGray,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
