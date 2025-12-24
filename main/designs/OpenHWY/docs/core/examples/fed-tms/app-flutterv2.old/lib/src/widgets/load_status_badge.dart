import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/models/loadboard_model.dart';

class LoadStatusBadge extends StatelessWidget {
  final LoadStatus status;

  const LoadStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getLabel(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _getTextColor(),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getLabel() {
    switch (status) {
      case LoadStatus.pending:
        return 'PENDING';
      case LoadStatus.booked:
        return 'BOOKED';
      case LoadStatus.inTransit:
        return 'IN TRANSIT';
      case LoadStatus.delivered:
        return 'DELIVERED';
      case LoadStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _getBackgroundColor() {
    switch (status) {
      case LoadStatus.pending:
        return AppColors.warningOrange.withOpacity(0.2);
      case LoadStatus.booked:
        return AppColors.highwayBlue.withOpacity(0.2);
      case LoadStatus.inTransit:
        return AppColors.yellowLine.withOpacity(0.2);
      case LoadStatus.delivered:
        return AppColors.forestGreen.withOpacity(0.2);
      case LoadStatus.cancelled:
        return AppColors.truckRed.withOpacity(0.2);
    }
  }

  Color _getTextColor() {
    switch (status) {
      case LoadStatus.pending:
        return AppColors.warningOrange;
      case LoadStatus.booked:
        return AppColors.highwayBlue;
      case LoadStatus.inTransit:
        return AppColors.yellowLine;
      case LoadStatus.delivered:
        return AppColors.forestGreen;
      case LoadStatus.cancelled:
        return AppColors.truckRed;
    }
  }
}
