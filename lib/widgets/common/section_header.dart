import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Reusable section header with icon, title, and optional badge
/// Follows Single Responsibility Principle - only handles header rendering
/// Updated for new glassmorphism design
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Color? badgeColor;
  final Color? backgroundColor;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.badge,
    this.badgeColor,
    this.backgroundColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppTheme.headerPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.glassWhite(0.08),
        borderRadius: BorderRadius.circular(AppTheme.headerBorderRadius),
        border: Border.all(color: AppTheme.glassWhite(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.amber400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTheme.headerTitleStyle,
            ),
          ),
          if (badge != null)
            _buildBadge()
          else if (trailing != null)
            trailing!,
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        badge!,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Section header with optional "Optional" tag
class SectionHeaderWithOptional extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool showOptional;
  final Color? backgroundColor;

  const SectionHeaderWithOptional({
    super.key,
    required this.icon,
    required this.title,
    this.showOptional = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      icon: icon,
      title: title,
      backgroundColor: backgroundColor,
      trailing: showOptional
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.glassWhite(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Optional',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.glassWhite(0.8),
                ),
              ),
            )
          : null,
    );
  }
}
