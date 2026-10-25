import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/file_utils.dart';

/// Top header for the Saved tab displaying total file-size reduction, count, and clear action.
class SavedStatsHeader extends StatelessWidget {
  final int totalSavedBytes;
  final int itemCount;
  final VoidCallback onClearAll;

  const SavedStatsHeader({
    super.key,
    required this.totalSavedBytes,
    required this.itemCount,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppConstants.surfaceDark
        : AppConstants.surfaceLight;
    final borderColor = isDark
        ? AppConstants.borderDark
        : AppConstants.borderLight;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.compress_rounded,
              color: AppConstants.primaryAccent,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FileUtils.formatBytes(totalSavedBytes),
                  style: const TextStyle(
                    color: AppConstants.primaryAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'File-size reduction across $itemCount images',
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
                Text(
                  'Compared with originals, not freed storage.',
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
              ],
            ),
          ),
          if (itemCount > 0)
            IconButton(
              onPressed: () => _showClearConfirmation(context),
              icon: Icon(Icons.delete_sweep_outlined, color: mutedColor),
              tooltip: 'Clear Saved References',
            ),
        ],
      ),
    );
  }

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
          'Clear Saved References?',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'This removes local photo copies and their history. Photos in your device gallery remain untouched.',
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
              onClearAll();
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
}
