import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';

/// Centralized color definitions for the app
/// Follows Single Responsibility Principle - only handles colors
class AppColors {
  AppColors._();

  // ==========================================================================
  // DARK THEME COLORS (Amber/Orange)
  // ==========================================================================

  static const Color darkSlate900 = Color(0xFF0f172a);
  static const Color darkPurple900 = Color(0xFF581c87);
  static const Color darkAmber500 = Color(0xFFf59e0b);
  static const Color darkOrange600 = Color(0xFFea580c);
  static const Color darkOrange500 = Color(0xFFf97316);
  static const Color darkAmber300 = Color(0xFFfcd34d);
  static const Color darkAmber400 = Color(0xFFfbbf24);

  // ==========================================================================
  // LIGHT THEME COLORS (Navy Blue)
  // ==========================================================================

  static const Color lightSlate950 = Color(0xFF020617);
  static const Color lightBlue950 = Color(0xFF172554);
  static const Color lightBlue600 = Color(0xFF2563eb);
  static const Color lightBlue500 = Color(0xFF3b82f6);
  static const Color lightBlue700 = Color(0xFF1d4ed8);
  static const Color lightBlue300 = Color(0xFF93c5fd);
  static const Color lightBlue400 = Color(0xFF60a5fa);

  // ==========================================================================
  // SEMANTIC COLORS
  // ==========================================================================

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color accent = Color(0xFF9C27B0);

  // ==========================================================================
  // GLASSMORPHISM COLORS
  // ==========================================================================

  static Color glassWhite(double opacity) => Colors.white.withValues(alpha: opacity);
  static Color glassBlack(double opacity) => Colors.black.withValues(alpha: opacity);

  static Color get cardGlassBackground => glassWhite(0.05);
  static Color get cardGlassBorder => glassWhite(0.1);

  // ==========================================================================
  // THEME-AWARE COLOR GETTERS
  // ==========================================================================

  static bool isDark(BuildContext context) {
    try {
      return context.read<ThemeService>().isDark(context);
    } catch (_) {
      return true;
    }
  }

  static Color getSlate900(BuildContext context) =>
      isDark(context) ? darkSlate900 : lightSlate950;

  static Color getPurple900(BuildContext context) =>
      isDark(context) ? darkPurple900 : lightBlue950;

  static Color getPrimaryColor(BuildContext context) =>
      isDark(context) ? darkAmber500 : lightBlue600;

  static Color getSecondaryColor(BuildContext context) =>
      isDark(context) ? darkOrange600 : lightBlue500;

  static Color getAccentLight(BuildContext context) =>
      isDark(context) ? darkAmber300 : lightBlue300;

  static Color getAccentMedium(BuildContext context) =>
      isDark(context) ? darkAmber400 : lightBlue400;

  // ==========================================================================
  // LEGACY ALIASES (for backward compatibility)
  // ==========================================================================

  static const Color slate900 = darkSlate900;
  static const Color purple900 = darkPurple900;
  static const Color amber500 = darkAmber500;
  static const Color orange600 = darkOrange600;
  static const Color orange500 = darkOrange500;
  static const Color amber300 = darkAmber300;
  static const Color amber400 = darkAmber400;
  static const Color primaryNavy = darkSlate900;
  static const Color secondaryTeal = darkAmber500;
  static const Color navyDark = darkSlate900;
  static const Color navyLight = darkPurple900;
}
