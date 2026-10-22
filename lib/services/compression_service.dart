import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'lanczos_encoder.dart';

import 'package:path_provider/path_provider.dart';

import '../models/compression_options.dart';
import '../models/compression_result.dart';
import '../models/image_metadata.dart';

/// Native JPEG encoding with a verified, inclusive byte ceiling.
typedef ImageEncoder = Future<String?> Function(
  String source,
  String target,
  int quality,
  int width,
  int height,
  bool keepExif,
);

class CompressionService {
  final ImageEncoder? _encode;
  final Future<Directory> Function() _temporaryDirectory;
  final Future<(int, int)> Function(String) _dimensions;

  CompressionService({
    ImageEncoder? encoder,
    Future<Directory> Function()? temporaryDirectory,
    Future<(int, int)> Function(String)? dimensions,
  }) : _encode = encoder,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _dimensions = dimensions ?? readDimensions;

  Future<CompressionResult> compressImage({
    required ImageMetadata metadata,
    required CompressionOptions options,
  }) async {
    if (!options.isValid) {
      throw ArgumentError('Enter a whole-number target of at least 50 KB.');
    }
    final stopwatch = Stopwatch()..start();
    final temp = await _temporaryDirectory();
    final job = await temp.createTemp('resinc_job_');
    String? winner;
    int iterations = 0;
    try {
      // Read the decoded image rather than trusting potentially stale EXIF sizes.
      final raster = _encode == null
          ? await LanczosEncoder.open(metadata.path, job, metadata.exifTags)
          : null;
      final encode = _encode ?? raster!.encode;
      final sourceSize = raster == null
          ? await _dimensions(metadata.path)
          : (raster.width, raster.height);
      int width = sourceSize.$1;
      int height = sourceSize.$2;
      final limit = options.preset.targetWidth;
      if (limit != null) {
        final scale = math.min(1.0, limit / math.max(width, height));
        width = math.max(1, (width * scale).floor());
        height = math.max(1, (height * scale).floor());
      }
      final target = options.effectiveTargetBytes;
      // Decimal KB avoids files exceeding limits in decimal-size consumers.
      // Leave headroom rather than relying on rounded display values.
      final budget = target == null ? null : target * 99 ~/ 100;
      double scale = 1.0;
      final baseWidth = width;
      final baseHeight = height;
      // Each resize level has its own complete quality search. All attempts
      // use the original, avoiding accumulated JPEG recompression artifacts.
      for (int pass = 0; pass < 32; pass++) {
        int? smallestAttempt;
        int low = target == null ? options.defaultQuality : 40;
        int high = target == null ? options.defaultQuality : 95;
        while (low <= high) {
          final quality = (low + high) ~/ 2;
          final path = '${job.path}/${iterations++}.jpg';
          final output = await encode(
            metadata.path,
            path,
            quality,
            width,
            height,
            !options.stripExif,
          );
          if (output == null) {
            throw StateError(
              'The image could not be encoded. Try another image.',
            );
          }
          final size = await File(output).length();
          if (size == 0) {
            throw StateError('The encoder returned an empty image.');
          }
          smallestAttempt = math.min(smallestAttempt ?? size, size);
          if (budget == null || size <= budget) {
            if (winner != null) await File(winner).delete();
            winner = output;
            low = quality + 1;
          } else {
            await File(output).delete();
            high = quality - 1;
          }
        }
        if (winner != null) break;
        if (width == 1 && height == 1) break;
        // Byte size roughly follows pixel area. This estimate only selects
        // the next dimensions; actual encoded bytes remain authoritative.
        final resize =
            math.sqrt(budget! / smallestAttempt!).clamp(0.4, 0.9) * 0.95;
        scale *= resize;
        width = math.max(1, (baseWidth * scale).floor());
        height = math.max(1, (baseHeight * scale).floor());
      }
      if (winner == null) {
        throw StateError(
          'Cannot meet this target. Increase the KB limit'
          '${options.stripExif ? '.' : ' or enable EXIF stripping.'}',
        );
      }
      final size = await File(winner).length();
      if (budget != null && size > budget) {
        throw StateError('Output exceeds the selected size limit.');
      }
      final dimensions = await _dimensions(winner);
      stopwatch.stop();
      final result = CompressionResult(
        originalPath: metadata.path,
        compressedPath: winner,
        originalSizeBytes: metadata.fileSizeBytes,
        compressedSizeBytes: size,
        maxSizeBytes: target,
        outputWidth: dimensions.$1,
        outputHeight: dimensions.$2,
        exifStripped: options.stripExif,
        processingTime: stopwatch.elapsed,
        iterationsCount: iterations,
      );
      // Retain only the verified result; the controller owns its lifetime.
      for (final file in await job.list().toList()) {
        if (file.path != winner) await file.delete();
      }
      return result;
    } catch (_) {
      if (await job.exists()) await job.delete(recursive: true);
      rethrow;
    }
  }

  static Future<(int, int)> readDimensions(String path) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width < 1 || descriptor.height < 1) {
          throw const FormatException('Invalid image dimensions.');
        }
        return (descriptor.width, descriptor.height);
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }

  static Future<void> deleteResult(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final parent = file.parent;
      if (parent.path
              .split(Platform.pathSeparator)
              .last
              .startsWith('resinc_job_') &&
          await parent.exists() &&
          await parent.list().isEmpty) {
        await parent.delete();
      }
    } on FileSystemException {
      // Temporary storage can also be reclaimed by the OS.
    }
  }
}
