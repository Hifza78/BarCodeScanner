import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for SharedPreferences access
/// Follows Single Responsibility Principle - handles all persistent storage
class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  // Preference Keys - centralized to avoid duplication
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserEmail = 'user_email';
  static const String keyIsDriveConnected = 'is_drive_connected';
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyLanguage = 'app_language';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyAutoUpload = 'auto_upload';
  static const String keyNotifications = 'notifications_enabled';

  /// Initialize the preferences service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance (lazy initialization)
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Generic getters
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final p = await prefs;
    return p.getBool(key) ?? defaultValue;
  }

  Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  Future<int?> getInt(String key) async {
    final p = await prefs;
    return p.getInt(key);
  }

  // Generic setters
  Future<bool> setBool(String key, bool value) async {
    final p = await prefs;
    return p.setBool(key, value);
  }

  Future<bool> setString(String key, String value) async {
    final p = await prefs;
    return p.setString(key, value);
  }

  Future<bool> setInt(String key, int value) async {
    final p = await prefs;
    return p.setInt(key, value);
  }

  Future<bool> remove(String key) async {
    final p = await prefs;
    return p.remove(key);
  }

  // Auth-related convenience methods
  Future<bool> get isLoggedIn => getBool(keyIsLoggedIn);
  Future<bool> get isDriveConnected => getBool(keyIsDriveConnected);
  Future<String?> get userEmail => getString(keyUserEmail);

  Future<void> setLoginState(bool isLoggedIn, {String? email}) async {
    await setBool(keyIsLoggedIn, isLoggedIn);
    if (isLoggedIn && email != null) {
      await setString(keyUserEmail, email);
    } else if (!isLoggedIn) {
      await remove(keyUserEmail);
    }
  }

  Future<void> setDriveConnected(bool isConnected) async {
    await setBool(keyIsDriveConnected, isConnected);
  }

  // Theme-related convenience methods
  Future<String?> get themeMode => getString(keyThemeMode);

  Future<void> setThemeMode(String mode) async {
    await setString(keyThemeMode, mode);
  }

  // Language-related convenience methods
  Future<String?> get language => getString(keyLanguage);

  Future<void> setLanguage(String language) async {
    await setString(keyLanguage, language);
  }

  // Onboarding-related convenience methods
  Future<bool> get isOnboardingComplete => getBool(keyOnboardingComplete);

  Future<void> setOnboardingComplete(bool complete) async {
    await setBool(keyOnboardingComplete, complete);
  }

  // Auto-upload convenience methods
  Future<bool> get isAutoUploadEnabled => getBool(keyAutoUpload);

  Future<void> setAutoUpload(bool enabled) async {
    await setBool(keyAutoUpload, enabled);
  }

  // Notifications convenience methods (default: true)
  Future<bool> get isNotificationsEnabled =>
      getBool(keyNotifications, defaultValue: true);

  Future<void> setNotifications(bool enabled) async {
    await setBool(keyNotifications, enabled);
  }

  /// Clear all preferences (for logout)
  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
