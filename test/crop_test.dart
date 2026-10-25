import 'dart:io';
import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:resinc/state/workbench_controller.dart';
import 'package:resinc/services/exif_service.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/models/crop_selection.dart';
import 'package:resinc/models/image_metadata.dart';
import 'package:resinc/services/crop_service.dart';
import 'package:resinc/screens/workbench/widgets/crop_image_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late ImageMetadata source;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('crop_test_');
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 40, 20),
      Paint()..color = Colors.red,
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, 0, 20, 20),
      Paint()..color = Colors.blue,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(40, 20);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    final file = await File('${temp.path}/original.png')
        .writeAsBytes(png!.buffer.asUint8List());
    source = ImageMetadata(
      path: file.path,
      fileName: 'original.png',
      width: 40,
      height: 20,
      fileSizeBytes: await file.length(),
      exifTags: const {'Artist': 'Test'},
    );
  });
  tearDown(() async => temp.delete(recursive: true));

  test('ratios and corner resizing stay bounded', () {
    for (final imageRatio in [0.2, 0.75, 1.0, 2.0, 5.0]) {
      for (final ratio in [0.5625, 0.75, 1.0, 4 / 3, 16 / 9]) {
        final rect = CropSelection.forRatio(imageRatio, ratio);
        expect(rect.width / rect.height * imageRatio, closeTo(ratio, 1e-8));
        for (var corner = 0; corner < 4; corner++) {
          for (final point in [
            const Offset(-1, -1),
            const Offset(2, 2),
            const Offset(0.5, 0.5),
          ]) {
            final resized = CropSelection.resize(
              rect,
              corner,
              point,
              ratio / imageRatio,
            );
            expect(resized.left, greaterThanOrEqualTo(-1e-10));
            expect(resized.top, greaterThanOrEqualTo(-1e-10));
            expect(resized.right, lessThanOrEqualTo(1.0000000001));
            expect(resized.bottom, lessThanOrEqualTo(1.0000000001));
            expect(
              resized.width / resized.height * imageRatio,
              closeTo(ratio, 1e-8),
            );
          }
        }
      }
    }
  });
  test('move clamps to image and invalid crops are rejected', () {
    expect(
      CropSelection.move(
        const Rect.fromLTWH(.2, .2, .5, .5),
        const Offset(2, -2),
      ),
      rectMoreOrLessEquals(const Rect.fromLTWH(.5, 0, .5, .5)),
    );
    expect(
      () => CropSelection.pixelBounds(Rect.zero, 40, 20),
      throwsArgumentError,
    );
    expect(
      () => CropSelection.pixelBounds(
        const Rect.fromLTWH(-.1, 0, .5, .5),
        40,
        20,
      ),
      throwsArgumentError,
    );
  });
  test('crop preserves selected pixels and original file', () async {
    final before = await File(source.path).readAsBytes();
    final result = await CropService(temporaryDirectory: () async => temp)
        .crop(source, const Rect.fromLTWH(.5, 0, .5, 1));
    expect((result.width, result.height), (20, 20));
    final codec = await ui.instantiateImageCodec(
      await File(result.path).readAsBytes(),
    );
    final frame = await codec.getNextFrame();
    final pixels = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    expect(pixels!.getUint8(0), Colors.blue.r * 255);
    expect(pixels.getUint8(2), Colors.blue.b * 255);
    frame.image.dispose();
    codec.dispose();
    expect(await File(source.path).readAsBytes(), before);
    expect(result.exifTags, source.exifTags);
    expect(result.fileSizeBytes, await File(result.path).length());
    expect(result.originalSizeBytes, source.fileSizeBytes);
    final recropped = await CropService(temporaryDirectory: () async => temp)
        .crop(result, const Rect.fromLTWH(0, 0, .5, 1));
    expect(recropped.originalSizeBytes, source.fileSizeBytes);
    await CropService.deleteCrop(recropped.path);
    await CropService.deleteCrop(result.path);
    expect(await File(result.path).exists(), false);
    expect(await File(source.path).exists(), true);
  });

  test('controller recrops original, restores it and retains image after crop failure', () async {
    final service = CropService(temporaryDirectory: () async => temp);
    final controller = WorkbenchController(
      picker: _Picker(source.path),
      exifService: _Metadata(source),
      cropService: service,
    );
    await controller.pickImage();
    await controller.applyCrop(const Rect.fromLTWH(.5, 0, .5, 1));
    expect(controller.hasCrop, true);
    expect(controller.selectedImage!.width, 20);
    await controller.applyCrop(const Rect.fromLTWH(0, 0, .75, 1));
    expect(
      controller.selectedImage!.width,
      30,
    ); // 75% of original, not prior crop.
    final valid = controller.selectedImage;
    await controller.applyCrop(Rect.zero);
    expect(controller.selectedImage, same(valid));
    expect(controller.errorMessage, isNotNull);
    controller.restoreOriginal();
    expect(controller.selectedImage, same(source));
    expect(controller.hasCrop, false);
    controller.dispose();
  });

  test('disposing during crop cleans newly created result', () async {
    final service = _DelayedCrop(temp);
    final controller = WorkbenchController(
      picker: _Picker(source.path),
      exifService: _Metadata(source),
      cropService: service,
    );
    await controller.pickImage();
    final pending = controller.applyCrop(const Rect.fromLTWH(.5, 0, .5, 1));
    expect(controller.isBusy, true);
    controller.dispose();
    service.ready.complete();
    await pending;
    expect(await File(service.output!.path).exists(), false);
    expect(await File(source.path).exists(), true);
  });

  testWidgets(
    'crop dialog presets and freeform dragging apply the selected area',
    (tester) async {
      Rect? selected;
      Future<void> waitForCanvas() async {
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (find.byKey(const Key('crop-canvas')).evaluate().isEmpty &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
        expect(find.byKey(const Key('crop-canvas')), findsOneWidget);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showDialog<Rect>(
                    context: context,
                    builder: (_) => CropImageDialog(path: source.path),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      // Start file decoding outside the fake widget clock.
      await tester.runAsync(() async {
        await tester.tap(find.text('Open'));
        await tester.pump();
        await waitForCanvas();
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('1:1'));
      await tester.pump();
      await tester.tap(find.text('Freeform'));
      await tester.pump();
      final canvas = tester.getRect(find.byKey(const Key('crop-canvas')));
      await tester.dragFrom(
        Offset(canvas.left + canvas.width * .25, canvas.top),
        const Offset(40, 20),
      );
      await tester.pump();
      final applyButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Apply Crop'),
      );
      expect(applyButton.style!.foregroundColor!.resolve({}), Colors.white);
      await tester.tap(find.text('Apply Crop'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      expect(selected, isNotNull);
      expect(selected!.left, greaterThan(.25));
      expect(selected!.top, greaterThan(0));
      expect(selected!.width / selected!.height * 2, isNot(closeTo(1, .01)));
      Future<void> reopen() async {
        await tester.runAsync(() async {
          await tester.tap(find.text('Open'));
          await tester.pump();
          await waitForCanvas();
        });
        await tester.pumpAndSettle();
      }

      await reopen();
      await tester.tap(find.text('1:1'));
      await tester.tap(find.byTooltip('Reset crop'));
      await tester.tap(find.text('Apply Crop'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      expect(selected, CropSelection.full);
      await reopen();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });
      expect(selected, isNull);
    },
  );
}

class _Picker extends ImagePicker {
  final String path;
  _Picker(this.path);
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => XFile(path);
}

class _Metadata extends ExifService {
  final ImageMetadata image;
  _Metadata(this.image);
  @override
  Future<ImageMetadata> inspectImage(String path) async => image;
}

class _DelayedCrop extends CropService {
  final ready = Completer<void>();
  ImageMetadata? output;
  _DelayedCrop(Directory temp) : super(temporaryDirectory: () async => temp);
  @override
  Future<ImageMetadata> crop(ImageMetadata original, Rect selection) async {
    await ready.future;
    return output = await super.crop(original, selection);
  }
}
