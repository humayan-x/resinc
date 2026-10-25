import 'package:flutter/material.dart';

import '../../state/theme_controller.dart';
import '../../state/workbench_controller.dart';
import '../../utils/constants.dart';
import 'widgets/compression_hud.dart';
import 'widgets/crop_image_dialog.dart';
import 'widgets/fullscreen_dashed_pick_area.dart';
import 'widgets/loaded_image_preview_card.dart';
import 'widgets/preset_selector.dart';

/// Screen for Tab 1: Full-height tap-to-select area (empty) vs interactive processing workbench.
class WorkbenchTab extends StatelessWidget {
  final WorkbenchController controller;
  final ThemeController themeController;
  final VoidCallback? onOpenGuide;

  const WorkbenchTab({
    super.key,
    required this.controller,
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

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AbsorbPointer(
          absorbing: controller.isBusy,
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              leading: controller.hasImage
                  ? IconButton(
                      tooltip: controller.hasResult
                          ? 'Change presets'
                          : 'Back to Home',
                      onPressed: controller.isBusy
                          ? null
                          : (controller.hasResult
                                ? controller.clearResult
                                : controller.reset),
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
              title: Text(
                AppConstants.appName,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                if (onOpenGuide != null)
                  IconButton(
                    onPressed: onOpenGuide,
                    icon: Icon(Icons.help_outline_rounded, color: textColor),
                    tooltip: 'Quick Guide',
                  ),
                IconButton(
                  onPressed: themeController.toggleTheme,
                  icon: Icon(
                    themeController.isDarkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: textColor,
                  ),
                  tooltip: 'Toggle Theme',
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: !controller.hasImage
                // Whole section below header and above floating bar for tap-to-select image
                ? Column(
                    children: [
                      if (controller.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            controller.errorMessage!,
                            style: const TextStyle(
                              color: AppConstants.alertRed,
                            ),
                          ),
                        ),
                      Expanded(
                        child: FullscreenDashedPickArea(
                          isInspecting: controller.isInspecting,
                          onPick: controller.pickImage,
                        ),
                      ),
                    ],
                  )
                // Loaded state: scrollable workbench controls
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error notification banner if any
                        if (controller.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppConstants.alertRed.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppConstants.alertRed.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppConstants.alertRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    controller.errorMessage!,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Compact 3-Column Loaded image preview card
                        LoadedImagePreviewCard(
                          metadata: controller.selectedImage!,
                          onPick: controller.pickImage,
                          onClear: controller.reset,
                        ),
                        const SizedBox(height: 12),

                        // Replace Presets with Compression Complete HUD after compression
                        if (!controller.hasResult) ...[
                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Crop Image',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    controller.hasCrop
                                        ? 'Your cropped proportions will be preserved.'
                                        : 'Optional. Original proportions are preserved without a crop.',
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppConstants.primaryAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.crop),
                                    label: Text(
                                      controller.isCropping
                                          ? 'Applying crop…'
                                          : 'Crop Image',
                                    ),
                                    onPressed: controller.isBusy
                                        ? null
                                        : () async {
                                            final source =
                                                controller.originalImage;
                                            if (source == null) return;
                                            final selection =
                                                await showDialog<Rect>(
                                                  context: context,
                                                  builder: (_) =>
                                                      CropImageDialog(
                                                        path: source.path,
                                                        initialSelection:
                                                            controller
                                                                .cropSelection,
                                                      ),
                                                );
                                            if (!context.mounted ||
                                                selection == null ||
                                                controller.originalImage !=
                                                    source) {
                                              return;
                                            }
                                            await controller.applyCrop(
                                              selection,
                                            );
                                          },
                                  ),
                                  if (controller.hasCrop)
                                    TextButton(
                                      onPressed: controller.isBusy
                                          ? null
                                          : controller.restoreOriginal,
                                      child: const Text('Restore Original'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Presets and options
                          PresetSelector(
                            options: controller.options,
                            savedCustomPresets: controller.savedCustomPresets,
                            onPresetChanged: controller.setPreset,
                            onCustomKBChanged: controller.setCustomTargetKB,
                            onSelectSavedCustomKB:
                                controller.selectSavedCustomPreset,
                            onRemoveSavedCustomKB:
                                controller.removeSavedCustomPreset,
                            onStripExifChanged: controller.setStripExif,
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          // Compression Complete HUD (Replaces Presets)
                          CompressionHUD(result: controller.compressionResult!),
                        ],

                        // Bottom clearance for floating nav bar
                        const SizedBox(height: 96),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
