import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resinc/models/crop_selection.dart';
import 'package:resinc/models/image_metadata.dart';
import 'package:resinc/services/exif_service.dart';
import 'package:resinc/state/workbench_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WorkbenchController create(_Picker picker, [_Inspector? inspector]) {
    final controller = WorkbenchController(
      picker: picker,
      exifService: inspector ?? _Inspector(),
      recoverLostSelection: true,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test(
    'startup recovers once, inspects photo and prevents concurrent picking',
    () async {
      final picker = _Picker();
      final inspector = _Inspector();
      final controller = create(picker, inspector);
      expect(controller.isInspecting, isTrue);
      await controller.pickImage();
      expect(picker.picks, 0);
      picker.recovery.complete(
        LostDataResponse(files: [XFile('/recovered.jpg')]),
      );
      await controller.recoverLostImage();
      expect(inspector.paths, ['/recovered.jpg']);
      expect(controller.originalImage, same(controller.selectedImage));
      expect(controller.selectedImage!.path, '/recovered.jpg');
      expect(controller.cropSelection, CropSelection.full);
      expect(controller.hasResult, isFalse);
      expect(controller.isSavedToGallery, isFalse);
      expect(controller.isBusy, isFalse);
      expect(controller.errorMessage, isNull);
      await controller.pickImage();
      await controller.recoverLostImage();
      expect(picker.recoveries, 1);
      expect(controller.selectedImage!.path, '/new.jpg');
    },
  );

  test('empty recovery leaves the picker ready without an error', () async {
    final picker = _Picker();
    final controller = create(picker);
    picker.recovery.complete(LostDataResponse.empty());
    await controller.recoverLostImage();
    expect(controller.hasImage, isFalse);
    expect(controller.isBusy, isFalse);
    expect(controller.errorMessage, isNull);
    await controller.pickImage();
    expect(controller.hasImage, isTrue);
  });

  for (final failure in ['response', 'channel', 'inspection']) {
    test(
      '$failure failure shows recovery guidance and allows another pick',
      () async {
        final picker = _Picker();
        final inspector = _Inspector()..fail = failure == 'inspection';
        final controller = create(picker, inspector);
        if (failure == 'channel') {
          picker.recovery.completeError(
            PlatformException(code: 'picker_failed'),
          );
        } else if (failure == 'response') {
          picker.recovery.complete(
            LostDataResponse(
              exception: PlatformException(code: 'picker_failed'),
            ),
          );
        } else {
          picker.recovery.complete(
            LostDataResponse(files: [XFile('/missing.jpg')]),
          );
        }
        await controller.recoverLostImage();
        expect(controller.hasImage, isFalse);
        expect(controller.isBusy, isFalse);
        expect(controller.errorMessage, contains('Please select it again'));
        inspector.fail = false;
        await controller.pickImage();
        expect(controller.selectedImage!.path, '/new.jpg');
        expect(controller.errorMessage, isNull);
      },
    );
  }

  test('disposed controller ignores a late recovery', () async {
    final picker = _Picker();
    final inspector = _Inspector();
    final controller = WorkbenchController(
      picker: picker,
      exifService: inspector,
      recoverLostSelection: true,
    );
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.dispose();
    picker.recovery.complete(
      LostDataResponse(files: [XFile('/recovered.jpg')]),
    );
    await controller.recoverLostImage();
    expect(inspector.paths, isEmpty);
    expect(controller.hasImage, isFalse);
    expect(notifications, 0);
  });
}

class _Picker extends ImagePicker {
  final recovery = Completer<LostDataResponse>();
  int recoveries = 0;
  int picks = 0;

  @override
  Future<LostDataResponse> retrieveLostData() {
    recoveries++;
    return recovery.future;
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    picks++;
    return XFile('/new.jpg');
  }
}

class _Inspector extends ExifService {
  final paths = <String>[];
  bool fail = false;
  @override
  Future<ImageMetadata> inspectImage(String path) async {
    paths.add(path);
    if (fail) throw const FileSystemException('Missing recovered file');
    return ImageMetadata(
      path: path,
      fileName: path.split('/').last,
      width: 100,
      height: 80,
      fileSizeBytes: 1000,
      exifTags: {},
    );
  }
}
