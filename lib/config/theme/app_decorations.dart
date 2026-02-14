import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_gradients.dart';

/// Centralized decoration definitions for the app
class AppDecorations {
  AppDecorations._();

  // ==========================================================================
  // DIMENSIONS
  // ==========================================================================

  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 30.0;
  static const double headerBorderRadius = 12.0;
  static const double cardElevation = 0.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  // ==========================================================================
  // BORDERS
  // ==========================================================================

  static BorderSide get cardBorder => BorderSide(
    color: AppColors.glassWhite(0.1),
    width: 1,
  );

  static BorderSide getAmberBorder(BuildContext context) => BorderSide(
    color: AppColors.getAccentMedium(context),
    width: 2,
  );

  static BorderSide get amberBorder => const BorderSide(
    color: AppColors.darkAmber400,
    width: 2,
  );

  static Color getDashedBorderColor(BuildContext context) =>
      AppColors.getAccentMedium(context);

  static Color get dashedBorderColor => AppColors.darkAmber400;

  // ==========================================================================
  // BOX DECORATIONS
  // ==========================================================================

  static BoxDecoration glassCard({Color? borderColor}) => BoxDecoration(
    color: AppColors.cardGlassBackground,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    border: Border.all(
      color: borderColor ?? AppColors.cardGlassBorder,
      width: 1,
    ),
  );

  static BoxDecoration card({Color? borderColor}) => glassCard(borderColor: borderColor);

  static BoxDecoration header({Color? color}) => BoxDecoration(
    color: color ?? AppColors.glassWhite(0.1),
    borderRadius: BorderRadius.circular(headerBorderRadius),
  );

  static BoxDecoration badge({Color? color, double opacity = 0.2}) => BoxDecoration(
    color: (color ?? AppColors.darkAmber500).withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration getBadge(BuildContext context, {Color? color, double opacity = 0.2}) =>
      BoxDecoration(
        color: (color ?? AppColors.getPrimaryColor(context)).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(12),
      );

  static BoxDecoration tabSelected() => BoxDecoration(
    gradient: AppGradients.primaryGradient,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: AppColors.darkAmber500.withValues(alpha: 0.4),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration getTabSelected(BuildContext context) {
    final primary = AppColors.getPrimaryColor(context);
    return BoxDecoration(
      gradient: AppGradients.getPrimaryGradient(context),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.4),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration tabUnselected() => BoxDecoration(
    color: AppColors.glassWhite(0.05),
    borderRadius: BorderRadius.circular(25),
    border: Border.all(color: AppColors.glassWhite(0.1)),
  );

  // ==========================================================================
  // SHADOWS
  // ==========================================================================

  static List<BoxShadow> cardShadow({Color? color}) => [
    BoxShadow(
      color: (color ?? Colors.black).withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glowShadow({Color? color}) => [
    BoxShadow(
      color: (color ?? AppColors.darkAmber500).withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> getGlowShadow(BuildContext context, {Color? color}) => [
    BoxShadow(
      color: (color ?? AppColors.getPrimaryColor(context)).withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> floatingShadow() => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // ==========================================================================
  // INPUT DECORATION
  // ==========================================================================

  static InputDecoration textField({
    String? hintText,
    IconData? prefixIcon,
  }) => InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: AppColors.glassWhite(0.4),
      fontSize: 14,
    ),
    contentPadding: const EdgeInsets.all(16),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: AppColors.glassWhite(0.5))
        : null,
    filled: true,
    fillColor: AppColors.glassWhite(0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.glassWhite(0.1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.glassWhite(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkAmber500, width: 2),
    ),
  );

  static InputDecoration getTextField(
    BuildContext context, {
    String? hintText,
    IconData? prefixIcon,
  }) => InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: AppColors.glassWhite(0.4),
      fontSize: 14,
    ),
    contentPadding: const EdgeInsets.all(16),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: AppColors.glassWhite(0.5))
        : null,
    filled: true,
    fillColor: AppColors.glassWhite(0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.glassWhite(0.1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.glassWhite(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.getPrimaryColor(context), width: 2),
    ),
  );

  // ==========================================================================
  // BUTTON STYLES
  // ==========================================================================

  static ButtonStyle primaryButton({Color? backgroundColor}) =>
      ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.darkAmber500,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonBorderRadius),
        ),
        elevation: 0,
      );

  static ButtonStyle getPrimaryButton(BuildContext context, {Color? backgroundColor}) =>
      ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonBorderRadius),
        ),
        elevation: 0,
      );

  static ButtonStyle secondaryButton({Color? backgroundColor}) =>
      ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.darkOrange600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonBorderRadius),
        ),
      );

  static ButtonStyle getSecondaryButton(BuildContext context, {Color? backgroundColor}) =>
      ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.getSecondaryColor(context),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonBorderRadius),
        ),
      );

  static ButtonStyle dangerButton() => ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
    ),
  );

  static ButtonStyle glassButton() => ElevatedButton.styleFrom(
    backgroundColor: AppColors.glassWhite(0.1),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
      side: BorderSide(color: AppColors.glassWhite(0.2)),
    ),
    elevation: 0,
  );
}
