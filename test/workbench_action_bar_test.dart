import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/models/compression_result.dart';
import 'package:resinc/models/image_metadata.dart';
import 'package:resinc/models/saved_item.dart';
import 'package:resinc/screens/home_navigation_screen.dart';
import 'package:resinc/services/saved_service.dart';
import 'package:resinc/state/theme_controller.dart';
import 'package:resinc/state/workbench_controller.dart';
import 'package:resinc/widgets/floating_bottom_bar.dart';
import 'package:resinc/widgets/floating_bar_frame.dart';
import 'package:resinc/widgets/workbench_action_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late _Workbench controller;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('action_bar_test_');
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(20, 20);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    final file = await File('${temp.path}/image.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    controller = _Workbench(
      ImageMetadata(
        path: file.path,
        fileName: 'image.png',
        width: 20,
        height: 20,
        fileSizeBytes: await file.length(),
        exifTags: const {},
      ),
    );
  });
  tearDown(() async {
    controller.dispose();
    await temp.delete(recursive: true);
  });

  testWidgets(
    'navigation is replaced by equal-sized workflow actions and returns on back',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeNavigationScreen(
            themeController: ThemeController(),
            savedService: _Saved(),
            workbenchController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final frameSize = tester.getSize(find.byType(FloatingBarFrame));
      expect(find.byType(FloatingBottomBar), findsOneWidget);
      controller.upload();
      await tester.pumpAndSettle();
      expect(find.byType(FloatingBottomBar), findsNothing);
      expect(find.text('Optimise'), findsOneWidget);
      expect(tester.getSize(find.byType(FloatingBarFrame)), frameSize);
      expect(
        find.descendant(
          of: find.byType(WorkbenchActionBar),
          matching: find.text('Optimise'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Optimise'));
      await tester.pumpAndSettle();
      expect(find.text('Optimise'), findsNothing);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Save to Gallery'), findsNothing);
      expect(tester.getSize(find.byType(FloatingBarFrame)), frameSize);
      await tester.tap(find.byTooltip('Share'));
      expect(controller.shares, 1);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);
      await tester.tap(find.byTooltip('New preset'));
      await tester.pumpAndSettle();
      expect(find.text('Optimise'), findsOneWidget);
      await tester.tap(find.byTooltip('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingBottomBar), findsOneWidget);
      expect(find.byType(WorkbenchActionBar), findsNothing);
    },
  );

  testWidgets('dialogs and detail routes hide the bottom bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeNavigationScreen(
          themeController: ThemeController(),
          savedService: _Saved(),
          workbenchController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(HomeNavigationScreen));
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Details'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FloatingBottomBar), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingBottomBar), findsOneWidget);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Detail page')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FloatingBottomBar), findsNothing);
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(find.byType(FloatingBottomBar), findsOneWidget);
  });

  testWidgets(
    'invalid target and busy processing disable the floating action',
    (tester) async {
      controller.upload();
      controller.setCustomTargetKB(49);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeNavigationScreen(
            themeController: ThemeController(),
            savedService: _Saved(),
            workbenchController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.widgetWithText(ElevatedButton, 'Optimise');
      expect(tester.widget<ElevatedButton>(action).onPressed, isNull);
      controller.setCustomTargetKB(50);
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(action).onPressed, isNotNull);
      controller.busy = true;
      controller.notifyListeners();
      await tester.pump();
      expect(tester.widget<ElevatedButton>(action).onPressed, isNull);
    },
  );
}

class _Saved extends SavedService {
  @override
  Future<List<SavedItem>> loadSavedItems() async => [];
}

class _Workbench extends WorkbenchController {
  final ImageMetadata image;
  bool loaded = false, complete = false, saved = false, busy = false;
  int shares = 0;
  _Workbench(this.image);
  void upload() {
    loaded = true;
    notifyListeners();
  }

  @override
  bool get hasImage => loaded;
  @override
  bool get hasResult => complete;
  @override
  bool get isBusy => busy;
  @override
  bool get isSavedToGallery => saved;
  @override
  ImageMetadata? get selectedImage => loaded ? image : null;
  @override
  ImageMetadata? get originalImage => selectedImage;
  @override
  CompressionResult? get compressionResult => complete
      ? CompressionResult(
          originalPath: image.path,
          compressedPath: image.path,
          originalSizeBytes: 1000,
          compressedSizeBytes: 100,
          outputWidth: 20,
          outputHeight: 20,
          exifStripped: true,
          processingTime: Duration.zero,
        )
      : null;
  @override
  Future<void> compress() async {
    complete = true;
    notifyListeners();
  }

  @override
  void clearResult() {
    complete = false;
    saved = false;
    notifyListeners();
  }

  @override
  void reset() {
    loaded = false;
    clearResult();
  }

  @override
  Future<void> shareResult() async {
    shares++;
  }

  @override
  Future<SavedItem?> saveToGallery(SavedService service) async {
    saved = true;
    notifyListeners();
    return null;
  }
}
