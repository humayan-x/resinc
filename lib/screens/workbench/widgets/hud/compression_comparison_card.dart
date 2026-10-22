import 'package:flutter/material.dart';

import '../../../../models/compression_result.dart';
import '../../../../utils/constants.dart';

/// Card displaying Original, Optimized, and Saved metrics with visual flow indicator.
class CompressionComparisonCard extends StatelessWidget {
  final CompressionResult result;
  final Color cardColor;
  final Color mutedColor;

  const CompressionComparisonCard({
    super.key,
    required this.result,
    required this.cardColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricColumn(
            label: 'ORIGINAL',
            value: result.originalSizeFormatted,
            subValue: 'Source',
            color: mutedColor,
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppConstants.primaryAccent,
            size: 20,
          ),
          _buildMetricColumn(
            label: 'OPTIMIZED',
            value: result.compressedSizeFormatted,
            subValue: result.resolutionString,
            color: AppConstants.primaryAccent,
          ),
          _buildMetricColumn(
            label: 'SAVED',
            value: result.bytesSavedFormatted,
            subValue: '${result.processingTime.inMilliseconds} ms',
            color: AppConstants.primaryAccentLight,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required String label,
    required String value,
    required String subValue,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subValue,
          style: const TextStyle(color: AppConstants.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
