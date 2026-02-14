/// Centralized application constants
/// Follows KISS and DRY principles - single source of truth for magic numbers
class AppConstants {
  AppConstants._();

  // ==========================================================================
  // ANIMATION DURATIONS
  // ==========================================================================

  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration scanLineAnimation = Duration(milliseconds: 1200);
  static const Duration minimumScanHold = Duration(milliseconds: 2500);
  static const Duration splashDuration = Duration(seconds: 2);

  // ==========================================================================
  // UI DIMENSIONS
  // ==========================================================================

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  static const double smallIconSize = 16.0;
  static const double defaultIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;

  static const double smallFontSize = 12.0;
  static const double defaultFontSize = 14.0;
  static const double mediumFontSize = 16.0;
  static const double largeFontSize = 18.0;
  static const double titleFontSize = 22.0;
  static const double headlineFontSize = 28.0;

  // ==========================================================================
  // LAYOUT BREAKPOINTS
  // ==========================================================================

  static const double smallScreenHeight = 650.0;
  static const double smallMascotSize = 200.0;
  static const double largeMascotSize = 260.0;

  // ==========================================================================
  // NETWORK TIMEOUTS
  // ==========================================================================

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ==========================================================================
  // RETRY CONFIGURATION
  // ==========================================================================

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // ==========================================================================
  // FILE SIZE LIMITS
  // ==========================================================================

  static const int maxPhotoSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int imageCacheSize = 200; // pixels for thumbnail caching

  // ==========================================================================
  // VALIDATION
  // ==========================================================================

  static const int minBarcodeLength = 1;
  static const int maxBarcodeLength = 100;
  static const int maxDescriptionLength = 500;
}
