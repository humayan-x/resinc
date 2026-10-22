import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/constants.dart';

/// List displaying App Name, App Version, App ID, and License.
class AppDetailsList extends StatelessWidget {
  const AppDetailsList({super.key});

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
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

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
                Icons.info_outline_rounded,
                size: 18,
                color: AppConstants.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'App Details',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Technical properties list
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  label: 'App Name',
                  value: AppConstants.appName,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                Divider(color: surfaceColor, height: 16),
                _buildInfoRow(
                  label: 'Version',
                  value: AppConstants.appVersion,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
                Divider(color: surfaceColor, height: 16),
                _buildInfoRow(
                  label: 'App ID',
                  value: AppConstants.appId,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  isCopyable: true,
                  onCopy: () {
                    Clipboard.setData(
                      const ClipboardData(text: AppConstants.appId),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('App ID copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                Divider(color: surfaceColor, height: 16),
                _buildInfoRow(
                  label: 'License',
                  value: AppConstants.licenseName,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required Color textColor,
    required Color mutedColor,
    bool isCopyable = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: mutedColor, fontSize: 12)),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: AppConstants.primaryAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
