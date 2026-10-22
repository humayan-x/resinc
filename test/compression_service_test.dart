import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/models/compression_options.dart';
import 'package:resinc/models/image_metadata.dart';
import 'package:resinc/services/compression_service.dart';

void main() {
  late Directory temp;
  const metadata = ImageMetadata(
    path: 'source',
    fileName: 'source.jpg',
    width: 4000,
    height: 3000,
    fileSizeBytes: 4000000,
    exifTags: {},
  );
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('resinc_test_');
  });
  tearDown(() async {
    await temp.delete(recursive: true);
  });

  test('custom targets can be cleared and invalid values are rejected', () {
    const options = CompressionOptions(
      preset: CompressionPreset.customKB,
      customTargetKB: 150,
    );
    expect(options.copyWith().customTargetKB, 150);
    expect(options.copyWith(customTargetKB: null).isValid, false);
    expect(options.copyWith(customTargetKB: 0).isValid, false);
    expect(options.copyWith(customTargetKB: -1).isValid, false);
    expect(options.copyWith(customTargetKB: 49).isValid, false);
    expect(options.copyWith(customTargetKB: 50).isValid, true);
  });

  for (final preset in [
    CompressionPreset.max100KB,
    CompressionPreset.max200KB,
    CompressionPreset.max500KB,
    CompressionPreset.customKB,
  ]) {
    test(
      '$preset retries dimensions and returns a verified candidate',
      () async {
        final widths = <int>[];
        final service = CompressionService(
          temporaryDirectory: () async => temp,
          dimensions: (_) async => (4000, 3000),
          encoder: (source, target, quality, width, height, keepExif) async {
            expect(source, 'source');
            widths.add(width);
            await File(target)
                .writeAsBytes(List.filled(width * quality * 10, 0));
            return target;
          },
        );
        final options = CompressionOptions(preset: preset, customTargetKB: 50);
        final result = await service.compressImage(
          metadata: metadata,
          options: options,
        );
        expect(
          result.compressedSizeBytes,
          lessThanOrEqualTo(options.effectiveTargetBytes!),
        );
        expect(
          await File(result.compressedPath).length(),
          result.compressedSizeBytes,
        );
        if (preset != CompressionPreset.max500KB &&
            preset != CompressionPreset.max200KB) {
          expect(widths.toSet().length, greaterThan(1));
        }
        final files = await temp
            .list(recursive: true)
            .where((e) => e is File)
            .toList();
        expect(files.length, 1);
        await CompressionService.deleteResult(result.compressedPath);
        expect(await temp.list().isEmpty, true);
      },
    );
  }

  test('200 KB rejects 201000 bytes and keeps decimal headroom', () async {
    final service = CompressionService(
      temporaryDirectory: () async => temp,
      dimensions: (_) async => (100, 100),
      encoder: (_, path, quality, width, height, keepExif) async {
        final size = quality > 60 ? 201000 : 198000;
        await File(path).writeAsBytes(List.filled(size, 0));
        return path;
      },
    );
    final result = await service.compressImage(
      metadata: metadata,
      options: const CompressionOptions(),
    );
    expect(result.compressedSizeBytes, 198000);
    expect(await File(result.compressedPath).length(), lessThan(200000));
  });

  test('impossible ceiling fails and removes every attempt', () async {
    final service = CompressionService(
      temporaryDirectory: () async => temp,
      dimensions: (_) async => (20, 10),
      encoder: (_, target, quality, width, height, keepExif) async {
        await File(target).writeAsBytes(List.filled(60000, 0));
        return target;
      },
    );
    await expectLater(
      service.compressImage(
        metadata: metadata,
        options: const CompressionOptions(
          preset: CompressionPreset.customKB,
          customTargetKB: 50,
        ),
      ),
      throwsStateError,
    );
    expect(await temp.list().isEmpty, true);
  });

  test('invalid target is rejected before encoding', () async {
    final service = CompressionService(
      temporaryDirectory: () async => temp,
      encoder: (_, _, _, _, _, _) async => fail('Must not encode'),
    );
    await expectLater(
      service.compressImage(
        metadata: metadata,
        options: const CompressionOptions(
          preset: CompressionPreset.customKB,
          customTargetKB: 49,
        ),
      ),
      throwsArgumentError,
    );
    expect(await temp.list().isEmpty, true);
  });

  test('export rejects a result that grew after compression', () async {
    final service = CompressionService(
      temporaryDirectory: () async => temp,
      dimensions: (_) async => (10, 10),
      encoder: (_, path, _, _, _, _) async {
        await File(path).writeAsBytes(List.filled(49000, 0));
        return path;
      },
    );
    final result = await service.compressImage(
      metadata: metadata,
      options: const CompressionOptions(
        preset: CompressionPreset.customKB,
        customTargetKB: 50,
      ),
    );
    await result.verifyFile();
    await File(result.compressedPath).writeAsBytes(List.filled(50001, 0));
    await expectLater(result.verifyFile(), throwsStateError);
  });

  test('encoder failure cleans its partial output', () async {
    final service = CompressionService(
      temporaryDirectory: () async => temp,
      dimensions: (_) async => (20, 10),
      encoder: (_, target, quality, width, height, keepExif) async {
        await File(target).writeAsBytes([1]);
        throw StateError('Encoder failed');
      },
    );
    await expectLater(
      service.compressImage(
        metadata: metadata,
        options: const CompressionOptions(),
      ),
      throwsStateError,
    );
    expect(await temp.list().isEmpty, true);
  });
}
