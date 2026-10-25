import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'compression_service.dart';
import 'native_image_processor.dart';

import 'package:path_provider/path_provider.dart';

import '../models/crop_selection.dart';
import '../models/image_metadata.dart';

class CropService {
  final Future<Directory> Function() temporaryDirectory;
  final NativeImageProcessor? _native;
  CropService({
    Future<Directory> Function()? temporaryDirectory,
    NativeImageProcessor? nativeProcessor,
  }) : temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _native =
           nativeProcessor ??
           (Platform.isAndroid ? NativeImageProcessor() : null);

  /// Crop from original pixels, retaining PNG only when it fits the source
  /// size. Otherwise use JPEG with a verified size ceiling. Never alter source.
  Future<ImageMetadata> crop(ImageMetadata original, ui.Rect selection) async {
    if (_native != null) {
      CropSelection.pixelBounds(selection, original.width, original.height);
      final job = await (await temporaryDirectory()).createTemp('resinc_crop_');
      try {
        final output = '${job.path}/crop.jpg';
        final result = await _native.process(
          source: original.path,
          output: output,
          crop: selection,
          budget: original.fileSizeBytes,
          quality: 85,
        );
        return ImageMetadata(
          path: output,
          fileName: original.fileName,
          width: result.width,
          height: result.height,
          fileSizeBytes: result.bytes,
          originalSizeBytes: original.originalSizeBytes,
          exifTags: original.exifTags,
          hasGps: original.hasGps,
          latitude: original.latitude,
          longitude: original.longitude,
        );
      } catch (_) {
        if (await job.exists()) await job.delete(recursive: true);
        rethrow;
      }
    }
    final buffer = await ui.ImmutableBuffer.fromFilePath(original.path);
    final codec = await ui.instantiateImageCodecFromBuffer(buffer);
    Directory? job;
    try {
      final frame = await codec.getNextFrame();
      try {
        final bounds = CropSelection.pixelBounds(
          selection,
          frame.image.width,
          frame.image.height,
        );
        final width = bounds.width.toInt();
        final height = bounds.height.toInt();
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawImageRect(
          frame.image,
          bounds,
          ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          ui.Paint()..filterQuality = ui.FilterQuality.none,
        );
        final picture = recorder.endRecording();
        try {
          final cropped = await picture.toImage(width, height);
          try {
            final bytes = await cropped.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (bytes == null) {
              throw StateError('Could not create cropped image.');
            }
            job = await (await temporaryDirectory()).createTemp('resinc_crop_');
            final png = bytes.buffer.asUint8List();
            final budget = original.fileSizeBytes;
            Uint8List output = png;
            var extension = 'png';
            var outputWidth = width;
            var outputHeight = height;
            if (png.length > budget) {
              output = await _compactCrop(png, width, height, budget);
              extension = 'jpg';
            }
            final file = File('${job.path}/crop.$extension');
            await file.writeAsBytes(output, flush: true);
            if (extension == 'jpg') {
              final dimensions = await CompressionService.readDimensions(
                file.path,
              );
              outputWidth = dimensions.$1;
              outputHeight = dimensions.$2;
            }
            return ImageMetadata(
              path: file.path,
              fileName: original.fileName,
              width: outputWidth,
              height: outputHeight,
              fileSizeBytes: await file.length(),
              originalSizeBytes: original.originalSizeBytes,
              exifTags: original.exifTags,
              hasGps: original.hasGps,
              latitude: original.latitude,
              longitude: original.longitude,
            );
          } finally {
            cropped.dispose();
          }
        } finally {
          picture.dispose();
        }
      } finally {
        frame.image.dispose();
      }
    } catch (_) {
      if (job != null && await job.exists()) await job.delete(recursive: true);
      rethrow;
    } finally {
      codec.dispose();
    }
  }

  Future<Uint8List> _compactCrop(
    Uint8List png,
    int width,
    int height,
    int budget,
  ) async {
    var outWidth = width;
    var outHeight = height;
    var scale = 1.0;
    for (var pass = 0; pass < 16; pass++) {
      Uint8List? winner;
      var low = 45;
      var high = 90;
      while (low <= high) {
        final quality = (low + high) ~/ 2;
        // Always encode the same lossless crop, avoiding repeated JPEG loss.
        final candidate = await FlutterImageCompress.compressWithList(
          png,
          minWidth: outWidth,
          minHeight: outHeight,
          quality: quality,
          format: CompressFormat.jpeg,
          keepExif: false,
          autoCorrectionAngle: false,
        );
        if (candidate.isEmpty) {
          throw StateError('Could not encode cropped image.');
        }
        if (candidate.length <= budget) {
          winner = candidate;
          low = quality + 1;
        } else {
          high = quality - 1;
        }
      }
      if (winner != null) return winner;
      if (outWidth == 1 && outHeight == 1) break;
      scale *= .75;
      outWidth = math.max(1, (width * scale).floor());
      outHeight = math.max(1, (height * scale).floor());
    }
    throw StateError('Could not crop within the original file size.');
  }

  static Future<void> deleteCrop(String path) async {
    final parent = File(path).parent;
    if (!parent.path
        .split(Platform.pathSeparator)
        .last
        .startsWith('resinc_crop_')) {
      return;
    }
    try {
      if (await parent.exists()) await parent.delete(recursive: true);
    } on FileSystemException {
      // The OS may already have reclaimed temporary storage.
    }
  }
}
