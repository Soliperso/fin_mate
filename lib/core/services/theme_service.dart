import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing theme preferences
class ThemeService {
  static const String _themeKey = 'theme_mode';

  late SharedPreferences _prefs;

  /// Initialize the theme service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get current theme mode
  ThemeMode getThemeMode() {
    final themeName = _prefs.getString(_themeKey) ?? 'system';
    switch (themeName) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final themeName = themeMode == ThemeMode.light
        ? 'light'
        : themeMode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await _prefs.setString(_themeKey, themeName);
  }

  /// Get theme mode as string
  String getThemeModeString() {
    return _prefs.getString(_themeKey) ?? 'system';
  }

  /// Set theme mode from string
  Future<void> setThemeModeString(String themeName) async {
    if (['light', 'dark', 'system'].contains(themeName)) {
      await _prefs.setString(_themeKey, themeName);
    }
  }
}
