import 'package:flutter/material.dart';

import '../../../../utils/constants.dart';

/// Reusable preset tile button with support for selection highlighting and delete action.
class PresetTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDeleted;
  final bool isSaved;
  final Color cardColor;
  final Color textColor;
  final Color borderColor;
  final Color mutedColor;

  const PresetTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.onDeleted,
    this.isSaved = false,
    required this.cardColor,
    required this.textColor,
    required this.borderColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryAccent : cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppConstants.primaryAccent : borderColor,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSaved) ...[
                Icon(
                  Icons.history,
                  size: 13,
                  color: isSelected
                      ? Colors.white
                      : AppConstants.primaryAccent,
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ),
              if (isSaved && onDeleted != null) ...[
                const SizedBox(width: 3),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(
                    Icons.close,
                    size: 13,
                    color: isSelected
                        ? Colors.white70
                        : mutedColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
