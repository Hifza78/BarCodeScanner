import 'package:flutter/material.dart';
import 'preferences_service.dart';

/// Theme mode options
enum AppThemeMode { light, dark, system }

/// Service to manage app theme state with persistence
class ThemeService extends ChangeNotifier {
  final PreferencesService _prefs = PreferencesService();

  AppThemeMode _themeMode = AppThemeMode.light;
  bool _isInitialized = false;

  AppThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  /// Check if current theme is dark (considering system theme)
  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.light:
        return false;
      case AppThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  /// Initialize theme from stored preference
  Future<void> initialize() async {
    if (_isInitialized) return;

    final storedTheme = await _prefs.themeMode;

    if (storedTheme != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == storedTheme,
        orElse: () => AppThemeMode.light,
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Set theme mode and persist
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    await _prefs.setThemeMode(mode.name);
  }

  /// Get theme mode display name
  String getThemeModeDisplayName() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}
