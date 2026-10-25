import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

/// Full-page documentation of the image optimization, downscaling, and compression engine.
class AlgorithmTransparencyPage extends StatelessWidget {
  const AlgorithmTransparencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppConstants.backgroundDark
        : AppConstants.backgroundLight;
    final surfaceColor = isDark
        ? AppConstants.surfaceDark
        : AppConstants.surfaceLight;
    final cardColor = isDark ? AppConstants.cardDark : AppConstants.cardLight;
    final borderColor = isDark
        ? AppConstants.borderDark
        : AppConstants.borderLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Algorithm Transparency',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Engine Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryAccentLight.withValues(
                    alpha: 0.35,
                  ),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryAccent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.primaryAccent.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppConstants.primaryAccentLight,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Optimization Pipeline',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Native Background Processing • Verified Size Limits',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppConstants.primaryAccentLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Technical Principles',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            _buildAlgorithmStep(
              stepNumber: '1',
              title: 'Native JPEG Encoding',
              description: 'Android processes each photo on a background worker. It decodes once, keeps pixels in native memory, and reuses the bitmap for JPEG attempts. No photo data leaves your device.',
              surfaceColor: surfaceColor,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 12),

            _buildAlgorithmStep(
              stepNumber: '2',
              title: 'Native Filtered Downscaling',
              description: 'Native filtered scaling preserves aspect ratio. Working images are capped at 4 megapixels and a 2560-pixel longest edge; resolution presets can impose a smaller limit. Cropping and small size targets may reduce detail.',
              surfaceColor: surfaceColor,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 12),

            _buildAlgorithmStep(
              stepNumber: '3',
              title: 'Fast Verified Ceiling Search',
              description: 'Targets start at 50 KB. Android tries JPEG quality 85, 65, then 45 and returns the first result that fits. If needed, dimensions are reduced using measured output size. The final size includes metadata and aims 1% below the target (1 KB = 1000 bytes). Files are checked again before saving or sharing.',
              surfaceColor: surfaceColor,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 12),

            _buildAlgorithmStep(
              stepNumber: '4',
              title: 'Privacy-Preserving EXIF Stripping',
              description: 'EXIF is stripped by default. Decoded orientation is preserved in the pixels. When metadata preservation is selected, supported tags are copied before measuring the file, with orientation and dimensions updated.',
              surfaceColor: surfaceColor,
              cardColor: cardColor,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgorithmStep({
    required String stepNumber,
    required String title,
    required String description,
    required Color surfaceColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppConstants.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppConstants.primaryAccent.withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: AppConstants.primaryAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
