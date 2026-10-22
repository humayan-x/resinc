import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import 'dashed_border_box.dart';

/// Full-height tap-to-select intake area with dashed border when no image is loaded.
class FullscreenDashedPickArea extends StatelessWidget {
  final bool isInspecting;
  final VoidCallback onPick;

  const FullscreenDashedPickArea({
    super.key,
    required this.isInspecting,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppConstants.surfaceDark
        : AppConstants.surfaceLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    if (isInspecting) {
      return Container(
        margin: const EdgeInsets.fromLTRB(18, 16, 18, 116),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppConstants.primaryAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppConstants.primaryAccent),
            const SizedBox(height: 18),
            Text(
              'Inspecting image & EXIF tags...',
              style: TextStyle(color: mutedColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 116),
      child: GestureDetector(
        onTap: onPick,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: AppConstants.primaryAccent.withValues(alpha: 0.45),
            strokeWidth: 2.0,
            radius: 14.0,
            dashLength: 10.0,
            dashGap: 6.0,
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing circular icon badge
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryAccent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.primaryAccent.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 42,
                    color: AppConstants.primaryAccent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tap to Select Image',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'JPEG, PNG, WebP • On-Device Hardware Processing',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
                const SizedBox(height: 28),

                // Feature pills
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFeatureTag(
                      context,
                      icon: Icons.shield_outlined,
                      label: 'Zero Cloud',
                    ),
                    _buildFeatureTag(
                      context,
                      icon: Icons.compress,
                      label: 'Target KB Ceilings',
                    ),
                    _buildFeatureTag(
                      context,
                      icon: Icons.location_off_outlined,
                      label: 'EXIF Stripping',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTag(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.cardDark : AppConstants.cardLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.primaryAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppConstants.primaryAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
