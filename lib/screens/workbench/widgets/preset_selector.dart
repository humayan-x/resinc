import 'package:flutter/material.dart';

import '../../../models/compression_options.dart';
import '../../../utils/constants.dart';
import 'presets/compression_toggles.dart';
import 'presets/custom_kb_input.dart';
import 'presets/preset_tile.dart';

/// Control panel widget displaying presets in 3-column rows (total 6 presets in 2 rows,
/// plus up to 1 row for maximum 3 saved custom presets = max 3 rows).
class PresetSelector extends StatefulWidget {
  final CompressionOptions options;
  final List<int> savedCustomPresets;
  final ValueChanged<CompressionPreset> onPresetChanged;
  final ValueChanged<int?> onCustomKBChanged;
  final ValueChanged<int> onSelectSavedCustomKB;
  final ValueChanged<int>? onRemoveSavedCustomKB;
  final ValueChanged<bool> onStripExifChanged;

  const PresetSelector({
    super.key,
    required this.options,
    this.savedCustomPresets = const [],
    required this.onPresetChanged,
    required this.onCustomKBChanged,
    required this.onSelectSavedCustomKB,
    this.onRemoveSavedCustomKB,
    required this.onStripExifChanged,
  });

  @override
  State<PresetSelector> createState() => _PresetSelectorState();
}

class _PresetSelectorState extends State<PresetSelector> {
  late final TextEditingController _customKBController;

  @override
  void initState() {
    super.initState();
    _customKBController = TextEditingController(
      text: widget.options.customTargetKB?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant PresetSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.customTargetKB != widget.options.customTargetKB &&
        (widget.options.customTargetKB?.toString() ?? '') !=
            _customKBController.text) {
      _customKBController.text =
          widget.options.customTargetKB?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _customKBController.dispose();
    super.dispose();
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

    final selectedPreset = widget.options.preset;
    final isCustomPreset = selectedPreset == CompressionPreset.customKB;

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
                Icons.tune_rounded,
                size: 18,
                color: AppConstants.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'Compression Presets',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 1: 3 Presets (Custom KB, Max 100 KB, Max 200 KB)
          Row(
            children: [
              PresetTile(
                label: 'Custom KB',
                isSelected:
                    isCustomPreset &&
                    !widget.savedCustomPresets.contains(
                      widget.options.customTargetKB,
                    ),
                onTap: () => widget.onPresetChanged(CompressionPreset.customKB),
                cardColor: cardColor,
                textColor: textColor,
                borderColor: borderColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(width: 8),
              PresetTile(
                label: CompressionPreset.max100KB.label,
                isSelected: selectedPreset == CompressionPreset.max100KB,
                onTap: () => widget.onPresetChanged(CompressionPreset.max100KB),
                cardColor: cardColor,
                textColor: textColor,
                borderColor: borderColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(width: 8),
              PresetTile(
                label: CompressionPreset.max200KB.label,
                isSelected: selectedPreset == CompressionPreset.max200KB,
                onTap: () => widget.onPresetChanged(CompressionPreset.max200KB),
                cardColor: cardColor,
                textColor: textColor,
                borderColor: borderColor,
                mutedColor: mutedColor,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: 3 Presets (Max 500 KB, 1080p Res, 720p Res)
          Row(
            children: [
              PresetTile(
                label: CompressionPreset.max500KB.label,
                isSelected: selectedPreset == CompressionPreset.max500KB,
                onTap: () => widget.onPresetChanged(CompressionPreset.max500KB),
                cardColor: cardColor,
                textColor: textColor,
                borderColor: borderColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(width: 8),
              PresetTile(
                label: CompressionPreset.p1080.label,
                isSelected: selectedPreset == CompressionPreset.p1080,
                onTap: () => widget.onPresetChanged(CompressionPreset.p1080),
                cardColor: cardColor,
                textColor: textColor,
                borderColor: borderColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(width: 8),
              PresetTile(
                label: CompressionPreset.p720.label,
                isSelected: selectedPreset == CompressionPreset.p720,
                onTap: () => widget.onPresetChanged(CompressionPreset.p720),
                cardColor: cardColor,
                textColor: textColor,
                borderColor: borderColor,
                mutedColor: mutedColor,
              ),
            ],
          ),

          // Row 3: Saved Custom Presets (maximum 3 custom presets saved = 3 rows max)
          if (widget.savedCustomPresets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  if (i < widget.savedCustomPresets.length) ...[
                    PresetTile(
                      label: '${widget.savedCustomPresets[i]} KB',
                      isSelected:
                          isCustomPreset &&
                          widget.options.customTargetKB ==
                              widget.savedCustomPresets[i],
                      onTap: () => widget.onSelectSavedCustomKB(
                        widget.savedCustomPresets[i],
                      ),
                      onDeleted: widget.onRemoveSavedCustomKB != null
                          ? () => widget.onRemoveSavedCustomKB!(
                              widget.savedCustomPresets[i],
                            )
                          : null,
                      isSaved: true,
                      cardColor: cardColor,
                      textColor: textColor,
                      borderColor: borderColor,
                      mutedColor: mutedColor,
                    ),
                  ] else ...[
                    const Spacer(),
                  ],
                ],
              ],
            ),
          ],

          // Custom KB input row when Custom KB preset is selected
          if (isCustomPreset) ...[
            const SizedBox(height: 14),
            CustomKBInput(
              controller: _customKBController,
              cardColor: cardColor,
              textColor: textColor,
              mutedColor: mutedColor,
              onChanged: widget.onCustomKBChanged,
            ),
          ],

          Divider(color: borderColor, height: 28),

          // Privacy toggle
          CompressionToggles(
            stripExif: widget.options.stripExif,
            onStripExifChanged: widget.onStripExifChanged,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
        ],
      ),
    );
  }
}
