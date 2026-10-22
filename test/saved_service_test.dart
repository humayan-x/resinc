import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

    test('loadSavedItems purges reference when photo was deleted from gallery', () async {
      final savedSubdir = Directory('${tempDir.path}/optimized');
      await savedSubdir.create(recursive: true);

      // Create two fake saved files with .meta sidecars
      final file1 = File('${savedSubdir.path}/resinc_1_100kb.jpg');
      final meta1 = File('${savedSubdir.path}/resinc_1_100kb.jpg.meta');
      await file1.writeAsBytes([1, 2, 3, 4]);
      await meta1.writeAsString(jsonEncode({
        'id': '1',
        'filePath': file1.path,
        'fileName': 'resinc_1_100kb.jpg',
        'fileSizeBytes': 100000,
        'originalSizeBytes': 500000,
        'createdAt': DateTime.now().toIso8601String(),
        'width': 1080,
        'height': 1080,
      }));

      final file2 = File('${savedSubdir.path}/resinc_2_200kb.jpg');
      final meta2 = File('${savedSubdir.path}/resinc_2_200kb.jpg.meta');
      await file2.writeAsBytes([5, 6, 7, 8]);
      await meta2.writeAsString(jsonEncode({
        'id': '2',
        'filePath': file2.path,
        'fileName': 'resinc_2_200kb.jpg',
        'fileSizeBytes': 200000,
        'originalSizeBytes': 800000,
        'createdAt': DateTime.now().toIso8601String(),
        'width': 1080,
        'height': 1080,
      }));

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
    });

    test('loadSavedItems purges all references when all photos deleted from gallery', () async {
      final savedSubdir = Directory('${tempDir.path}/optimized');
      await savedSubdir.create(recursive: true);

      final file1 = File('${savedSubdir.path}/resinc_deleted_100kb.jpg');
      final meta1 = File('${savedSubdir.path}/resinc_deleted_100kb.jpg.meta');
      await file1.writeAsBytes([1, 2, 3]);
      await meta1.writeAsString(jsonEncode({
        'id': 'deleted',
        'filePath': file1.path,
        'fileName': 'resinc_deleted_100kb.jpg',
        'fileSizeBytes': 100000,
        'originalSizeBytes': 200000,
        'createdAt': DateTime.now().toIso8601String(),
        'width': 1080,
        'height': 1080,
      }));

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
