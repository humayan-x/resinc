import '../utils/file_utils.dart';

/// Represents an optimized image saved to the gallery and referenced in the app.
class SavedItem {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final int originalSizeBytes;
  final DateTime createdAt;
  final int width;
  final int height;
  final String storeLocation;
  final bool exifStripped;

  const SavedItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.originalSizeBytes,
    required this.createdAt,
    required this.width,
    required this.height,
    this.storeLocation = 'Gallery / ReSinc',
    this.exifStripped = true,
  });

  int get bytesSaved =>
      originalSizeBytes > fileSizeBytes ? originalSizeBytes - fileSizeBytes : 0;

  double get reductionPercentage =>
      FileUtils.calculateReductionPercentage(originalSizeBytes, fileSizeBytes);

  String get fileSizeFormatted => FileUtils.formatBytes(fileSizeBytes);

  String get originalSizeFormatted => FileUtils.formatBytes(originalSizeBytes);

  String get bytesSavedFormatted => FileUtils.formatBytes(bytesSaved);

  String get dateFormatted => FileUtils.formatDate(createdAt);

  String get resolutionString => '${width}x$height px';
}
