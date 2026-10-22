import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:native_exif/native_exif.dart';

import 'lanczos_resizer.dart';

/// One decoded original per job; one lossless resized raster per resolution.
class LanczosEncoder {
  final Uint8List pixels;
  final int width;
  final int height;
  final Directory job;
  final Map<String, Object> exif;
  String? _resizedPath;
  (int, int)? _size;

  LanczosEncoder._(this.pixels, this.width, this.height, this.job, this.exif);

  static Future<LanczosEncoder> open(
    String path,
    Directory job,
    Map<String, Object> exif,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    // This call takes ownership of the encoded buffer.
    final codec = await ui.instantiateImageCodecFromBuffer(buffer);
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (data == null) throw StateError('Cannot decode image pixels.');
        return LanczosEncoder._(
          data.buffer.asUint8List(),
          frame.image.width,
          frame.image.height,
          job,
          exif,
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Future<String?> encode(
    String source,
    String target,
    int quality,
    int outWidth,
    int outHeight,
    bool keepExif,
  ) async {
    if (_size != (outWidth, outHeight)) {
      final original = pixels;
      final w = width;
      final h = height;
      final resized = await Isolate.run(
        () => resizeLanczos3(original, w, h, outWidth, outHeight),
      );
      final buffer = await ui.ImmutableBuffer.fromUint8List(resized);
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: outWidth,
        height: outHeight,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      try {
        final codec = await descriptor.instantiateCodec();
        try {
          final frame = await codec.getNextFrame();
          try {
            final png = await frame.image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (png == null) throw StateError('Cannot prepare resized image.');
            _resizedPath = '${job.path}/resized.png';
            await File(_resizedPath!)
                .writeAsBytes(png.buffer.asUint8List(), flush: true);
            _size = (outWidth, outHeight);
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
        buffer.dispose();
      }
    }
    final output = await FlutterImageCompress.compressAndGetFile(
      _resizedPath!,
      target,
      quality: quality.clamp(0, 100),
      minWidth: outWidth,
      minHeight: outHeight,
      keepExif: false,
      autoCorrectionAngle: false,
      format: CompressFormat.jpeg,
    );
    if (output == null) return null;
    if (keepExif && exif.isNotEmpty) {
      final attributes = Map<String, Object>.from(exif)
        ..removeWhere((key, _) => key.toLowerCase().contains('thumbnail'))
        ..addAll({
          'Orientation': '1',
          'ImageWidth': '$outWidth',
          'ImageLength': '$outHeight',
          'PixelXDimension': '$outWidth',
          'PixelYDimension': '$outHeight',
        });
      final destination = await Exif.fromPath(output.path);
      try {
        await destination.writeAttributes(attributes);
      } finally {
        await destination.close();
      }
    }
    // The caller measures only after all metadata has been written.
    return output.path;
  }
}
