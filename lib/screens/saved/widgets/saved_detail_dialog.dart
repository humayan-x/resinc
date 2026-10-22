import 'package:flutter/material.dart';

import '../../../models/saved_item.dart';
import '../../../utils/constants.dart';
import 'dialog/saved_detail_actions.dart';
import 'dialog/saved_detail_preview.dart';
import 'dialog/saved_detail_specs.dart';

/// Modal dialog showing preview, size, dimension, and store location of a saved image.
class SavedDetailDialog extends StatelessWidget {
  final SavedItem item;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const SavedDetailDialog({
    super.key,
    required this.item,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppConstants.surfaceDark
        : AppConstants.surfaceLight;
    final cardColor = isDark ? AppConstants.cardDark : AppConstants.cardLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Preview container with privacy status badge
            SavedDetailPreview(
              item: item,
              cardColor: cardColor,
              mutedColor: mutedColor,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Technical specs: Size, Dimension, Store Location, Privacy Status
                  SavedDetailSpecs(
                    item: item,
                    cardColor: cardColor,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 16),

                  // 3. Action Buttons: Open in Gallery, Share icon only, Delete icon
                  SavedDetailActions(
                    onShare: onShare,
                    onDelete: onDelete,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
