import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/language_service.dart';
import 'common/section_card.dart';
import 'common/section_header.dart';

/// Widget for device description input section
/// Updated for new glassmorphism design
class DescriptionSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const DescriptionSection({
    super.key,
    required this.controller,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderWithOptional(
            icon: Icons.description,
            title: lang.translate('device_description'),
          ),
          const SizedBox(height: 12),
          _buildTextField(lang),
        ],
      ),
    );
  }

  Widget _buildTextField(LanguageService lang) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: 3,
      maxLines: 6,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: AppTheme.textFieldDecoration(
        hintText: lang.translate('description_hint'),
      ),
      onChanged: onChanged,
    );
  }
}
