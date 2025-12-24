import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/app_drawer.dart';

enum HosStatus {
  driving,
  onDuty,
  offDuty,
  sleeper,
}

class HosScreen extends ConsumerWidget {
  const HosScreen({super.key});

  Color _getStatusColor(HosStatus status) {
    switch (status) {
      case HosStatus.driving:
        return AppColors.purple;
      case HosStatus.onDuty:
        return AppColors.orange;
      case HosStatus.offDuty:
        return AppColors.blue;
      case HosStatus.sleeper:
        return AppColors.textGray;
    }
  }

  String _getStatusText(HosStatus status) {
    switch (status) {
      case HosStatus.driving:
        return 'Driving';
      case HosStatus.onDuty:
        return 'On Duty';
      case HosStatus.offDuty:
        return 'Off Duty';
      case HosStatus.sleeper:
        return 'Sleeper';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Hours of Service'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
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
            // Current Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Status',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.blue.withOpacity(0.5),
                              ),
                            ),
                            child: const Text(
                              'Off Duty',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textGray,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '2h 15m',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Change Status'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hours Remaining Cards
            Text(
              'Hours Remaining',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _HoursCard(
                  label: 'Drive Time',
                  hours: 8.5,
                  maxHours: 11,
                  color: AppColors.purple,
                ),
                _HoursCard(
                  label: 'On Duty',
                  hours: 10.2,
                  maxHours: 14,
                  color: AppColors.orange,
                ),
                _HoursCard(
                  label: '70-Hour',
                  hours: 42.5,
                  maxHours: 70,
                  color: AppColors.blue,
                ),
                _HoursCard(
                  label: 'Cycle Reset',
                  hours: 18.0,
                  maxHours: 34,
                  color: AppColors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Today's Log
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Log',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Log Entries
            ...List.generate(6, (index) {
              final statuses = [
                HosStatus.offDuty,
                HosStatus.sleeper,
                HosStatus.offDuty,
                HosStatus.driving,
                HosStatus.onDuty,
                HosStatus.offDuty,
              ];
              final status = statuses[index];
              final statusColor = _getStatusColor(status);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientNight,
                  border: Border.all(color: AppColors.borderGray),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(status),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${8 + index}:00 AM - ${9 + index}:00 AM',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '1h 00m',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(HosStatus status) {
    switch (status) {
      case HosStatus.driving:
        return Icons.local_shipping;
      case HosStatus.onDuty:
        return Icons.work;
      case HosStatus.offDuty:
        return Icons.home;
      case HosStatus.sleeper:
        return Icons.bed;
    }
  }
}

class _HoursCard extends StatelessWidget {
  final String label;
  final double hours;
  final double maxHours;
  final Color color;

  const _HoursCard({
    required this.label,
    required this.hours,
    required this.maxHours,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = hours / maxHours;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hours.toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'of ${maxHours.toStringAsFixed(0)}h',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderGray,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
