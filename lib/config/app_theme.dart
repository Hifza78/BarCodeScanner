import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'theme/app_gradients.dart';
import 'theme/app_text_styles.dart';
import 'theme/app_decorations.dart';

// Re-export theme components for easy access
export 'theme/app_colors.dart';
export 'theme/app_gradients.dart';
export 'theme/app_text_styles.dart';
export 'theme/app_decorations.dart';

/// Centralized theme configuration - Facade pattern
/// Provides backward compatibility while delegating to focused theme classes
class AppTheme {
  AppTheme._();

  // ==========================================================================
  // COLOR ALIASES (Backward Compatibility)
  // ==========================================================================

  static const Color darkSlate900 = AppColors.darkSlate900;
  static const Color darkPurple900 = AppColors.darkPurple900;
  static const Color darkAmber500 = AppColors.darkAmber500;
  static const Color darkOrange600 = AppColors.darkOrange600;
  static const Color darkOrange500 = AppColors.darkOrange500;
  static const Color darkAmber300 = AppColors.darkAmber300;
  static const Color darkAmber400 = AppColors.darkAmber400;

  static const Color lightSlate950 = AppColors.lightSlate950;
  static const Color lightBlue950 = AppColors.lightBlue950;
  static const Color lightBlue600 = AppColors.lightBlue600;
  static const Color lightBlue500 = AppColors.lightBlue500;
  static const Color lightBlue700 = AppColors.lightBlue700;
  static const Color lightBlue300 = AppColors.lightBlue300;
  static const Color lightBlue400 = AppColors.lightBlue400;

  static const Color slate900 = AppColors.slate900;
  static const Color purple900 = AppColors.purple900;
  static const Color amber500 = AppColors.amber500;
  static const Color orange600 = AppColors.orange600;
  static const Color orange500 = AppColors.orange500;
  static const Color amber300 = AppColors.amber300;
  static const Color amber400 = AppColors.amber400;
  static const Color primaryNavy = AppColors.primaryNavy;
  static const Color secondaryTeal = AppColors.secondaryTeal;
  static const Color navyDark = AppColors.navyDark;
  static const Color navyLight = AppColors.navyLight;

  static const Color success = AppColors.success;
  static const Color error = AppColors.error;
  static const Color warning = AppColors.warning;
  static const Color info = AppColors.info;
  static const Color accent = AppColors.accent;

  // Dynamic color getters
  static Color getSlate900(BuildContext context) => AppColors.getSlate900(context);
  static Color getPurple900(BuildContext context) => AppColors.getPurple900(context);
  static Color getPrimaryColor(BuildContext context) => AppColors.getPrimaryColor(context);
  static Color getSecondaryColor(BuildContext context) => AppColors.getSecondaryColor(context);
  static Color getAccentLight(BuildContext context) => AppColors.getAccentLight(context);
  static Color getAccentMedium(BuildContext context) => AppColors.getAccentMedium(context);

  // Glass colors
  static Color glassWhite(double opacity) => AppColors.glassWhite(opacity);
  static Color glassBlack(double opacity) => AppColors.glassBlack(opacity);
  static Color get cardGlassBackground => AppColors.cardGlassBackground;
  static Color get cardGlassBorder => AppColors.cardGlassBorder;

  // ==========================================================================
  // GRADIENT ALIASES
  // ==========================================================================

  static LinearGradient getPrimaryGradient(BuildContext context) =>
      AppGradients.getPrimaryGradient(context);
  static LinearGradient getBackgroundGradient(BuildContext context) =>
      AppGradients.getBackgroundGradient(context);
  static LinearGradient getTealGradient(BuildContext context) =>
      AppGradients.getTealGradient(context);
  static LinearGradient getGlowGradient(BuildContext context, {double opacity = 0.2}) =>
      AppGradients.getGlowGradient(context, opacity: opacity);

  static const LinearGradient primaryGradient = AppGradients.primaryGradient;
  static const LinearGradient backgroundGradient = AppGradients.backgroundGradient;
  static const LinearGradient authGradient = AppGradients.authGradient;
  static const LinearGradient tealGradient = AppGradients.tealGradient;
  static LinearGradient glowGradient({double opacity = 0.2}) =>
      AppGradients.glowGradient(opacity: opacity);

  // ==========================================================================
  // TEXT STYLE ALIASES
  // ==========================================================================

  static const TextStyle appTitleStyle = AppTextStyles.appTitle;
  static TextStyle appSubtitleStyle = AppTextStyles.appSubtitle;
  static TextStyle getAppSubtitleStyle(BuildContext context) =>
      AppTextStyles.getAppSubtitle(context);
  static const TextStyle headerTitleStyle = AppTextStyles.headerTitle;
  static const TextStyle badgeTextStyle = AppTextStyles.badgeText;
  static const TextStyle cardTitleStyle = AppTextStyles.cardTitle;
  static const TextStyle valueStyle = AppTextStyles.value;
  static TextStyle amberTextStyle = AppTextStyles.primaryText;
  static TextStyle getPrimaryTextStyle(BuildContext context) =>
      AppTextStyles.getPrimaryText(context);
  static TextStyle subtitleStyle({Color? color}) => AppTextStyles.subtitle(color: color);
  static TextStyle labelStyle = AppTextStyles.label;

  // ==========================================================================
  // DECORATION ALIASES
  // ==========================================================================

  static const double cardBorderRadius = AppDecorations.cardBorderRadius;
  static const double buttonBorderRadius = AppDecorations.buttonBorderRadius;
  static const double headerBorderRadius = AppDecorations.headerBorderRadius;
  static const double cardElevation = AppDecorations.cardElevation;
  static const EdgeInsets cardPadding = AppDecorations.cardPadding;
  static const EdgeInsets headerPadding = AppDecorations.headerPadding;

  static BorderSide get cardBorder => AppDecorations.cardBorder;
  static BorderSide getAmberBorder(BuildContext context) =>
      AppDecorations.getAmberBorder(context);
  static BorderSide get amberBorder => AppDecorations.amberBorder;
  static Color getDashedBorderColor(BuildContext context) =>
      AppDecorations.getDashedBorderColor(context);
  static Color get dashedBorderColor => AppDecorations.dashedBorderColor;

  static BoxDecoration glassCardDecoration({Color? borderColor}) =>
      AppDecorations.glassCard(borderColor: borderColor);
  static BoxDecoration cardDecoration({Color? borderColor}) =>
      AppDecorations.card(borderColor: borderColor);
  static BoxDecoration headerDecoration({Color? color}) =>
      AppDecorations.header(color: color);
  static BoxDecoration badgeDecoration({Color? color, double opacity = 0.2}) =>
      AppDecorations.badge(color: color, opacity: opacity);
  static BoxDecoration getBadgeDecoration(BuildContext context,
          {Color? color, double opacity = 0.2}) =>
      AppDecorations.getBadge(context, color: color, opacity: opacity);
  static BoxDecoration tabSelectedDecoration() => AppDecorations.tabSelected();
  static BoxDecoration getTabSelectedDecoration(BuildContext context) =>
      AppDecorations.getTabSelected(context);
  static BoxDecoration tabUnselectedDecoration() => AppDecorations.tabUnselected();

  static List<BoxShadow> cardShadow({Color? color}) =>
      AppDecorations.cardShadow(color: color);
  static List<BoxShadow> glowShadow({Color? color}) =>
      AppDecorations.glowShadow(color: color);
  static List<BoxShadow> getGlowShadow(BuildContext context, {Color? color}) =>
      AppDecorations.getGlowShadow(context, color: color);
  static List<BoxShadow> floatingShadow() => AppDecorations.floatingShadow();

  static InputDecoration textFieldDecoration({String? hintText, IconData? prefixIcon}) =>
      AppDecorations.textField(hintText: hintText, prefixIcon: prefixIcon);
  static InputDecoration getTextFieldDecoration(BuildContext context,
          {String? hintText, IconData? prefixIcon}) =>
      AppDecorations.getTextField(context, hintText: hintText, prefixIcon: prefixIcon);

  static ButtonStyle primaryButtonStyle({Color? backgroundColor}) =>
      AppDecorations.primaryButton(backgroundColor: backgroundColor);
  static ButtonStyle getPrimaryButtonStyle(BuildContext context,
          {Color? backgroundColor}) =>
      AppDecorations.getPrimaryButton(context, backgroundColor: backgroundColor);
  static ButtonStyle secondaryButtonStyle({Color? backgroundColor}) =>
      AppDecorations.secondaryButton(backgroundColor: backgroundColor);
  static ButtonStyle getSecondaryButtonStyle(BuildContext context,
          {Color? backgroundColor}) =>
      AppDecorations.getSecondaryButton(context, backgroundColor: backgroundColor);
  static ButtonStyle dangerButtonStyle() => AppDecorations.dangerButton();
  static ButtonStyle glassButtonStyle() => AppDecorations.glassButton();
}
