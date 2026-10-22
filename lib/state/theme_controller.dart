import 'package:flutter/material.dart';

import '../services/preferences_service.dart';

/// Lightweight controller managing dynamic Dark, Light, and System theme switching with persistence.
class ThemeController extends ChangeNotifier {
  final PreferencesService? preferencesService;
  ThemeMode _themeMode;

  ThemeController({
    this.preferencesService,
    ThemeMode initialThemeMode = ThemeMode.dark,
  }) : _themeMode = initialThemeMode;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Loads persisted theme mode from preferences if available.
  Future<void> loadSavedTheme() async {
    if (preferencesService == null) return;
    final savedMode =
        await preferencesService!.getThemeMode(defaultMode: _themeMode);
    if (_themeMode != savedMode) {
      _themeMode = savedMode;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    final nextMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await preferencesService?.setThemeMode(mode);
  }
}
