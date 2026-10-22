import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../../../../utils/constants.dart';

/// Action buttons in the SavedDetailDialog (Open in Gallery, Share, Delete).
class SavedDetailActions extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final Color cardColor;
  final Color textColor;

  const SavedDetailActions({
    super.key,
    required this.onShare,
    required this.onDelete,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Open in gallery primary action
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await Gal.open();
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 18, color: Colors.white),
            label: const Text(
              'Open in Gallery',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Share icon ONLY (no button label)
        IconButton(
          onPressed: () {
            Navigator.pop(context);
            onShare();
          },
          style: IconButton.styleFrom(
            backgroundColor: cardColor,
            foregroundColor: textColor,
            side: BorderSide(
              color: AppConstants.primaryAccent.withValues(alpha: 0.4),
            ),
            fixedSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.share_rounded, size: 20),
          tooltip: 'Share',
        ),
        const SizedBox(width: 8),

        // Delete reference icon
        IconButton(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          style: IconButton.styleFrom(
            backgroundColor: cardColor,
            foregroundColor: AppConstants.alertRed,
            side: const BorderSide(color: AppConstants.alertRed),
            fixedSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.delete_outline, size: 20, color: AppConstants.alertRed),
          tooltip: 'Remove Reference',
        ),
      ],
    );
  }
}
