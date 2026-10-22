import 'dart:io';

import '../utils/file_utils.dart';

/// Metrics and metadata of an executed compression job.
class CompressionResult {
  final String originalPath;
  final String compressedPath;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final int? maxSizeBytes;
  final int outputWidth;
  final int outputHeight;
  final bool exifStripped;
  final Duration processingTime;
  final int iterationsCount;

  const CompressionResult({
    required this.originalPath,
    required this.compressedPath,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    this.maxSizeBytes,
    required this.outputWidth,
    required this.outputHeight,
    required this.exifStripped,
    required this.processingTime,
    this.iterationsCount = 1,
  });

  Future<void> verifyFile([String? path]) async {
    final size = await File(path ?? compressedPath).length();
    if (size <= 0 ||
        size != compressedSizeBytes ||
        (maxSizeBytes != null && size > maxSizeBytes!)) {
      throw StateError(
        'File changed or exceeds the selected size limit. Compress again.',
      );
    }
  }

  double get reductionPercentage => FileUtils.calculateReductionPercentage(
    originalSizeBytes,
    compressedSizeBytes,
  );

  int get bytesSaved => originalSizeBytes > compressedSizeBytes
      ? originalSizeBytes - compressedSizeBytes
      : 0;

  String get originalSizeFormatted => FileUtils.formatBytes(originalSizeBytes);

  String get compressedSizeFormatted =>
      FileUtils.formatBytes(compressedSizeBytes);

  String get bytesSavedFormatted => FileUtils.formatBytes(bytesSaved);

  String get resolutionString => '${outputWidth}x$outputHeight px';
}
