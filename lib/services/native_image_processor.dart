import 'dart:io';

import 'package:flutter/services.dart';

/// Android owns the bitmap for the complete job on a background task queue.
/// Only paths/settings and result metrics cross the platform channel.
class NativeImageProcessor {
  static const channel = MethodChannel('io.github.humayanx.resinc/images');

  Future<NativeImageResult> process({
    required String source,
    required String output,
    int? budget,
    int? maxDimension,
    int quality = 85,
    Rect? crop,
    bool keepExif = false,
    Map<String, Object> exif = const {},
  }) async {
    final result = await channel.invokeMapMethod<String, dynamic>('process', {
      'source': source,
      'output': output,
      'budget': budget,
      'maxDimension': maxDimension,
      'quality': quality,
      'crop': crop == null
          ? null
          : [crop.left, crop.top, crop.right, crop.bottom],
      'keepExif': keepExif,
      'exif': exif,
    });
    if (result == null) throw StateError('No image processing result.');
    final size = await File(output).length();
    final width = result['width'] as int;
    final height = result['height'] as int;
    if (size <= 0 ||
        size != result['bytes'] ||
        (budget != null && size > budget) ||
        width < 1 ||
        height < 1) {
      throw StateError('Invalid image processing result.');
    }
    return NativeImageResult(width, height, size, result['attempts'] as int);
  }
}

class NativeImageResult {
  final int width;
  final int height;
  final int bytes;
  final int attempts;
  const NativeImageResult(this.width, this.height, this.bytes, this.attempts);
}
