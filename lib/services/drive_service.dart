import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'auth_service.dart';

/// Service for Google Drive operations
class DriveService {
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  DriveService._internal();

  final AuthService _authService = AuthService();

  /// Main app folder name in Google Drive where all barcode folders will be stored
  static const String _mainFolderName = 'WMS Barcode Scanner';

  /// Upload photos to Google Drive and return the folder URL
  /// Creates a folder with the barcode number containing:
  /// - All captured photos (numbered)
  /// - Barcode image (if available)
  /// - Info file with barcode number and description
  /// Returns the shareable folder link on success, null on failure
  Future<String?> uploadPhotos({
    required String bcn,
    required List<File> photos,
    String description = '',
    Function(double)? onProgress,
  }) async {
    try {
      // Get authenticated client
      final client = await _authService.getAuthenticatedClient();
      final driveApi = drive.DriveApi(client);

      // Get or create the main app folder (e.g., "WMS Barcode Scanner")
      final mainFolderId = await _getOrCreateMainFolder(driveApi);

      // Create barcode folder inside the main folder with BCN number as the name
      final folder = await _createFolder(driveApi, bcn, parentId: mainFolderId);

      if (folder.id == null) {
        throw Exception('Failed to create folder');
      }

      final folderId = folder.id!;

      // Calculate total items to upload (photos + info file)
      final totalItems = photos.length + 1; // +1 for info file
      var uploadedCount = 0;

      // Upload each photo with numbered names
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        final photoName = 'Photo_${(i + 1).toString().padLeft(2, '0')}.jpg';
        await _uploadFileWithName(driveApi, photo, folderId, photoName);
        uploadedCount++;
        onProgress?.call(uploadedCount / totalItems);
      }

      // Create and upload info file
      final infoFile = await _createInfoFile(bcn, description, photos.length, false);
      await _uploadFileWithName(driveApi, infoFile, folderId, 'Device_Info.txt');
      uploadedCount++;
      onProgress?.call(uploadedCount / totalItems);

      // Clean up temp info file
      try {
        await infoFile.delete();
      } catch (_) {}

      // Set folder permissions to "anyone with link can view"
      await _setFolderPermissions(driveApi, folderId);

      // Return the shareable folder link
      return 'https://drive.google.com/drive/folders/$folderId';
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  /// Create an info file with device details in a readable format
  Future<File> _createInfoFile(
    String bcn,
    String description,
    int photoCount,
    bool hasBarcodeImage,
  ) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('                    DEVICE INFORMATION                  ');
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('┌─────────────────────────────────────────────────────┐');
    buffer.writeln('│  BARCODE NUMBER                                     │');
    buffer.writeln('├─────────────────────────────────────────────────────┤');
    buffer.writeln('│  $bcn');
    buffer.writeln('└─────────────────────────────────────────────────────┘');
    buffer.writeln();
    buffer.writeln('┌─────────────────────────────────────────────────────┐');
    buffer.writeln('│  UPLOAD DATE & TIME                                 │');
    buffer.writeln('├─────────────────────────────────────────────────────┤');
    buffer.writeln('│  Date: $dateStr');
    buffer.writeln('│  Time: $timeStr');
    buffer.writeln('└─────────────────────────────────────────────────────┘');
    buffer.writeln();
    buffer.writeln('┌─────────────────────────────────────────────────────┐');
    buffer.writeln('│  FOLDER CONTENTS                                    │');
    buffer.writeln('├─────────────────────────────────────────────────────┤');
    buffer.writeln('│  • Device Photos: $photoCount');
    buffer.writeln('│  • Barcode Image: ${hasBarcodeImage ? "Yes" : "No"}');
    buffer.writeln('│  • Info File: Yes (this file)');
    buffer.writeln('└─────────────────────────────────────────────────────┘');
    buffer.writeln();
    buffer.writeln('┌─────────────────────────────────────────────────────┐');
    buffer.writeln('│  DEVICE DESCRIPTION                                 │');
    buffer.writeln('├─────────────────────────────────────────────────────┤');
    if (description.isNotEmpty) {
      // Split description into lines and add proper formatting
      final lines = description.split('\n');
      for (final line in lines) {
        buffer.writeln('│  $line');
      }
    } else {
      buffer.writeln('│  No description provided');
    }
    buffer.writeln('└─────────────────────────────────────────────────────┘');
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('          Generated by WMS Barcode Scanner App         ');
    buffer.writeln('═══════════════════════════════════════════════════════');

    final tempDir = await getTemporaryDirectory();
    final infoFilePath = p.join(tempDir.path, 'device_info_${DateTime.now().millisecondsSinceEpoch}.txt');
    final infoFile = File(infoFilePath);
    await infoFile.writeAsString(buffer.toString(), encoding: utf8);

    return infoFile;
  }

  /// Find or create the main app folder in Google Drive root
  /// Returns the folder ID of the main app folder
  Future<String> _getOrCreateMainFolder(drive.DriveApi driveApi) async {
    // Search for existing main folder
    final query = "name = '$_mainFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final fileList = await driveApi.files.list(
      q: query,
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    // If folder exists, return its ID
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id!;
    }

    // Create new main folder
    final folder = drive.File()
      ..name = _mainFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id!;
  }

  /// Create a folder on Google Drive
  /// If parentId is provided, the folder will be created inside that parent folder
  Future<drive.File> _createFolder(
    drive.DriveApi driveApi,
    String folderName, {
    String? parentId,
  }) async {
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    // Set parent folder if provided
    if (parentId != null) {
      folder.parents = [parentId];
    }

    return await driveApi.files.create(folder);
  }

  /// Upload a single file to a folder with a custom name
  Future<drive.File> _uploadFileWithName(
    drive.DriveApi driveApi,
    File file,
    String folderId,
    String fileName,
  ) async {
    final fileStream = file.openRead();
    final fileLength = await file.length();

    final driveFile = drive.File()
      ..name = fileName
      ..parents = [folderId];

    final media = drive.Media(
      fileStream,
      fileLength,
      contentType: _getContentType(fileName),
    );

    return await driveApi.files.create(
      driveFile,
      uploadMedia: media,
    );
  }

  /// Set folder permissions to "anyone with link can view"
  Future<void> _setFolderPermissions(
    drive.DriveApi driveApi,
    String folderId,
  ) async {
    final permission = drive.Permission()
      ..role = 'reader'
      ..type = 'anyone';

    await driveApi.permissions.create(permission, folderId);
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.txt':
        return 'text/plain; charset=utf-8';
      default:
        return 'application/octet-stream';
    }
  }
}
