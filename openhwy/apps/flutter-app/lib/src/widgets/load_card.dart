import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/models/loadboard_model.dart';
import 'load_status_badge.dart';

class LoadCard extends StatelessWidget {
  final Load load;
  final VoidCallback? onTap;

  const LoadCard({
    super.key,
    required this.load,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            load.reference,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (load.driverName != null)
                            Text(
                              'Driver: ${load.driverName}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textGray,
                              ),
                            ),
                        ],
                      ),
                    ),
                    LoadStatusBadge(status: load.status),
                  ],
                ),
                const SizedBox(height: 16),
                _RouteRow(
                  icon: Icons.location_on,
                  label: 'Pickup',
                  value: load.origin,
                  iconColor: AppColors.forestGreen,
                ),
                const SizedBox(height: 8),
                _RouteRow(
                  icon: Icons.flag,
                  label: 'Delivery',
                  value: load.destination,
                  iconColor: AppColors.truckRed,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.borderLight,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.attach_money,
                      label: '\$${load.rate.toStringAsFixed(0)}',
                      color: AppColors.forestGreen,
                    ),
                    if (load.distance != null) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.straighten,
                        label: '${load.distance} mi',
                        color: AppColors.highwayBlue,
                      ),
                    ],
                    if (load.pickupDate != null) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.calendar_today,
                        label: _formatDate(load.pickupDate!),
                        color: AppColors.sunrisePurple,
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textGray,
                      size: 24,
                    ),
                  ],
                ),
                if (load.progress != null) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${load.progress}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.yellowLine,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (load.progress ?? 0) / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.borderGray,
                          valueColor: const AlwaysStoppedAnimation(AppColors.yellowLine),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _RouteRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
