import 'package:flutter/material.dart';

import '../../state/saved_controller.dart';
import '../../state/theme_controller.dart';
import '../../utils/constants.dart';
import 'widgets/app_details_list.dart';
import 'widgets/guides_section.dart';
import 'widgets/open_source_card.dart';
import 'widgets/storage_section.dart';
import 'widgets/theme_section.dart';

/// Screen for Tab 3: Settings, preferences, theme mode, app details, architecture, OSS, and storage.
class SettingsTab extends StatelessWidget {
  final SavedController savedController;
  final ThemeController themeController;
  final VoidCallback? onOpenGuide;

  const SettingsTab({
    super.key,
    required this.savedController,
    required this.themeController,
    this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppConstants.backgroundDark
        : AppConstants.backgroundLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Theme Section at the top
            ThemeSection(themeController: themeController),
            const SizedBox(height: 16),

            // 2. App Details (App Name, Version, App ID, License)
            const AppDetailsList(),
            const SizedBox(height: 16),

            // 3. Guides Section (How ReSinc Works, Architecture, Algorithms)
            GuidesSection(onOpenGuide: onOpenGuide),
            const SizedBox(height: 16),

            // 4. Open Source & Community Section (Above Saved Images Storage)
            const OpenSourceCard(),
            const SizedBox(height: 16),

            // 5. Saved Images Storage Section
            StorageSection(savedController: savedController),

            // Bottom clearance for floating nav bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
