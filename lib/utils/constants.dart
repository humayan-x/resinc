import 'package:flutter/material.dart';

/// App-wide constants, color palette, and presets.
class AppConstants {
  // Brand info
  static const String appName = 'ReSinc';
  static const String appTagline = 'Offline Android Image Optimizer';
  static const String appVersion = '1.0.0+1';
  static const String appId = 'io.github.humayanx.resinc';
  static const String githubRepoUrl = 'https://github.com/humayan-x/resinc';
  static const String githubIssuesUrl =
      'https://github.com/humayan-x/resinc/issues';
  static const String licenseName = 'MIT License';
  static const String licenseUrl = 'https://opensource.org/licenses/MIT';

  // Brand Assets
  static const String logoDark = 'assets/resinc-logo-dark.png';
  static const String logoWhite = 'assets/resinc-logo-white.png';
  static const String appIcon = 'assets/resinc-icon.png';

  // Saved folder name inside application documents directory
  static const String savedFolderName = 'optimized';
  static const String vaultFolderName = savedFolderName;

  // Preset size thresholds in KB
  static const int minimumTargetKB = 50;
  static const int preset100KB = 100;
  static const int preset200KB = 200;
  static const int preset500KB = 500;

  // Preset resolution widths in pixels
  static const int width1080p = 1920;
  static const int width720p = 1280;

  // Maximum iterative compression passes
  static const int maxCompressionIterations = 6;

  // --- Modern Palette ---
  // Primary & Accent Colors
  static const Color primaryAccent = Color(0xFF5B8C32);
  static const Color primaryAccentLight = Color(0xFF7CAE48);
  static const Color primaryAccentDark = Color(0xFF426822);
  static const Color secondaryAccent = Color(0xFF4D772A);

  // Dark Theme
  static const Color backgroundDark = Color(0xFF202734);
  static const Color surfaceDark = Color(0xFF273142);
  static const Color cardDark = Color(0xFF2F3B4E);
  static const Color borderDark = Color(0xFF404E65);

  // Light Theme (Porcelain & Frost)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Semantic Colors
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textMutedLight = Color(0xFF64748B);
}
