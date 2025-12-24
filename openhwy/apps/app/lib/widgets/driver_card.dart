import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/models/driver_model.dart';

class DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onTap;

  const DriverCard({
    super.key,
    required this.driver,
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
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientHighway,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _getStatusColor(driver.status),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          driver.initials,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(driver.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(driver.status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getStatusLabel(driver.status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _getStatusColor(driver.status),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getTruckTypeLabel(driver.truckType),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textGray,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.borderLight,
                ),
                const SizedBox(height: 16),
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        icon: Icons.local_shipping,
                        value: '${driver.totalLoads}',
                        label: 'Loads',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.borderLight,
                    ),
                    Expanded(
                      child: _StatColumn(
                        icon: Icons.straighten,
                        value: '${(driver.totalMiles / 1000).toStringAsFixed(1)}K',
                        label: 'Miles',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.borderLight,
                    ),
                    Expanded(
                      child: _StatColumn(
                        icon: Icons.attach_money,
                        value: '\$${(driver.totalRevenue / 1000).toStringAsFixed(0)}K',
                        label: 'Revenue',
                      ),
                    ),
                  ],
                ),
                if (driver.currentLocation != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.highwayBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            driver.currentLocation!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGray,
                            ),
                          ),
                        ),
                        if (driver.hoursAvailable != null)
                          Text(
                            '${driver.hoursAvailable!.toStringAsFixed(1)}h available',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.yellowLine,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(DriverStatus status) {
    switch (status) {
      case DriverStatus.active:
      case DriverStatus.driving:
        return AppColors.forestGreen;
      case DriverStatus.onDuty:
        return AppColors.yellowLine;
      case DriverStatus.offDuty:
      case DriverStatus.sleeping:
        return AppColors.textGray;
      case DriverStatus.inactive:
        return AppColors.truckRed;
    }
  }

  String _getStatusLabel(DriverStatus status) {
    switch (status) {
      case DriverStatus.active:
        return 'ACTIVE';
      case DriverStatus.onDuty:
        return 'ON DUTY';
      case DriverStatus.offDuty:
        return 'OFF DUTY';
      case DriverStatus.driving:
        return 'DRIVING';
      case DriverStatus.sleeping:
        return 'SLEEPING';
      case DriverStatus.inactive:
        return 'INACTIVE';
    }
  }

  String _getTruckTypeLabel(TruckType type) {
    switch (type) {
      case TruckType.dryVan:
        return 'Dry Van';
      case TruckType.reefer:
        return 'Reefer';
      case TruckType.flatbed:
        return 'Flatbed';
      case TruckType.stepDeck:
        return 'Step Deck';
      case TruckType.boxTruck:
        return 'Box Truck';
      case TruckType.tanker:
        return 'Tanker';
    }
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.sunrisePurple, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
