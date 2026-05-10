import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_service.dart';

/// Riverpod provider for theme service
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

/// Holds the theme mode read from SharedPreferences before runApp().
/// Overridden in main.dart so the correct theme is applied on frame one.
final initialThemeModeProvider = Provider<ThemeMode>((_) => ThemeMode.system);

/// Riverpod notifier for theme mode state management
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;

  ThemeModeNotifier(this._themeService, ThemeMode initialMode)
      : super(initialMode);

  /// Refresh theme from storage (called after ThemeService.initialize())
  Future<void> initialize() async {
    state = _themeService.getThemeMode();
  }

  /// Update theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _themeService.setThemeMode(themeMode);
    state = themeMode;
  }
}

/// Riverpod provider for theme mode state
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  final initialMode = ref.watch(initialThemeModeProvider);
  return ThemeModeNotifier(themeService, initialMode);
});

/// Riverpod provider for current theme mode as string
final themeModeStringProvider = FutureProvider<String>((ref) async {
  final themeService = ref.watch(themeServiceProvider);
  return themeService.getThemeModeString();
});
