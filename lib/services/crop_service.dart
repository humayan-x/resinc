import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import '../models/crop_selection.dart';
import '../models/image_metadata.dart';

class CropService {
  final Future<Directory> Function() temporaryDirectory;
  CropService({Future<Directory> Function()? temporaryDirectory})
    : temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  /// Lossless crop of the original decoded pixels. Never modifies the source.
  Future<ImageMetadata> crop(ImageMetadata original, ui.Rect selection) async {
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
            final file = File('${job.path}/crop.png');
            await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
            return ImageMetadata(
              path: file.path,
              fileName: original.fileName,
              width: width,
              height: height,
              fileSizeBytes: await file.length(),
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
