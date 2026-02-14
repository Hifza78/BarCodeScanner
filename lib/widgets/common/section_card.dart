import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Reusable card wrapper for consistent styling across all sections
/// Follows Single Responsibility Principle - only handles card container styling
/// Updated for new glassmorphism design
class SectionCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    super.key,
    required this.child,
    this.borderColor,
    this.elevation,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCardDecoration(borderColor: borderColor),
      child: Padding(
        padding: padding ?? AppTheme.cardPadding,
        child: child,
      ),
    );
  }
}
