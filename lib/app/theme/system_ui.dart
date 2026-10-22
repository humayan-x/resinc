import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';

/// Utilities for system UI overlay styling (status bar, navigation bar).
class SystemUiConfig {
  const SystemUiConfig._();

  /// Configures edge-to-edge transparent status bar and themed navigation bar.
  static void configureOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppConstants.backgroundDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}
