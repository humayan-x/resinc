import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:resinc/services/compression_service.dart';
import 'package:resinc/services/lanczos_encoder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('decode budgets preserve proportions without upscaling', () {
    for (final size in [(8000, 6000), (6000, 8000), (12000, 1000)]) {
      final decoded = LanczosEncoder.decodeSize(size.$1, size.$2);
      expect(decoded.width! * decoded.height!, lessThanOrEqualTo(4000000));
      expect(decoded.width, lessThanOrEqualTo(2560));
      expect(decoded.height, lessThanOrEqualTo(2560));
      expect(
        decoded.width! / decoded.height!,
        closeTo(size.$1 / size.$2, 0.02),
      );
    }
    final small = LanczosEncoder.decodeSize(320, 240, maxDimension: 1920);
    expect((small.width, small.height), (320, 240));
    final portrait = LanczosEncoder.decodeSize(3000, 4000, maxDimension: 1280);
    expect((portrait.width, portrait.height), (960, 1280));
  });

  test('decoder produces bounded pixels before encoding', () async {
    final temp = await Directory.systemTemp.createTemp('decode_budget_');
    try {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
          .drawColor(const ui.Color(0xff205080), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(3200, 2400);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      final source = File('${temp.path}/source.png');
      await source.writeAsBytes(png!.buffer.asUint8List());
      final preset = await LanczosEncoder.open(
        source.path,
        temp,
        {},
        maxDimension: 1920,
      );
      expect((preset.width, preset.height), (1920, 1440));
      expect(preset.pixels.length, 1920 * 1440 * 4);
      final kb = await LanczosEncoder.open(source.path, temp, {});
      expect(kb.width * kb.height, lessThanOrEqualTo(4000000));
      expect(kb.pixels.length, kb.width * kb.height * 4);
    } finally {
      await temp.delete(recursive: true);
    }
  });

  test(
    'decoded raster is resized once per level and metadata precedes return',
    () async {
      final temp = await Directory.systemTemp.createTemp('lanczos_test_');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final previous = FlutterImageCompressPlatform.instance;
      FlutterImageCompressPlatform.instance = _TestEncoder();
      var writes = 0;
      messenger.setMockMethodCallHandler(const MethodChannel('native_exif'), (
        call,
      ) async {
        if (call.method == 'initPath') return 1;
        if (call.method == 'setAttributes') {
          final values = (call.arguments as Map)['values'] as Map;
          expect(values['Orientation'], '1');
          expect(values['ImageWidth'], '8');
          expect(values['Artist'], 'Test');
          writes++;
        }
        return null;
      });
      try {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder)
            .drawColor(const ui.Color(0xff205080), ui.BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(32, 16);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        final source = '${temp.path}/source.png';
        await File(source).writeAsBytes(png!.buffer.asUint8List());
        final encoder = await LanczosEncoder.open(source, temp, {
          'Artist': 'Test',
        });
        expect((encoder.width, encoder.height), (32, 16));
        await encoder.encode(source, '${temp.path}/one.jpg', 80, 8, 4, true);
        final modified = await File('${temp.path}/resized.png').lastModified();
        await encoder.encode(source, '${temp.path}/two.jpg', 60, 8, 4, false);
        expect(await File('${temp.path}/resized.png').lastModified(), modified);
        expect(writes, 1);
      } finally {
        messenger.setMockMethodCallHandler(
          const MethodChannel('flutter_image_compress'),
          null,
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('native_exif'),
          null,
        );
        FlutterImageCompressPlatform.instance = previous;
        await temp.delete(recursive: true);
      }
    },
  );
}

class _TestEncoder extends UnsupportedFlutterImageCompress {
  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    expect(await CompressionService.readDimensions(path), (8, 4));
    expect((minWidth, minHeight), (8, 4));
    expect(autoCorrectionAngle, false);
    expect(keepExif, false);
    await File(path).copy(targetPath);
    return XFile(targetPath);
  }
}
