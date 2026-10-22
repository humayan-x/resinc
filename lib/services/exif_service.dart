import 'dart:io';

import 'compression_service.dart';

import 'package:flutter/foundation.dart';
import 'package:native_exif/native_exif.dart';

import '../models/image_metadata.dart';

/// Service responsible for parsing EXIF metadata and detecting GPS coordinates.
class ExifService {
  /// Inspects an image file, extracting dimensions, file size, EXIF tags, and GPS coordinates.
  Future<ImageMetadata> inspectImage(String filePath) async {
    final file = File(filePath);
    final fileName = filePath.split(Platform.pathSeparator).last;
    final fileSizeBytes = await file.length();

    Map<String, Object> tags = {};
    bool hasGps = false;
    double? latitude;
    double? longitude;

    Exif? exif;
    try {
      exif = await Exif.fromPath(filePath);
      final rawAttributes = await exif.getAttributes();
      if (rawAttributes != null) {
        tags = rawAttributes;
      }

      final latLong = await exif.getLatLong();
      if (latLong != null) {
        latitude = latLong.latitude;
        longitude = latLong.longitude;
        hasGps = true;
      }
    } catch (e) {
      debugPrint('Exif inspection notice: $e');
    } finally {
      try {
        await exif?.close();
      } catch (_) {}
    }

    final dimensions = await CompressionService.readDimensions(filePath);
    final width = dimensions.$1;
    final height = dimensions.$2;

    return ImageMetadata(
      path: filePath,
      fileName: fileName,
      width: width,
      height: height,
      fileSizeBytes: fileSizeBytes,
      exifTags: tags,
      hasGps: hasGps,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
