import 'package:flutter/material.dart';

import '../../../state/saved_controller.dart';
import '../../../utils/constants.dart';
import '../../../utils/file_utils.dart';

/// Card showing saved images storage summary and a button to clear references.
class StorageSection extends StatelessWidget {
  final SavedController savedController;

  const StorageSection({super.key, required this.savedController});

  void _showClearConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppConstants.surfaceDark
        : AppConstants.surfaceLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Clear All Saved References?',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'This will clear saved image references from the app. Original gallery images will not be affected.',
          style: TextStyle(color: mutedColor, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: mutedColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              savedController.clearSaved();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved references cleared.'),
                  backgroundColor: AppConstants.primaryAccentDark,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppConstants.surfaceDark
        : AppConstants.surfaceLight;
    final borderColor = isDark
        ? AppConstants.borderDark
        : AppConstants.borderLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    return ListenableBuilder(
      listenable: savedController,
      builder: (context, _) {
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
              Text(
                'Saved Images Storage',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saved References: ${savedController.itemCount} (${FileUtils.formatBytes(savedController.totalSavedBytes)} space saved)',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: savedController.itemCount > 0
                    ? () => _showClearConfirmation(context)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.alertRed,
                  side: BorderSide(
                    color: savedController.itemCount > 0
                        ? AppConstants.alertRed.withValues(alpha: 0.6)
                        : borderColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Clear Saved References'),
              ),
            ],
          ),
        );
      },
    );
  }
}
