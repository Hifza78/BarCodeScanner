import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/language_service.dart';

/// Reusable error display widget
/// Follows DRY principle - single source for error UI
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color? color;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = color ?? AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: errorColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: errorColor, fontSize: 13),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final lang = context.read<LanguageService>();
                return SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(lang.translate('retry_button')),
                    style: TextButton.styleFrom(
                      foregroundColor: errorColor,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Compact inline error message
  static Widget inline({
    required String message,
    Color? color,
  }) {
    final errorColor = color ?? AppTheme.error;
    return Row(
      children: [
        Icon(Icons.error_outline, color: errorColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: errorColor, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
