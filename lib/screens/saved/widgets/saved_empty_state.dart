import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

/// Empty state placeholder shown when no images have been saved yet.
class SavedEmptyState extends StatelessWidget {
  const SavedEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppConstants.surfaceDark
        : AppConstants.surfaceLight;
    final borderColor = isDark
        ? AppConstants.borderDark
        : AppConstants.borderLight;
    final textColor = isDark ? AppConstants.textLight : AppConstants.textDark;
    final mutedColor = isDark
        ? AppConstants.textMuted
        : AppConstants.textMutedLight;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 44,
                  color: AppConstants.primaryAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Saved Images',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Images you compress in the Workbench and choose to "Save" will appear here as saved references.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
