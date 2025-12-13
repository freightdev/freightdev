import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

enum HOSStatus {
  offDuty,
  sleeper,
  driving,
  onDuty,
}

class HosTrackingScreen extends StatefulWidget {
  final String driverId;

  const HosTrackingScreen({
    super.key,
    required this.driverId,
  });

  @override
  State<HosTrackingScreen> createState() => _HosTrackingScreenState();
}

class _HosTrackingScreenState extends State<HosTrackingScreen> {
  HOSStatus _currentStatus = HOSStatus.offDuty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.roadBlack,
      appBar: AppBar(
        backgroundColor: AppColors.asphaltGray,
        title: const Text(
          'Hours of Service',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.white),
            onPressed: () {
              // TODO: Show logs history
            },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.white),
            onPressed: () {
              // TODO: Print logs
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderGray),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(_currentStatus),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(_currentStatus),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(_currentStatus),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Time Remaining
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TimeCard(
                    label: 'Drive Time Remaining',
                    hours: 8.5,
                    total: 11,
                    color: AppColors.yellowLine,
                    icon: Icons.local_shipping,
                  ),
                  const SizedBox(height: 12),
                  _TimeCard(
                    label: 'On-Duty Time Remaining',
                    hours: 10.2,
                    total: 14,
                    color: AppColors.highwayBlue,
                    icon: Icons.work,
                  ),
                  const SizedBox(height: 12),
                  _TimeCard(
                    label: 'Cycle Time Remaining',
                    hours: 42.5,
                    total: 70,
                    color: AppColors.forestGreen,
                    icon: Icons.autorenew,
                  ),
                ],
              ),
            ),

            // Status Change Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                    children: [
                      _StatusButton(
                        status: HOSStatus.offDuty,
                        isActive: _currentStatus == HOSStatus.offDuty,
                        onTap: () => _changeStatus(HOSStatus.offDuty),
                      ),
                      _StatusButton(
                        status: HOSStatus.sleeper,
                        isActive: _currentStatus == HOSStatus.sleeper,
                        onTap: () => _changeStatus(HOSStatus.sleeper),
                      ),
                      _StatusButton(
                        status: HOSStatus.driving,
                        isActive: _currentStatus == HOSStatus.driving,
                        onTap: () => _changeStatus(HOSStatus.driving),
                      ),
                      _StatusButton(
                        status: HOSStatus.onDuty,
                        isActive: _currentStatus == HOSStatus.onDuty,
                        onTap: () => _changeStatus(HOSStatus.onDuty),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Today's Timeline
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today\'s Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientNight,
                      border: Border.all(color: AppColors.borderGray),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _ActivityLog(
                          status: HOSStatus.offDuty,
                          startTime: '12:00 AM',
                          endTime: '6:00 AM',
                          duration: '6h 0m',
                        ),
                        _ActivityLog(
                          status: HOSStatus.driving,
                          startTime: '6:00 AM',
                          endTime: '10:30 AM',
                          duration: '4h 30m',
                        ),
                        _ActivityLog(
                          status: HOSStatus.onDuty,
                          startTime: '10:30 AM',
                          endTime: '11:00 AM',
                          duration: '30m',
                        ),
                        _ActivityLog(
                          status: HOSStatus.driving,
                          startTime: '11:00 AM',
                          endTime: '2:00 PM',
                          duration: '3h 0m',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Violations & Warnings
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alerts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AlertCard(
                    icon: Icons.warning,
                    color: AppColors.warningOrange,
                    title: 'Drive Time Warning',
                    message: 'You have 2.5 hours of drive time remaining',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeStatus(HOSStatus newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    // TODO: Log status change to backend
  }

  Color _getStatusColor(HOSStatus status) {
    switch (status) {
      case HOSStatus.offDuty:
        return AppColors.textGray;
      case HOSStatus.sleeper:
        return AppColors.highwayBlue;
      case HOSStatus.driving:
        return AppColors.yellowLine;
      case HOSStatus.onDuty:
        return AppColors.forestGreen;
    }
  }

  String _getStatusLabel(HOSStatus status) {
    switch (status) {
      case HOSStatus.offDuty:
        return 'OFF DUTY';
      case HOSStatus.sleeper:
        return 'SLEEPER';
      case HOSStatus.driving:
        return 'DRIVING';
      case HOSStatus.onDuty:
        return 'ON DUTY';
    }
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final double hours;
  final double total;
  final Color color;
  final IconData icon;

  const _TimeCard({
    required this.label,
    required this.hours,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (hours / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
              Text(
                '${hours.toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: AppColors.borderGray,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(percentage * 100).toStringAsFixed(0)}% remaining',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final HOSStatus status;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusButton({
    required this.status,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();
    final label = _getLabel();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: isActive ? null : AppColors.gradientNight,
            color: isActive ? color.withOpacity(0.2) : null,
            border: Border.all(
              color: isActive ? color : AppColors.borderGray,
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? color : AppColors.textGray,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case HOSStatus.offDuty:
        return AppColors.textGray;
      case HOSStatus.sleeper:
        return AppColors.highwayBlue;
      case HOSStatus.driving:
        return AppColors.yellowLine;
      case HOSStatus.onDuty:
        return AppColors.forestGreen;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case HOSStatus.offDuty:
        return Icons.power_settings_new;
      case HOSStatus.sleeper:
        return Icons.hotel;
      case HOSStatus.driving:
        return Icons.local_shipping;
      case HOSStatus.onDuty:
        return Icons.work;
    }
  }

  String _getLabel() {
    switch (status) {
      case HOSStatus.offDuty:
        return 'Off Duty';
      case HOSStatus.sleeper:
        return 'Sleeper';
      case HOSStatus.driving:
        return 'Driving';
      case HOSStatus.onDuty:
        return 'On Duty';
    }
  }
}

class _ActivityLog extends StatelessWidget {
  final HOSStatus status;
  final String startTime;
  final String endTime;
  final String duration;
  final bool isLast;

  const _ActivityLog({
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.borderLight),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getIcon(), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLabel(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Text(
            duration,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case HOSStatus.offDuty:
        return AppColors.textGray;
      case HOSStatus.sleeper:
        return AppColors.highwayBlue;
      case HOSStatus.driving:
        return AppColors.yellowLine;
      case HOSStatus.onDuty:
        return AppColors.forestGreen;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case HOSStatus.offDuty:
        return Icons.power_settings_new;
      case HOSStatus.sleeper:
        return Icons.hotel;
      case HOSStatus.driving:
        return Icons.local_shipping;
      case HOSStatus.onDuty:
        return Icons.work;
    }
  }

  String _getLabel() {
    switch (status) {
      case HOSStatus.offDuty:
        return 'Off Duty';
      case HOSStatus.sleeper:
        return 'Sleeper Berth';
      case HOSStatus.driving:
        return 'Driving';
      case HOSStatus.onDuty:
        return 'On Duty (Not Driving)';
    }
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
