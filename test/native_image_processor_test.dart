import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/models/compression_options.dart';
import 'package:resinc/models/image_metadata.dart';
import 'package:resinc/services/compression_service.dart';
import 'package:resinc/services/crop_service.dart';
import 'package:resinc/services/native_image_processor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late Map<dynamic, dynamic> request;
  late int calls;
  var oversize = false;
  const metadata = ImageMetadata(
    path: 'photo.jpg',
    fileName: 'photo.jpg',
    width: 4000,
    height: 3000,
    fileSizeBytes: 500000,
    originalSizeBytes: 1000000,
    exifTags: {'Artist': 'Test'},
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('native_bridge_');
    calls = 0;
    oversize = false;
    messenger.setMockMethodCallHandler(NativeImageProcessor.channel, (
      call,
    ) async {
      expect(call.method, 'process');
      calls++;
      request = call.arguments as Map;
      final bytes = oversize ? (request['budget'] as int) + 1 : 1000;
      await File(request['output'] as String)
          .writeAsBytes(List.filled(bytes, 0));
      return {'width': 800, 'height': 600, 'bytes': bytes, 'attempts': 1};
    });
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(NativeImageProcessor.channel, null);
    await temp.delete(recursive: true);
  });

  test(
    'optimization sends one native job with ceiling and metadata policy',
    () async {
      final service = CompressionService(
        nativeProcessor: NativeImageProcessor(),
        temporaryDirectory: () async => temp,
      );
      final result = await service.compressImage(
        metadata: metadata,
        options: const CompressionOptions(stripExif: false),
      );
      expect(calls, 1);
      expect(request['source'], 'photo.jpg');
      expect(request['budget'], 198000);
      expect(request['keepExif'], isTrue);
      expect(request['exif'], {'Artist': 'Test'});
      expect(result.originalSizeBytes, 1000000);
      expect(result.iterationsCount, 1);
      expect(result.outputWidth, 800);
      await result.verifyFile();
    },
  );

  test(
    'crop sends normalized bounds and preserves original comparison',
    () async {
      final service = CropService(
        nativeProcessor: NativeImageProcessor(),
        temporaryDirectory: () async => temp,
      );
      final result = await service.crop(
        metadata,
        const Rect.fromLTWH(.1, .2, .5, .5),
      );
      expect(calls, 1);
      expect(request['crop'], [.1, .2, .6, .7]);
      expect(request['budget'], 500000);
      expect(request['keepExif'], isFalse);
      expect(result.originalSizeBytes, 1000000);
      expect(result.exifTags, metadata.exifTags);
      expect(result.fileSizeBytes, 1000);
    },
  );

  test('oversized native results fail and remove temporary jobs', () async {
    oversize = true;
    await expectLater(
      CompressionService(
        nativeProcessor: NativeImageProcessor(),
        temporaryDirectory: () async => temp,
      ).compressImage(metadata: metadata, options: const CompressionOptions()),
      throwsStateError,
    );
    await expectLater(
      CropService(
        nativeProcessor: NativeImageProcessor(),
        temporaryDirectory: () async => temp,
      ).crop(metadata, const Rect.fromLTWH(0, 0, .5, .5)),
      throwsStateError,
    );
    expect(await temp.list().isEmpty, isTrue);
  });
}
