import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Reusable gradient button widget
/// Follows DRY principle - single source for gradient buttons
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isEnabled;
  final bool isLoading;
  final EdgeInsets? padding;
  final double borderRadius;
  final bool showGlow;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isEnabled = true,
    this.isLoading = false,
    this.padding,
    this.borderRadius = 30,
    this.showGlow = true,
  });

  /// Factory constructor for icon button variant
  factory GradientButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isEnabled = true,
    bool isLoading = false,
    double iconSize = 20,
  }) {
    return GradientButton(
      key: key,
      onPressed: onPressed,
      isEnabled: isEnabled,
      isLoading: isLoading,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && !isLoading;

    return Container(
      decoration: BoxDecoration(
        gradient: enabled ? AppTheme.getPrimaryGradient(context) : null,
        color: enabled ? null : AppTheme.glassWhite(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: enabled && showGlow ? AppTheme.getGlowShadow(context) : null,
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppTheme.glassWhite(0.5),
          shadowColor: Colors.transparent,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}
