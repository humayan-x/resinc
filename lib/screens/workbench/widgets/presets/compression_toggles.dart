import 'package:flutter/material.dart';

import '../../../../utils/constants.dart';

/// Toggle for EXIF metadata stripping.
class CompressionToggles extends StatelessWidget {
  final bool stripExif;
  final ValueChanged<bool> onStripExifChanged;
  final Color textColor;
  final Color mutedColor;

  const CompressionToggles({
    super.key,
    required this.stripExif,
    required this.onStripExifChanged,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              'Strip EXIF & Location Tags',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Removes GPS coordinates, camera model and timestamps',
              style: TextStyle(color: mutedColor, fontSize: 11),
            ),
            value: stripExif,
            activeThumbColor: AppConstants.primaryAccent,
            onChanged: onStripExifChanged,
          ),
        ],
      ),
    );
  }
}
