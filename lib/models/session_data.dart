import 'dart:io';
import '../config/app_config.dart';

/// Data model for the current scanning session
/// Following Single Responsibility Principle - only manages session state
class SessionData {
  String bcn;
  String description;
  List<File> photos;
  bool isUploading;
  double uploadProgress;
  String? error;

  SessionData({
    this.bcn = '',
    this.description = '',
    List<File>? photos,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
  }) : photos = photos ?? [];

  /// Maximum photos allowed - using centralized config
  static int get maxPhotos => AppConfig.maxPhotos;

  /// Check if the session has minimum required data for upload
  bool get isReadyForUpload => bcn.isNotEmpty && photos.isNotEmpty;

  /// Check if more photos can be added
  bool get canAddMorePhotos => photos.length < maxPhotos;

  /// Get the number of photos
  int get photoCount => photos.length;

  /// Get remaining photo slots
  int get remainingSlots => maxPhotos - photos.length;

  /// Reset session data for next device
  void reset() {
    bcn = '';
    description = '';
    photos.clear();
    isUploading = false;
    uploadProgress = 0.0;
    error = null;
  }

  /// Add a photo to the session
  /// Returns true if photo was added successfully
  bool addPhoto(File photo) {
    if (canAddMorePhotos) {
      photos.add(photo);
      return true;
    }
    return false;
  }

  /// Add multiple photos to the session
  /// Only adds up to the remaining slots available
  void addPhotos(List<File> newPhotos) {
    final photosToAdd = newPhotos.take(remainingSlots);
    photos.addAll(photosToAdd);
  }

  /// Remove a photo from the session
  /// Also deletes the file from temp storage
  void removePhoto(int index) {
    if (index >= 0 && index < photos.length) {
      final photo = photos.removeAt(index);
      _deletePhotoSafely(photo);
    }
  }

  /// Clear all photos and delete temp files
  Future<void> clearPhotos() async {
    for (final photo in photos) {
      await _deletePhotoAsyncSafely(photo);
    }
    photos.clear();
  }

  /// Safely delete a photo file synchronously
  void _deletePhotoSafely(File photo) {
    try {
      if (photo.existsSync()) {
        photo.deleteSync();
      }
    } catch (_) {
      // Ignore deletion errors - file may already be deleted
    }
  }

  /// Safely delete a photo file asynchronously
  Future<void> _deletePhotoAsyncSafely(File photo) async {
    try {
      if (await photo.exists()) {
        await photo.delete();
      }
    } catch (_) {
      // Ignore deletion errors - file may already be deleted
    }
  }
}
