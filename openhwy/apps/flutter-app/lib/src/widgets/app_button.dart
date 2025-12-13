import 'package:flutter/material.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: _getPadding(),
            decoration: _getDecoration(isDisabled),
            child: Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: _getIconSize(),
                    height: _getIconSize(),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_getTextColor(isDisabled)),
                    ),
                  )
                else if (icon != null)
                  Icon(
                    icon,
                    size: _getIconSize(),
                    color: _getTextColor(isDisabled),
                  ),
                if ((loading || icon != null) && label.isNotEmpty)
                  const SizedBox(width: 8),
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: _getFontSize(),
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(isDisabled),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case AppButtonSize.small:
        return 8;
      case AppButtonSize.medium:
        return 10;
      case AppButtonSize.large:
        return 12;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  BoxDecoration _getDecoration(bool isDisabled) {
    if (isDisabled) {
      return BoxDecoration(
        color: AppColors.borderGray,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      );
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          gradient: AppColors.gradientSunrise,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellowLine.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        );
      case AppButtonVariant.secondary:
        return BoxDecoration(
          color: AppColors.white.withOpacity(0.05),
          border: Border.all(color: AppColors.borderGray),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
      case AppButtonVariant.outline:
        return BoxDecoration(
          border: Border.all(color: AppColors.sunrisePurple, width: 2),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
      case AppButtonVariant.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
      case AppButtonVariant.danger:
        return BoxDecoration(
          color: AppColors.truckRed,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          boxShadow: [
            BoxShadow(
              color: AppColors.truckRed.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        );
    }
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) return AppColors.textGray;

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return AppColors.white;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return AppColors.offWhite;
    }
  }
}
