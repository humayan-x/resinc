import 'dart:math' as math;
import 'dart:typed_data';

/// Separable, scale-aware Lanczos3. Input is premultiplied RGBA; composite
/// onto white before filtering because the destination is an opaque JPEG.
Uint8List resizeLanczos3(
  Uint8List rgba,
  int width,
  int height,
  int outWidth,
  int outHeight,
) {
  if (width < 1 ||
      height < 1 ||
      outWidth < 1 ||
      outHeight < 1 ||
      rgba.length != width * height * 4) {
    throw ArgumentError('Invalid raster dimensions');
  }
  if (width == outWidth && height == outHeight) {
    final output = Uint8List(rgba.length);
    for (var i = 0; i < rgba.length; i += 4) {
      for (var c = 0; c < 3; c++) {
        output[i + c] = (rgba[i + c] + 255 - rgba[i + 3]).clamp(0, 255);
      }
      output[i + 3] = 255;
    }
    return output;
  }
  final horizontal = _weights(width, outWidth);
  final vertical = _weights(height, outHeight);
  final intermediate = Float32List(outWidth * height * 3);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < outWidth; x++) {
      final taps = horizontal[x];
      for (var c = 0; c < 3; c++) {
        double value = 0;
        for (var k = 0; k < taps.$2.length; k++) {
          final p = (y * width + taps.$1 + k) * 4;
          value += (rgba[p + c] + 255 - rgba[p + 3]) * taps.$2[k];
        }
        intermediate[(y * outWidth + x) * 3 + c] = value;
      }
    }
  }
  final output = Uint8List(outWidth * outHeight * 4);
  for (var y = 0; y < outHeight; y++) {
    final taps = vertical[y];
    for (var x = 0; x < outWidth; x++) {
      final p = (y * outWidth + x) * 4;
      for (var c = 0; c < 3; c++) {
        double value = 0;
        for (var k = 0; k < taps.$2.length; k++) {
          value +=
              intermediate[((taps.$1 + k) * outWidth + x) * 3 + c] * taps.$2[k];
        }
        output[p + c] = value.round().clamp(0, 255);
      }
      output[p + 3] = 255;
    }
  }
  return output;
}

List<(int, Float64List)> _weights(int source, int target) {
  final scale = math.max(1.0, source / target);
  return List.generate(target, (i) {
    final center = (i + 0.5) * source / target - 0.5;
    final start = math.max(0, (center - 3 * scale).ceil());
    final end = math.min(source - 1, (center + 3 * scale).floor());
    final weights = Float64List(end - start + 1);
    double sum = 0;
    for (var j = start; j <= end; j++) {
      final x = (j - center) / scale;
      final value = x.abs() < 1e-10
          ? 1.0
          : x.abs() >= 3
          ? 0.0
          : 3 *
                math.sin(math.pi * x) *
                math.sin(math.pi * x / 3) /
                (math.pi * math.pi * x * x);
      weights[j - start] = value;
      sum += value;
    }
    for (var j = 0; j < weights.length; j++) {
      weights[j] /= sum;
    }
    return (start, weights);
  });
}
