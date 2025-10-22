import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_service.dart';

/// Riverpod provider for theme service
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

/// Riverpod notifier for theme mode state management
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;

  ThemeModeNotifier(this._themeService) : super(ThemeMode.system);

  /// Initialize theme from storage
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
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeModeNotifier(themeService);
});

/// Riverpod provider for current theme mode as string
final themeModeStringProvider = FutureProvider<String>((ref) async {
  final themeService = ref.watch(themeServiceProvider);
  return themeService.getThemeModeString();
});
