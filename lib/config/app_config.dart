/// Application configuration constants
class AppConfig {
  // Warehouse Management System URL
  static const String wmsBaseUrl = 'http://jsoft.vipserv.org/x/engine/sl_addGallery.php';

  // Maximum number of photos per device
  static const int maxPhotos = 5;

  // Google Drive API scopes
  static const List<String> driveScopes = [
    'https://www.googleapis.com/auth/drive.file',
  ];

  // App name for Google Drive folder prefix
  static const String appName = 'WMS Scanner';

  /// Generate folder name for Google Drive
  /// Now uses just the barcode number for cleaner organization
  static String getFolderName(String bcn) {
    return bcn;
  }

  /// Build WMS redirect URL with query parameters
  /// Sends bcn (barcode) and drive (Google Drive folder URL) to WMS
  static String buildWmsUrl({
    required String bcn,
    required String driveUrl,
    required String description,
  }) {
    final encodedBcn = Uri.encodeComponent(bcn);
    final encodedDrive = Uri.encodeComponent(driveUrl);

    return '$wmsBaseUrl?bcn=$encodedBcn&drive=$encodedDrive';
  }
}
