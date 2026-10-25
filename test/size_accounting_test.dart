import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/models/compression_options.dart';
import 'package:resinc/models/image_metadata.dart';
import 'package:resinc/services/compression_service.dart';
import 'package:resinc/services/saved_service.dart';
import 'package:resinc/state/saved_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'crop comparison uses original bytes through compression, save and reload',
    () async {
      final temp = await Directory.systemTemp.createTemp('size_accounting_');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(const MethodChannel('gal'), (
        call,
      ) async {
        if (call.method == 'requestAccess') return true;
        expect(call.method, 'putImage');
        return null;
      });
      final saved = SavedService(
        directoryProvider: () async => temp,
        galleryChecker: (names) async => names,
      );
      final controller = SavedController(savedService: saved);
      try {
        const crop = ImageMetadata(
          path: 'crop.png',
          fileName: 'photo.jpg',
          width: 100,
          height: 100,
          fileSizeBytes: 4000000,
          originalSizeBytes: 200000,
          exifTags: {},
        );
        final compression = CompressionService(
          temporaryDirectory: () async => temp,
          dimensions: (_) async => (100, 100),
          encoder: (source, target, quality, width, height, keepExif) async {
            expect(source, 'crop.png');
            await File(target).writeAsBytes(List.filled(100000, 0));
            return target;
          },
        );
        final result = await compression.compressImage(
          metadata: crop,
          options: const CompressionOptions(),
        );
        expect(result.originalSizeBytes, 200000);
        expect(result.bytesSaved, 100000);
        expect(result.reductionPercentage, 50);
        final item = await saved.saveToGallery(result);
        expect(item.originalSizeBytes, 200000);
        await controller.loadSaved();
        expect(controller.items.single.originalSizeBytes, 200000);
        expect(controller.items.single.reductionPercentage, 50);
        expect(controller.totalSavedBytes, 100000);
        expect(controller.localPhotoBytes, 100000);
        // Disk usage comes from the local file, not stale sidecar metadata.
        await File(item.filePath).writeAsBytes(List.filled(120000, 0));
        await controller.loadSaved();
        expect(controller.localPhotoBytes, 120000);
        expect(controller.totalSavedBytes, 80000);
        await controller.deleteItem(controller.items.single);
        expect(controller.localPhotoBytes, 0);
      } finally {
        controller.dispose();
        messenger.setMockMethodCallHandler(const MethodChannel('gal'), null);
        await temp.delete(recursive: true);
      }
    },
  );
}
