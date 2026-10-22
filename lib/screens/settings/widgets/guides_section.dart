import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../pages/algorithm_transparency_page.dart';
import '../pages/offline_architecture_page.dart';

/// Section providing one-tap navigation tiles to Guides, Architecture, and Algorithm pages.
class GuidesSection extends StatelessWidget {
  final VoidCallback? onOpenGuide;

  const GuidesSection({
    super.key,
    this.onOpenGuide,
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
                Icons.menu_book_outlined,
                size: 18,
                color: AppConstants.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'Guides',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tile 1: How ReSinc Works (no subtext)
          if (onOpenGuide != null) ...[
            _buildNavTile(
              context,
              title: 'How ReSinc Works',
              onTap: onOpenGuide!,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 8),
          ],

          // Tile 2: Offline-Only Architecture (no subtext)
          _buildNavTile(
            context,
            title: 'Offline-Only Architecture',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfflineArchitecturePage(),
                ),
              );
            },
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 8),

          // Tile 3: Algorithm Transparency (no subtext)
          _buildNavTile(
            context,
            title: 'Algorithm Transparency',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AlgorithmTransparencyPage(),
                ),
              );
            },
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return InkWell(
      onTap: onTap,
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
            Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Backward compatibility alias.
typedef ArchitectureSection = GuidesSection;
