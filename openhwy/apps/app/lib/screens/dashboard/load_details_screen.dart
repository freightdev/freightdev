import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';

class LoadDetailsScreen extends ConsumerWidget {
  final String loadId;

  const LoadDetailsScreen({
    super.key,
    required this.loadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Load #L$loadId'),
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
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: AppColors.purple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'In Transit',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ETA: Dec 15, 2024 - 3:00 PM',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Route Information
            Text(
              'Route',
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
                  _RoutePoint(
                    icon: Icons.trip_origin,
                    location: 'Chicago, IL 60601',
                    date: 'Dec 12, 2024',
                    time: '8:00 AM',
                    isCompleted: true,
                  ),
                  _RouteConnector(),
                  _RoutePoint(
                    icon: Icons.location_on,
                    location: 'Dallas, TX 75201',
                    date: 'Dec 15, 2024',
                    time: '3:00 PM',
                    isCompleted: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Load Details
            Text(
              'Details',
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
                  _DetailRow(label: 'Load ID', value: '#L$loadId'),
                  const Divider(height: 24, color: AppColors.borderGray),
                  _DetailRow(label: 'Rate', value: '\$2,500.00'),
                  const Divider(height: 24, color: AppColors.borderGray),
                  _DetailRow(label: 'Distance', value: '950 miles'),
                  const Divider(height: 24, color: AppColors.borderGray),
                  _DetailRow(label: 'Weight', value: '42,000 lbs'),
                  const Divider(height: 24, color: AppColors.borderGray),
                  _DetailRow(label: 'Equipment', value: 'Dry Van'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Driver Information
            Text(
              'Assigned Driver',
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.purple.withOpacity(0.2),
                    child: const Text(
                      'JD',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'John Doe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Truck #T1234',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.purple),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, color: AppColors.purple),
                    onPressed: () {},
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

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final String location;
  final String date;
  final String time;
  final bool isCompleted;

  const _RoutePoint({
    required this.icon,
    required this.location,
    required this.date,
    required this.time,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isCompleted ? AppColors.green : AppColors.purple,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$date at $time',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
        if (isCompleted)
          const Icon(
            Icons.check_circle,
            color: AppColors.green,
            size: 20,
          ),
      ],
    );
  }
}

class _RouteConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 11),
          Container(
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.green,
                  AppColors.purple,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textGray,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}
