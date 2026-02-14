import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text style definitions for the app
class AppTextStyles {
  AppTextStyles._();

  // ==========================================================================
  // STATIC TEXT STYLES
  // ==========================================================================

  static const TextStyle appTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle appSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle headerTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle value = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle primaryText = TextStyle(
    fontSize: 14,
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  // ==========================================================================
  // DYNAMIC TEXT STYLES
  // ==========================================================================

  static TextStyle subtitle({Color? color}) => TextStyle(
    fontSize: 13,
    color: color ?? AppColors.glassWhite(0.6),
  );

  static TextStyle get label => TextStyle(
    fontSize: 12,
    color: AppColors.glassWhite(0.6),
    fontWeight: FontWeight.w500,
  );

  // ==========================================================================
  // CONTEXT-AWARE TEXT STYLES
  // ==========================================================================

  static TextStyle getAppSubtitle(BuildContext context) => appSubtitle;

  static TextStyle getPrimaryText(BuildContext context) => primaryText;
}
