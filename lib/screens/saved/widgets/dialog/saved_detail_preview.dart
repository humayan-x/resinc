import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../models/saved_item.dart';
import '../../../../utils/constants.dart';

/// Image preview hero section of the SavedDetailDialog with floating privacy badge and close button.
class SavedDetailPreview extends StatelessWidget {
  final SavedItem item;
  final Color cardColor;
  final Color mutedColor;

  const SavedDetailPreview({
    super.key,
    required this.item,
    required this.cardColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.black,
          constraints: const BoxConstraints(maxHeight: 280),
          width: double.infinity,
          child: InteractiveViewer(
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(item.filePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: cardColor,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: mutedColor,
                  size: 48,
                ),
              ),
            ),
          ),
        ),

        // Privacy badge floating over top-left of preview
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: item.exifStripped
                    ? AppConstants.primaryAccent.withValues(alpha: 0.6)
                    : AppConstants.warningAmber.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.exifStripped
                      ? Icons.verified_user_rounded
                      : Icons.info_outline_rounded,
                  size: 13,
                  color: item.exifStripped
                      ? AppConstants.primaryAccentLight
                      : AppConstants.warningAmber,
                ),
                const SizedBox(width: 5),
                Text(
                  item.exifStripped ? 'EXIF & GPS Stripped' : 'EXIF & GPS Kept',
                  style: TextStyle(
                    color: item.exifStripped
                        ? Colors.white
                        : AppConstants.warningAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Close button top-right
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.6),
            ),
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}
