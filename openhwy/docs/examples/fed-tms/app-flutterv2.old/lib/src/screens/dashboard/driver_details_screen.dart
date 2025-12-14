import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';

class DriverDetailsScreen extends ConsumerWidget {
  final String driverId;

  const DriverDetailsScreen({
    super.key,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.purple.withOpacity(0.2),
                    child: const Text(
                      'JD',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.green.withOpacity(0.5),
                      ),
                    ),
                    child: const Text(
                      'On Duty',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone, color: AppColors.purple),
                        iconSize: 28,
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.message, color: AppColors.purple),
                        iconSize: 28,
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.email, color: AppColors.purple),
                        iconSize: 28,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Cards
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                _StatCard(
                  label: 'Loads',
                  value: '127',
                  icon: Icons.local_shipping,
                  color: AppColors.purple,
                ),
                _StatCard(
                  label: 'Miles',
                  value: '98K',
                  icon: Icons.route,
                  color: AppColors.blue,
                ),
                _StatCard(
                  label: 'Revenue',
                  value: '\$245K',
                  icon: Icons.attach_money,
                  color: AppColors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Contact Information
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: 'john.doe@example.com',
                  ),
                  const Divider(height: 24, color: AppColors.borderGray),
                  _InfoRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: '(555) 123-4567',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Truck Information
            Text(
              'Truck Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.local_shipping,
                    label: 'Truck Number',
                    value: 'T1234',
                  ),
                  const Divider(height: 24, color: AppColors.borderGray),
                  _InfoRow(
                    icon: Icons.category,
                    label: 'Type',
                    value: 'Dry Van',
                  ),
                  const Divider(height: 24, color: AppColors.borderGray),
                  _InfoRow(
                    icon: Icons.rv_hookup,
                    label: 'Trailer',
                    value: 'TR5678',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // License Information
            Text(
              'License Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.badge,
                    label: 'License Number',
                    value: 'DL123456789',
                  ),
                  const Divider(height: 24, color: AppColors.borderGray),
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'State',
                    value: 'Illinois',
                  ),
                  const Divider(height: 24, color: AppColors.borderGray),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Expiry Date',
                    value: 'Dec 31, 2025',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current Location
            Text(
              'Current Location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 48,
                      color: AppColors.purple,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Springfield, IL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Last updated 15 min ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textGray),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
