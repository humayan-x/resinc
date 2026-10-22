import '../utils/constants.dart';

/// Pre-configured optimization presets
enum CompressionPreset {
  customKB('Custom KB'),
  max100KB('Max 100 KB', targetKB: AppConstants.preset100KB),
  max200KB('Max 200 KB', targetKB: AppConstants.preset200KB),
  max500KB('Max 500 KB', targetKB: AppConstants.preset500KB),
  p1080('1080p Res', targetWidth: AppConstants.width1080p),
  p720('720p Res', targetWidth: AppConstants.width720p);

  final String label;
  final int? targetKB;
  final int? targetWidth;

  const CompressionPreset(this.label, {this.targetKB, this.targetWidth});

  bool get isSizeConstrained =>
      targetKB != null || this == CompressionPreset.customKB;
  bool get isDimensionConstrained => targetWidth != null;
}

/// Compression configuration passed to the compression service
class CompressionOptions {
  final CompressionPreset preset;
  final int? customTargetKB;
  final bool stripExif;
  final int defaultQuality;

  const CompressionOptions({
    this.preset = CompressionPreset.max200KB,
    this.customTargetKB,
    this.stripExif = true,
    this.defaultQuality = 80,
  });

  int? get effectiveTargetKB {
    if (preset == CompressionPreset.customKB) {
      return customTargetKB;
    }
    return preset.targetKB;
  }

  int? get effectiveTargetBytes {
    final kb = effectiveTargetKB;
    return kb != null ? kb * 1000 : null;
  }

  bool get isValid =>
      !preset.isSizeConstrained ||
      (effectiveTargetKB != null &&
          effectiveTargetKB! >= AppConstants.minimumTargetKB &&
          effectiveTargetKB! <= 9007199254740);

  static const _unset = Object();

  CompressionOptions copyWith({
    CompressionPreset? preset,
    Object? customTargetKB = _unset,
    bool? stripExif,
    int? defaultQuality,
  }) {
    return CompressionOptions(
      preset: preset ?? this.preset,
      customTargetKB: identical(customTargetKB, _unset)
          ? this.customTargetKB
          : customTargetKB as int?,
      stripExif: stripExif ?? this.stripExif,
      defaultQuality: defaultQuality ?? this.defaultQuality,
    );
  }
}
