import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/language_service.dart';
import '../utils/app_dialogs.dart';
import 'common/section_card.dart';
import 'common/section_header.dart';

/// Widget for photo gallery with camera functionality
/// Updated for new glassmorphism design
class PhotoGallery extends StatelessWidget {
  final List<File> photos;
  final int maxPhotos;
  final ValueChanged<File>? onPhotoAdded;
  final ValueChanged<List<File>>? onPhotosAdded;
  final ValueChanged<int>? onPhotoRemoved;
  final VoidCallback? onCameraPressed;
  final bool enabled;

  const PhotoGallery({
    super.key,
    required this.photos,
    this.maxPhotos = 5,
    this.onPhotoAdded,
    this.onPhotosAdded,
    this.onPhotoRemoved,
    this.onCameraPressed,
    this.enabled = true,
  });

  bool get _isAtMaxCapacity => photos.length >= maxPhotos;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(lang),
          const SizedBox(height: 12),
          _buildPhotoList(context, lang),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageService lang) {
    return SectionHeader(
      icon: Icons.photo_library,
      title: lang.translate('photos'),
      badge: '${photos.length}/$maxPhotos',
    );
  }

  Widget _buildPhotoList(BuildContext context, LanguageService lang) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (!_isAtMaxCapacity && enabled) _buildCameraButton(lang),
          ...photos.asMap().entries.map(
                (entry) => _PhotoThumbnail(
                  photo: entry.value,
                  index: entry.key,
                  enabled: enabled,
                  onRemove: () => _confirmDelete(context, entry.key),
                  onTap: () => _viewPhoto(context, entry.value),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCameraButton(LanguageService lang) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onCameraPressed,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.glowShadow(),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 24, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                lang.translate('camera'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPhoto(BuildContext context, File photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoViewScreen(photo: photo),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final lang = context.read<LanguageService>();
    final confirmed = await AppDialogs.showConfirmation(
      context: context,
      title: lang.translate('delete_photo'),
      message: lang.translate('delete_photo_confirm'),
      confirmText: lang.translate('delete'),
      isDangerous: true,
    );

    if (confirmed) {
      onPhotoRemoved?.call(index);
    }
  }
}

/// Photo thumbnail widget - extracted for reusability
class _PhotoThumbnail extends StatelessWidget {
  final File photo;
  final int index;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _PhotoThumbnail({
    required this.photo,
    required this.index,
    required this.enabled,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          _buildThumbnailImage(),
          if (enabled) _buildDeleteButton(),
        ],
      ),
    );
  }

  Widget _buildThumbnailImage() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.glassWhite(0.2), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.file(
            photo,
            fit: BoxFit.cover,
            cacheWidth: 180,
            cacheHeight: 180,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppTheme.glassWhite(0.05),
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  color: AppTheme.glassWhite(0.3),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppTheme.error,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

/// Full-screen photo view
class _PhotoViewScreen extends StatelessWidget {
  final File photo;

  const _PhotoViewScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageService>();
    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: AppTheme.slate900,
        foregroundColor: Colors.white,
        title: Text(lang.translate('photo_preview')),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            photo,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                Icons.broken_image,
                color: AppTheme.glassWhite(0.5),
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
