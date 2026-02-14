import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/language_service.dart';

/// Widget for the Upload button
/// Updated for new glassmorphism design with amber/orange gradient
class UploadButton extends StatelessWidget {
  final bool isEnabled;
  final bool isUploading;
  final double progress;
  final VoidCallback? onPressed;

  const UploadButton({
    super.key,
    required this.isEnabled,
    this.isUploading = false,
    this.progress = 0.0,
    this.onPressed,
  });

  bool get _isActive => isEnabled && !isUploading;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
        gradient: _isActive ? AppTheme.primaryGradient : null,
        color: _isActive ? null : AppTheme.glassWhite(0.1),
        boxShadow: _isActive ? AppTheme.glowShadow() : null,
      ),
      child: ElevatedButton.icon(
        onPressed: _isActive ? onPressed : null,
        icon: _buildIcon(),
        label: _buildLabel(lang),
        style: _buildButtonStyle(),
      ),
    );
  }

  Widget _buildIcon() {
    if (isUploading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return const Icon(Icons.cloud_upload_outlined, size: 24);
  }

  Widget _buildLabel(LanguageService lang) {
    return Text(
      isUploading ? '${lang.translate('uploading')} ${(progress * 100).toInt()}%' : lang.translate('upload_to_drive'),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.transparent,
      disabledForegroundColor: AppTheme.glassWhite(0.5),
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
      ),
      elevation: 0,
    );
  }
}
