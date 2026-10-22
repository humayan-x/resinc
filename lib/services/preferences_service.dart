import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Lightweight, offline preferences persistence service for ReSinc.
class PreferencesService {
  final Future<Directory> Function()? directoryProvider;
  bool? _cachedHasSeenOnboarding;
  ThemeMode? _cachedThemeMode;
  File? _preferencesFile;

  static const String _preferencesFileName = 'resinc_preferences.json';
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String _keyThemeMode = 'theme_mode';

  PreferencesService({
    this.directoryProvider,
    bool? initialHasSeenOnboarding,
    ThemeMode? initialThemeMode,
  })  : _cachedHasSeenOnboarding = initialHasSeenOnboarding ??
            (directoryProvider == null &&
                    !kIsWeb &&
                    Platform.environment.containsKey('FLUTTER_TEST')
                ? true
                : null),
        _cachedThemeMode = initialThemeMode ??
            (directoryProvider == null &&
                    !kIsWeb &&
                    Platform.environment.containsKey('FLUTTER_TEST')
                ? ThemeMode.dark
                : null);

  static String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode stringToThemeMode(
    String? value, {
    ThemeMode defaultMode = ThemeMode.dark,
  }) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return defaultMode;
    }
  }

  Future<File> _getFile() async {
    if (_preferencesFile != null) return _preferencesFile!;
    final dir = directoryProvider != null
        ? await directoryProvider!()
        : await getApplicationDocumentsDirectory();
    _preferencesFile = File('${dir.path}/$_preferencesFileName');
    return _preferencesFile!;
  }

  /// Checks if the user has already seen the onboarding welcome sheet.
  Future<bool> hasSeenOnboarding() async {
    if (_cachedHasSeenOnboarding != null) {
      return _cachedHasSeenOnboarding!;
    }

    try {
      final file = await _getFile();
      if (!await file.exists()) {
        _cachedHasSeenOnboarding = false;
        return false;
      }

      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final seen = map[_keyHasSeenOnboarding] as bool? ?? false;
      _cachedHasSeenOnboarding = seen;
      return seen;
    } catch (e) {
      debugPrint('PreferencesService.hasSeenOnboarding error: $e');
      _cachedHasSeenOnboarding = false;
      return false;
    }
  }

  /// Updates whether the user has seen the onboarding welcome sheet.
  Future<void> setHasSeenOnboarding(bool value) async {
    _cachedHasSeenOnboarding = value;
    try {
      final file = await _getFile();
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          data = jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {
          data = {};
        }
      }
      data[_keyHasSeenOnboarding] = value;
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('PreferencesService.setHasSeenOnboarding error: $e');
    }
  }

  /// Retrieves the saved ThemeMode, or defaults to [defaultMode].
  Future<ThemeMode> getThemeMode({
    ThemeMode defaultMode = ThemeMode.dark,
  }) async {
    if (_cachedThemeMode != null) {
      return _cachedThemeMode!;
    }

    try {
      final file = await _getFile();
      if (!await file.exists()) {
        _cachedThemeMode = defaultMode;
        return defaultMode;
      }

      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final modeStr = map[_keyThemeMode] as String?;
      final mode = stringToThemeMode(modeStr, defaultMode: defaultMode);
      _cachedThemeMode = mode;
      return mode;
    } catch (e) {
      debugPrint('PreferencesService.getThemeMode error: $e');
      _cachedThemeMode = defaultMode;
      return defaultMode;
    }
  }

  /// Persists the selected ThemeMode.
  Future<void> setThemeMode(ThemeMode mode) async {
    _cachedThemeMode = mode;
    try {
      final file = await _getFile();
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          data = jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {
          data = {};
        }
      }
      data[_keyThemeMode] = themeModeToString(mode);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('PreferencesService.setThemeMode error: $e');
    }
  }

  /// Clears stored preferences (useful for testing or resetting app tour).
  Future<void> resetPreferences() async {
    _cachedHasSeenOnboarding = false;
    _cachedThemeMode = null;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('PreferencesService.resetPreferences error: $e');
    }
  }
}
