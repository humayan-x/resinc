import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/saved_item.dart';
import '../../../../utils/constants.dart';

/// Specification details card for saved image (file size, dimensions, store location, privacy status).
class SavedDetailSpecs extends StatelessWidget {
  final SavedItem item;
  final Color cardColor;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;

  const SavedDetailSpecs({
    super.key,
    required this.item,
    required this.cardColor,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size
          _buildSpecRow('Size', item.fileSizeFormatted, isHighlight: true),
          Divider(color: surfaceColor, height: 16),

          // Dimension
          _buildSpecRow('Dimension', '${item.width} x ${item.height} px'),
          Divider(color: surfaceColor, height: 16),

          // Store Location (friendly name displayed, full path copied)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Store Location',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        item.storeLocation.isNotEmpty
                            ? item.storeLocation
                            : 'Gallery / ReSinc',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.filePath));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Full path copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryAccent.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppConstants.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: surfaceColor, height: 16),

          // Privacy Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Privacy Status',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.exifStripped
                        ? Icons.verified_user_rounded
                        : Icons.info_outline_rounded,
                    size: 14,
                    color: item.exifStripped
                        ? AppConstants.primaryAccentLight
                        : AppConstants.warningAmber,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.exifStripped
                        ? 'EXIF & Location Stripped'
                        : 'EXIF & Location Kept',
                    style: TextStyle(
                      color: item.exifStripped
                          ? AppConstants.primaryAccentLight
                          : AppConstants.warningAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Divider(color: surfaceColor, height: 16),

          // Original Size & Saved
          _buildSpecRow(
            'Original Size',
            '${item.originalSizeFormatted} (-${item.reductionPercentage.toStringAsFixed(1)}%)',
          ),
          Divider(color: surfaceColor, height: 16),

          _buildSpecRow('Date Saved', item.dateFormatted),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: mutedColor, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppConstants.primaryAccent : textColor,
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
