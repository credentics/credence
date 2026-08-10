import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

class AppTypography {
  static TextTheme build(TextTheme base) {
    return base.copyWith(
      headlineLarge: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.7,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
      titleLarge: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      bodySmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
      labelLarge: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
