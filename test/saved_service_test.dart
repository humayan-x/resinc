import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:resinc/services/saved_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SavedService tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('resinc_saved_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('failed gallery check preserves files, metadata and visible history; retry reconciles', () async {
      final savedDir = await Directory('${tempDir.path}/optimized').create();
      final originals = <String, List<int>>{};
      for (var i = 1; i <= 2; i++) {
        final file = File('${savedDir.path}/resinc_$i.jpg');
        await file.writeAsBytes([i, 2, 3]);
        final meta = File('${file.path}.meta');
        await meta.writeAsString(
          jsonEncode({
            'id': '$i',
            'fileName': 'resinc_$i.jpg',
            'originalSizeBytes': 100000,
            'fileSizeBytes': 3,
            'createdAt': DateTime(2026, 1, i).toIso8601String(),
          }),
        );
        originals[file.path] = await file.readAsBytes();
        originals[meta.path] = await meta.readAsBytes();
      }
      var fail = true;
      final service = SavedService(
        directoryProvider: () async => tempDir,
        galleryChecker: (_) async {
          if (fail) {
            throw PlatformException(code: 'gallery_check_failed');
          }
          return ['resinc_2.jpg'];
        },
      );

      for (var attempt = 0; attempt < 2; attempt++) {
        final items = await service.loadSavedItems();
        expect(items.map((item) => item.id), ['2', '1']);
        for (final entry in originals.entries) {
          expect(await File(entry.key).readAsBytes(), entry.value);
        }
      }

      fail = false;
      final items = await service.loadSavedItems();
      expect(items.map((item) => item.id), ['2']);
      expect(await File('${savedDir.path}/resinc_1.jpg').exists(), isFalse);
      expect(
        await File('${savedDir.path}/resinc_1.jpg.meta').exists(),
        isFalse,
      );
      expect(await File('${savedDir.path}/resinc_2.jpg').exists(), isTrue);
      expect(await File('${savedDir.path}/resinc_2.jpg.meta').exists(), isTrue);
    });

    test(
      'loadSavedItems purges reference when photo was deleted from gallery',
      () async {
        final savedSubdir = Directory('${tempDir.path}/optimized');
        await savedSubdir.create(recursive: true);

        // Create two fake saved files with .meta sidecars
        final file1 = File('${savedSubdir.path}/resinc_1_100kb.jpg');
        final meta1 = File('${savedSubdir.path}/resinc_1_100kb.jpg.meta');
        await file1.writeAsBytes([1, 2, 3, 4]);
        await meta1.writeAsString(
          jsonEncode({
            'id': '1',
            'filePath': file1.path,
            'fileName': 'resinc_1_100kb.jpg',
            'fileSizeBytes': 100000,
            'originalSizeBytes': 500000,
            'createdAt': DateTime.now().toIso8601String(),
            'width': 1080,
            'height': 1080,
          }),
        );

        final file2 = File('${savedSubdir.path}/resinc_2_200kb.jpg');
        final meta2 = File('${savedSubdir.path}/resinc_2_200kb.jpg.meta');
        await file2.writeAsBytes([5, 6, 7, 8]);
        await meta2.writeAsString(
          jsonEncode({
            'id': '2',
            'filePath': file2.path,
            'fileName': 'resinc_2_200kb.jpg',
            'fileSizeBytes': 200000,
            'originalSizeBytes': 800000,
            'createdAt': DateTime.now().toIso8601String(),
            'width': 1080,
            'height': 1080,
          }),
        );

        // Simulate that file 1 was deleted from Gallery by user, but file 2 remains
        final service = SavedService(
          directoryProvider: () async => tempDir,
          galleryChecker: (names) async => ['resinc_2_200kb.jpg'],
        );

        final items = await service.loadSavedItems();

        expect(items.length, 1);
        expect(items.first.fileName, 'resinc_2_200kb.jpg');

        // Verify that file1 and its meta were automatically deleted from disk
        expect(await file1.exists(), isFalse);
        expect(await meta1.exists(), isFalse);

        // Verify file2 still exists
        expect(await file2.exists(), isTrue);
        expect(await meta2.exists(), isTrue);
      },
    );

    test('loadSavedItems purges all references when all photos deleted from gallery', () async {
      final savedSubdir = Directory('${tempDir.path}/optimized');
      await savedSubdir.create(recursive: true);

      final file1 = File('${savedSubdir.path}/resinc_deleted_100kb.jpg');
      final meta1 = File('${savedSubdir.path}/resinc_deleted_100kb.jpg.meta');
      await file1.writeAsBytes([1, 2, 3]);
      await meta1.writeAsString(
        jsonEncode({
          'id': 'deleted',
          'filePath': file1.path,
          'fileName': 'resinc_deleted_100kb.jpg',
          'fileSizeBytes': 100000,
          'originalSizeBytes': 200000,
          'createdAt': DateTime.now().toIso8601String(),
          'width': 1080,
          'height': 1080,
        }),
      );

      final service = SavedService(
        directoryProvider: () async => tempDir,
        galleryChecker: (names) async => [],
      );

      final items = await service.loadSavedItems();

      expect(items.isEmpty, isTrue);
      expect(await file1.exists(), isFalse);
      expect(await meta1.exists(), isFalse);
    });
  });
}
