import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:resinc/models/image_metadata.dart';
import 'package:resinc/services/crop_service.dart';

Future<Uint8List> raster(int width, int height, {bool detailed = false}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final random = Random(42);
  for (var x = 0; x < width; x++) {
    for (var y = 0; y < height; y++) {
      canvas.drawRect(
        ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
        ui.Paint()
          ..color = ui.Color(
            detailed ? 0xff000000 | random.nextInt(0x1000000) : 0xff0000ff,
          ),
      );
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

class CropEncoder extends UnsupportedFlutterImageCompress {
  bool requireResize = false;
  bool fail = false;
  final widths = <int>[];
  final qualities = <int>[];
  Uint8List? input;

  @override
  Future<Uint8List> compressWithList(
    Uint8List image, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    int inSampleSize = 1,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    expect(format, CompressFormat.jpeg);
    expect(keepExif, isFalse);
    expect(autoCorrectionAngle, isFalse);
    input ??= image;
    expect(image, input); // Every attempt starts from the lossless crop.
    widths.add(minWidth);
    qualities.add(quality);
    if (fail) throw StateError('encoder unavailable');
    // Substitute a decodable raster for native JPEG in unit tests, with
    // controlled byte sizes to exercise quality and dimension selection.
    final png = await raster(minWidth, minHeight);
    final size = requireResize && minWidth == 60 ? 2000 : quality * 20;
    final output = Uint8List(size);
    output.setRange(0, png.length, png);
    return output;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final resize in [false, true]) {
    test('oversized crop fits source budget; resize=$resize', () async {
      final temp = await Directory.systemTemp.createTemp('compact_crop_');
      final previous = FlutterImageCompressPlatform.instance;
      final encoder = CropEncoder()..requireResize = resize;
      FlutterImageCompressPlatform.instance = encoder;
      try {
        final source = await File('${temp.path}/source.png')
            .writeAsBytes(await raster(120, 80, detailed: true));
        final before = await source.readAsBytes();
        final metadata = ImageMetadata(
          path: source.path,
          fileName: 'photo.jpg',
          width: 120,
          height: 80,
          fileSizeBytes: 1000,
          originalSizeBytes: 1000,
          exifTags: const {'Artist': 'Test'},
        );
        final service = CropService(temporaryDirectory: () async => temp);
        final result = await service.crop(
          metadata,
          const ui.Rect.fromLTWH(0, 0, .5, 1),
        );
        expect(encoder.input!.length, greaterThan(1000));
        expect(result.fileSizeBytes, lessThanOrEqualTo(1000));
        expect(result.fileSizeBytes, await File(result.path).length());
        expect(result.path, endsWith('.jpg'));
        expect((result.width, result.height), resize ? (45, 60) : (60, 80));
        expect(result.originalSizeBytes, 1000);
        expect(result.exifTags, metadata.exifTags);
        expect(await source.readAsBytes(), before);
        expect(encoder.qualities, contains(50));
        await CropService.deleteCrop(result.path);
        encoder.fail = true;
        await expectLater(
          service.crop(metadata, const ui.Rect.fromLTWH(0, 0, .5, 1)),
          throwsStateError,
        );
        expect(
          await temp.list().where((entry) => entry is Directory).isEmpty,
          isTrue,
        );
      } finally {
        FlutterImageCompressPlatform.instance = previous;
        await temp.delete(recursive: true);
      }
    });
  }
}
