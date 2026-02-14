import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Reusable loading indicator widget
/// Follows DRY principle - single source for loading UI
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool showBackground;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size = 24,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppTheme.getPrimaryColor(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: size / 12,
            color: primaryColor,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.glassWhite(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showBackground) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.getBackgroundGradient(context),
        ),
        child: Center(child: content),
      );
    }

    return Center(child: content);
  }

  /// Full screen loading overlay
  static Widget fullScreen({
    required BuildContext context,
    String? message,
  }) {
    return Scaffold(
      body: LoadingWidget(
        message: message,
        showBackground: true,
      ),
    );
  }
}

/// Inline loading indicator for buttons or small spaces
class InlineLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const InlineLoader({
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? Colors.white,
      ),
    );
  }
}
