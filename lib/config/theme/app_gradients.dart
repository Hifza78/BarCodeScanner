import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized gradient definitions for the app
class AppGradients {
  AppGradients._();

  // ==========================================================================
  // THEME-AWARE GRADIENTS
  // ==========================================================================

  static LinearGradient getPrimaryGradient(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return LinearGradient(
      colors: isDark
          ? [AppColors.darkAmber500, AppColors.darkOrange600]
          : [AppColors.lightBlue600, AppColors.lightBlue500],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  static LinearGradient getBackgroundGradient(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [AppColors.darkSlate900, AppColors.darkPurple900, AppColors.darkSlate900]
          : [AppColors.lightSlate950, AppColors.lightBlue950, AppColors.lightSlate950],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  static LinearGradient getTealGradient(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [AppColors.darkAmber500, AppColors.darkOrange600]
          : [AppColors.lightBlue600, AppColors.lightBlue500],
    );
  }

  static LinearGradient getGlowGradient(BuildContext context, {double opacity = 0.2}) {
    final isDark = AppColors.isDark(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.darkAmber500.withValues(alpha: opacity),
              AppColors.darkPurple900.withValues(alpha: opacity),
            ]
          : [
              AppColors.lightBlue500.withValues(alpha: opacity),
              AppColors.lightBlue950.withValues(alpha: opacity),
            ],
    );
  }

  // ==========================================================================
  // STATIC GRADIENTS (Legacy support)
  // ==========================================================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.darkAmber500, AppColors.darkOrange600],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.darkSlate900, AppColors.darkPurple900, AppColors.darkSlate900],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient authGradient = backgroundGradient;

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.darkAmber500, AppColors.darkOrange600],
  );

  static LinearGradient glowGradient({double opacity = 0.2}) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.darkAmber500.withValues(alpha: opacity),
      AppColors.darkPurple900.withValues(alpha: opacity),
    ],
  );
}
