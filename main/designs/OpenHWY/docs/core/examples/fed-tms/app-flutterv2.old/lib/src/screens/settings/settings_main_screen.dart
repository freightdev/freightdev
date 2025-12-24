import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class SettingsMainScreen extends StatelessWidget {
  const SettingsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.roadBlack,
      appBar: AppBar(
        backgroundColor: AppColors.asphaltGray,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _SectionCard(
              title: 'Profile',
              children: [
                _SettingsTile(
                  icon: Icons.person,
                  title: 'Account Information',
                  subtitle: 'Update your profile details',
                  onTap: () {
                    // TODO: Navigate to profile
                  },
                ),
                _SettingsTile(
                  icon: Icons.business,
                  title: 'Company Settings',
                  subtitle: 'Manage company information',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.security,
                  title: 'Security',
                  subtitle: 'Password and authentication',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preferences Section
            _SectionCard(
              title: 'Preferences',
              children: [
                _SettingsTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Push, email, and SMS preferences',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English (US)',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.palette,
                  title: 'Appearance',
                  subtitle: 'Dark mode (System)',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Billing Section
            _SectionCard(
              title: 'Billing',
              children: [
                _SettingsTile(
                  icon: Icons.credit_card,
                  title: 'Payment Methods',
                  subtitle: 'Manage payment cards',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.receipt_long,
                  title: 'Billing History',
                  subtitle: 'View past invoices',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.upgrade,
                  title: 'Subscription',
                  subtitle: 'Pro Plan • $247/month',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientSunrise,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Support Section
            _SectionCard(
              title: 'Support',
              children: [
                _SettingsTile(
                  icon: Icons.help,
                  title: 'Help Center',
                  subtitle: 'FAQs and guides',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.chat,
                  title: 'Contact Support',
                  subtitle: 'Get help from our team',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.bug_report,
                  title: 'Report a Problem',
                  subtitle: 'Let us know about issues',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // About Section
            _SectionCard(
              title: 'About',
              children: [
                _SettingsTile(
                  icon: Icons.info,
                  title: 'About OpenHWY',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.article,
                  title: 'Terms of Service',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.code,
                  title: 'Open Source Licenses',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.truckRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.asphaltGray,
        title: const Text(
          'Log Out',
          style: TextStyle(color: AppColors.white),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppColors.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGray),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Logout
              Navigator.pop(context);
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.truckRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textGray,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradientNight,
            border: Border.all(color: AppColors.borderGray),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.sunrisePurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.sunrisePurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textGray,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
