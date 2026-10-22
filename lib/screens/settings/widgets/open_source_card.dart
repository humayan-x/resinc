import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/constants.dart';

/// Card displaying open source links as individual clean tiles (one per row, no sub text).
class OpenSourceCard extends StatelessWidget {
  const OpenSourceCard({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error opening link: $e')));
      }
    }
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
                Icons.favorite_outline_rounded,
                size: 18,
                color: AppConstants.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'Open Source & Community',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tile 1: GitHub Repository (no sub text)
          _buildOssTile(
            context,
            title: 'GitHub Repository',
            url: AppConstants.githubRepoUrl,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 8),

          // Tile 2: Issue Tracker (no sub text)
          _buildOssTile(
            context,
            title: 'Issue Tracker',
            url: AppConstants.githubIssuesUrl,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 8),

          // Tile 3: MIT License (no sub text)
          _buildOssTile(
            context,
            title: 'MIT License',
            url: AppConstants.licenseUrl,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
        ],
      ),
    );
  }

  Widget _buildOssTile(
    BuildContext context, {
    required String title,
    required String url,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return InkWell(
      onTap: () => _openUrl(context, url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded, color: mutedColor, size: 16),
          ],
        ),
      ),
    );
  }
}
