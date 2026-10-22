/// Represents the extracted metadata of an intake image.
class ImageMetadata {
  final String path;
  final String fileName;
  final int width;
  final int height;
  final int fileSizeBytes;
  final Map<String, Object> exifTags;
  final bool hasGps;
  final double? latitude;
  final double? longitude;

  const ImageMetadata({
    required this.path,
    required this.fileName,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.exifTags,
    this.hasGps = false,
    this.latitude,
    this.longitude,
  });

  int get tagCount => exifTags.length;

  double get aspectRatio => height > 0 ? width / height : 1.0;

  String get resolutionString => '${width}x$height px';
}
