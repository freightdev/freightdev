import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/loadboard_model.dart';
import '../widgets/load_status_badge.dart';

class LoadDetailScreen extends StatelessWidget {
  final String loadId;

  const LoadDetailScreen({
    super.key,
    required this.loadId,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Get load from provider/state management
    final load = _getMockLoad();

    return Scaffold(
      backgroundColor: AppColors.roadBlack,
      appBar: AppBar(
        backgroundColor: AppColors.asphaltGray,
        title: Text(
          load.reference,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.white),
            onPressed: () {
              // TODO: Navigate to edit screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.white),
            onPressed: () {
              _showOptionsMenu(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderGray),
                ),
              ),
              child: Row(
                children: [
                  LoadStatusBadge(status: load.status),
                  const Spacer(),
                  if (load.progress != null)
                    Text(
                      '${load.progress}% Complete',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.yellowLine,
                      ),
                    ),
                ],
              ),
            ),

            // Route Information
            _Section(
              title: 'Route',
              child: Column(
                children: [
                  _RouteStop(
                    icon: Icons.location_on,
                    label: 'Pickup Location',
                    location: load.origin,
                    date: load.pickupDate,
                    color: AppColors.forestGreen,
                  ),
                  const SizedBox(height: 20),
                  _RouteStop(
                    icon: Icons.flag,
                    label: 'Delivery Location',
                    location: load.destination,
                    date: load.deliveryDate,
                    color: AppColors.truckRed,
                  ),
                  if (load.distance != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.straighten, color: AppColors.highwayBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Total Distance: ${load.distance} miles',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Financial Information
            _Section(
              title: 'Financial',
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Total Rate',
                    value: '\$${load.rate.toStringAsFixed(2)}',
                    valueColor: AppColors.forestGreen,
                    highlight: true,
                  ),
                  if (load.distance != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Rate Per Mile',
                      value: '\$${(load.rate / load.distance!).toStringAsFixed(2)}/mi',
                    ),
                  ],
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Fuel Surcharge',
                    value: '\$${(load.rate * 0.15).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),

            // Driver Information
            if (load.driverId != null)
              _Section(
                title: 'Driver',
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientHighway,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          load.driverName![0],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            load.driverName!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          const Text(
                            'Commercial Driver',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Contact',
                      icon: Icons.message,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.small,
                      onPressed: () {
                        // TODO: Open messaging
                      },
                    ),
                  ],
                ),
              ),

            // Documents
            _Section(
              title: 'Documents',
              child: Column(
                children: [
                  _DocumentTile(
                    icon: Icons.description,
                    title: 'Rate Confirmation',
                    subtitle: 'Signed on ${_formatDate(load.createdAt)}',
                    onTap: () {},
                  ),
                  _DocumentTile(
                    icon: Icons.receipt_long,
                    title: 'Bill of Lading',
                    subtitle: 'Pending',
                    onTap: () {},
                  ),
                  _DocumentTile(
                    icon: Icons.receipt,
                    title: 'Proof of Delivery',
                    subtitle: load.status == LoadStatus.delivered ? 'Completed' : 'Not available',
                    onTap: load.status == LoadStatus.delivered ? () {} : null,
                  ),
                ],
              ),
            ),

            // Notes
            if (load.notes != null)
              _Section(
                title: 'Notes',
                child: Text(
                  load.notes!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                    height: 1.6,
                  ),
                ),
              ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (load.status == LoadStatus.pending)
                    AppButton(
                      label: 'Assign Driver',
                      icon: Icons.person_add,
                      fullWidth: true,
                      onPressed: () {
                        // TODO: Show driver selection
                      },
                    ),
                  if (load.status == LoadStatus.booked) ...[
                    AppButton(
                      label: 'Start Transit',
                      icon: Icons.local_shipping,
                      fullWidth: true,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (load.status == LoadStatus.inTransit)
                    AppButton(
                      label: 'Mark as Delivered',
                      icon: Icons.check_circle,
                      fullWidth: true,
                      onPressed: () {},
                    ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Cancel Load',
                    variant: AppButtonVariant.danger,
                    fullWidth: true,
                    onPressed: () {
                      _showCancelDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Load _getMockLoad() {
    return Load(
      id: loadId,
      reference: 'LD-2024-001',
      origin: 'Chicago, IL 60601',
      destination: 'Dallas, TX 75201',
      status: LoadStatus.inTransit,
      rate: 2500.00,
      distance: 920,
      driverId: 'driver1',
      driverName: 'John Smith',
      progress: 45,
      pickupDate: DateTime.now().subtract(const Duration(days: 1)),
      deliveryDate: DateTime.now().add(const Duration(days: 1)),
      notes: 'Handle with care. Temperature-sensitive cargo. Maintain 38-42°F.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.asphaltGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.white),
              title: const Text('Share', style: TextStyle(color: AppColors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.white),
              title: const Text('Print', style: TextStyle(color: AppColors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.white),
              title: const Text('Duplicate', style: TextStyle(color: AppColors.white)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.asphaltGray,
        title: const Text('Cancel Load?', style: TextStyle(color: AppColors.white)),
        content: const Text(
          'Are you sure you want to cancel this load? This action cannot be undone.',
          style: TextStyle(color: AppColors.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Load', style: TextStyle(color: AppColors.textGray)),
          ),
          TextButton(
            onPressed: () {
              // TODO: Cancel load
              Navigator.pop(context);
            },
            child: const Text('Cancel Load', style: TextStyle(color: AppColors.truckRed)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  final IconData icon;
  final String label;
  final String location;
  final DateTime? date;
  final Color color;

  const _RouteStop({
    required this.icon,
    required this.label,
    required this.location,
    this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (date != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(date!),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.highlight = false,
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
          style: TextStyle(
            fontSize: highlight ? 20 : 15,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _DocumentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.sunrisePurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.sunrisePurple, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: AppColors.textGray)
            : null,
        onTap: onTap,
      ),
    );
  }
}
