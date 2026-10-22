import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// App theme definitions for dark and light modes.
class AppTheme {
  const AppTheme._();

  /// Dark Theme
  static ThemeData darkTheme(String? fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppConstants.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primaryAccent,
        secondary: AppConstants.primaryAccentLight,
        surface: AppConstants.surfaceDark,
        error: AppConstants.alertRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppConstants.textLight,
      ),
      splashColor: AppConstants.primaryAccent.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      hoverColor: AppConstants.primaryAccent.withValues(alpha: 0.08),
      focusColor: AppConstants.primaryAccent.withValues(alpha: 0.12),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppConstants.primaryAccent),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            AppConstants.primaryAccentDark.withValues(alpha: 0.18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(
            AppConstants.primaryAccent.withValues(alpha: 0.12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(
            AppConstants.primaryAccent.withValues(alpha: 0.12),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppConstants.textLight),
      ),
      fontFamily: fontFamily ?? 'PlusJakartaSans',
    );
  }

  /// Light Theme
  static ThemeData lightTheme(String? fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppConstants.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.primaryAccent,
        secondary: AppConstants.primaryAccentLight,
        surface: AppConstants.surfaceLight,
        error: AppConstants.alertRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppConstants.textDark,
      ),
      splashColor: AppConstants.primaryAccent.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      hoverColor: AppConstants.primaryAccent.withValues(alpha: 0.08),
      focusColor: AppConstants.primaryAccent.withValues(alpha: 0.12),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppConstants.primaryAccent),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            AppConstants.primaryAccentDark.withValues(alpha: 0.18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(
            AppConstants.primaryAccent.withValues(alpha: 0.12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(
            AppConstants.primaryAccent.withValues(alpha: 0.12),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppConstants.textDark),
      ),
      fontFamily: fontFamily ?? 'PlusJakartaSans',
    );
  }
}
