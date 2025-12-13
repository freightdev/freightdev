import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class AppSearchBar extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final Widget? trailing;

  const AppSearchBar({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint ?? 'Search...',
          hintStyle: const TextStyle(color: AppColors.textGray),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textGray,
          ),
          suffixIcon: trailing,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
