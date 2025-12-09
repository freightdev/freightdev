import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/load_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadStatsAsync = ref.watch(loadStatsProvider);
    final invoiceStatsAsync = ref.watch(invoiceStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Consumer(
              builder: (context, ref, child) {
                final user = ref.watch(authNotifierProvider).value;
                return Text(
                  'Welcome back, ${user?.firstName ?? 'User'}!',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const SizedBox(height: 24),

            // Stats Cards
            loadStatsAsync.when(
              data: (stats) => _buildStatsCards(context, stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),

            // Revenue Stats
            invoiceStatsAsync.when(
              data: (stats) => _buildRevenueStats(context, stats),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          title: 'Active Loads',
          value: stats['active_loads']?.toString() ?? '0',
          icon: Icons.local_shipping,
          color: AppTheme.info,
        ),
        _buildStatCard(
          context,
          title: 'Available Drivers',
          value: stats['available_drivers']?.toString() ?? '0',
          icon: Icons.person,
          color: AppTheme.success,
        ),
        _buildStatCard(
          context,
          title: 'Pending Invoices',
          value: stats['pending_invoices']?.toString() ?? '0',
          icon: Icons.receipt_long,
          color: AppTheme.warning,
        ),
        _buildStatCard(
          context,
          title: 'In Transit',
          value: stats['in_transit']?.toString() ?? '0',
          icon: Icons.drive_eta,
          color: AppTheme.purplePrimary,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.surfaceGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.trending_up, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueStats(BuildContext context, Map<String, dynamic> stats) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.surfaceGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRevenueItem(
                context,
                'Total Revenue',
                '\$${stats['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                AppTheme.success,
              ),
              _buildRevenueItem(
                context,
                'Outstanding',
                '\$${stats['outstanding']?.toStringAsFixed(2) ?? '0.00'}',
                AppTheme.warning,
              ),
              _buildRevenueItem(
                context,
                'Paid Today',
                '\$${stats['paid_today']?.toStringAsFixed(2) ?? '0.00'}',
                AppTheme.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'title': 'New Load', 'icon': Icons.add_box, 'route': '/loads'},
      {'title': 'Track Loads', 'icon': Icons.gps_fixed, 'route': '/tracking'},
      {'title': 'Messages', 'icon': Icons.message, 'route': '/messages'},
      {'title': 'Invoices', 'icon': Icons.receipt, 'route': '/invoicing'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return InkWell(
              onTap: () => context.go(action['route'] as String),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.surfaceGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: AppTheme.purplePrimary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      action['title'] as String,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.surfaceGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildActivityItem(
                context,
                'Load LOAD-001 assigned to John Smith',
                '2 hours ago',
                Icons.assignment,
              ),
              const Divider(height: 24),
              _buildActivityItem(
                context,
                'Invoice INV-0042 marked as paid',
                '4 hours ago',
                Icons.check_circle,
              ),
              const Divider(height: 24),
              _buildActivityItem(
                context,
                'New driver Sarah Johnson added',
                '1 day ago',
                Icons.person_add,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String time, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.purplePrimary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.purplePrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(time, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
