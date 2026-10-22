import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/image_metadata.dart';
import '../../../utils/constants.dart';
import '../../../utils/file_utils.dart';

/// Loaded preview card displayed when an image is actively loaded into Workbench.
class LoadedImagePreviewCard extends StatelessWidget {
  final ImageMetadata metadata;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const LoadedImagePreviewCard({
    super.key,
    required this.metadata,
    required this.onPick,
    required this.onClear,
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
    final cardColor = isDark ? AppConstants.cardDark : AppConstants.cardLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 3 Columns Row:
          // Col 1: Square image preview thumbnail
          // Col 2: Image name (truncated)
          // Col 3: Action buttons (Change, Remove)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.file(File(metadata.path), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metadata.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onPick,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: cardColor,
                      padding: const EdgeInsets.all(6),
                    ),
                    icon: Icon(Icons.refresh, color: textColor, size: 17),
                    tooltip: 'Choose another image',
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: onClear,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: cardColor,
                      padding: const EdgeInsets.all(6),
                    ),
                    icon: Icon(Icons.close, color: textColor, size: 17),
                    tooltip: 'Remove image',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 10),

          // Metadata in a single tight row (Dimension, Size, EXIF Tags)
          Row(
            children: [
              Expanded(
                child: _buildChip(
                  icon: Icons.aspect_ratio_rounded,
                  label: metadata.resolutionString,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildChip(
                  icon: Icons.storage_rounded,
                  label: FileUtils.formatBytes(metadata.fileSizeBytes),
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildChip(
                  icon: Icons.label_outline_rounded,
                  label: '${metadata.tagCount} EXIF tags',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppConstants.primaryAccent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
