import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/language_service.dart';
import 'common/section_card.dart';
import 'common/section_header.dart';

/// Widget for BCN (Barcode Control Number) display section
/// Updated for new glassmorphism design with amber/orange theme
class BcnInputSection extends StatelessWidget {
  final String bcnValue;
  final VoidCallback? onScanPressed;

  const BcnInputSection({
    super.key,
    required this.bcnValue,
    this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    final hasBarcode = bcnValue.isNotEmpty;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(lang),
          if (hasBarcode) ...[
            const SizedBox(height: 16),
            _buildBarcodeDisplay(context, lang),
          ],
          const SizedBox(height: 16),
          _buildScanButton(lang),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageService lang) {
    return SectionHeader(
      icon: Icons.qr_code_scanner,
      title: lang.translate('barcode_scanner'),
      badge: bcnValue.isNotEmpty ? lang.translate('scanned') : null,
    );
  }

  Widget _buildBarcodeDisplay(BuildContext context, LanguageService lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassWhite(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.amber500.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // BCN Number display
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.numbers,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.translate('bcn_number'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.glassWhite(0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bcnValue,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                        color: AppTheme.amber300,
                      ),
                    ),
                  ],
                ),
              ),
              // Copy button
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: bcnValue));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(lang.translate('barcode_copied')),
                        ],
                      ),
                      backgroundColor: AppTheme.success,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.copy, color: AppTheme.amber400),
                tooltip: lang.translate('copy_bcn'),
              ),
            ],
          ),

          // Success indicator
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppTheme.success, size: 16),
                const SizedBox(width: 6),
                Text(
                  lang.translate('barcode_captured'),
                  style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(LanguageService lang) {
    final hasBarcode = bcnValue.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppTheme.glowShadow(),
        ),
        child: ElevatedButton.icon(
          onPressed: onScanPressed,
          icon: Icon(
            hasBarcode ? Icons.refresh : Icons.qr_code_scanner,
            size: 22,
          ),
          label: Text(
            hasBarcode ? lang.translate('scan_new_barcode') : lang.translate('start_scanning'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
