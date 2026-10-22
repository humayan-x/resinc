import 'package:flutter/material.dart';

import '../../../state/theme_controller.dart';
import '../../../utils/constants.dart';

/// Section allowing users to switch between System, Dark, and Light themes.
class ThemeSection extends StatelessWidget {
  final ThemeController themeController;

  const ThemeSection({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppConstants.surfaceDark
        : AppConstants.surfaceLight;
    final borderColor = isDark
        ? AppConstants.borderDark
        : AppConstants.borderLight;
    final cardColor = isDark ? AppConstants.cardDark : AppConstants.cardLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final currentMode = themeController.themeMode;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.palette_outlined,
                    size: 18,
                    color: AppConstants.primaryAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Theme',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildThemeOption(
                    context,
                    label: 'System',
                    icon: Icons.brightness_auto_rounded,
                    isSelected: currentMode == ThemeMode.system,
                    onTap: () => themeController.setThemeMode(ThemeMode.system),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    context,
                    label: 'Dark',
                    icon: Icons.dark_mode_outlined,
                    isSelected: currentMode == ThemeMode.dark,
                    onTap: () => themeController.setThemeMode(ThemeMode.dark),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(width: 8),
                  _buildThemeOption(
                    context,
                    label: 'Light',
                    icon: Icons.light_mode_outlined,
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () => themeController.setThemeMode(ThemeMode.light),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryAccent : cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppConstants.primaryAccent : borderColor,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : textColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
