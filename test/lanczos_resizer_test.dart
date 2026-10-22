import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/services/lanczos_resizer.dart';

void main() {
  test('constant color survives reduction including borders', () {
    final pixels = Uint8List.fromList(
      List.generate(
        17 * 11,
        (_) => [30, 80, 140, 255],
      ).expand((p) => p).toList(),
    );
    final resized = resizeLanczos3(pixels, 17, 11, 5, 3);
    expect(
      resized,
      List.generate(15, (_) => [30, 80, 140, 255]).expand((p) => p).toList(),
    );
  });
  test('transparent pixels are composited onto white', () {
    expect(resizeLanczos3(Uint8List(16), 2, 2, 1, 1), [255, 255, 255, 255]);
  });
  test('high-frequency checkerboard is antialiased', () {
    final pixels = Uint8List(64 * 64 * 4);
    for (var y = 0; y < 64; y++) {
      for (var x = 0; x < 64; x++) {
        final i = (y * 64 + x) * 4;
        pixels[i] = pixels[i + 1] = pixels[i + 2] = (x + y).isEven ? 0 : 255;
        pixels[i + 3] = 255;
      }
    }
    final output = resizeLanczos3(pixels, 64, 64, 8, 8);
    for (var i = 0; i < output.length; i += 4) {
      expect(output[i], inInclusiveRange(125, 130));
    }
  });
  test('identity resize preserves opaque pixels', () {
    final pixels = Uint8List.fromList([20, 30, 40, 255, 180, 100, 60, 255]);
    expect(resizeLanczos3(pixels, 2, 1, 2, 1), pixels);
  });
}
