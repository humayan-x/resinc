import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/widgets/file_preview.dart';

void main() {
  testWidgets('thumbnail decodes near its viewport and preserves proportions', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('preview_test_');
    try {
      final file = File('${temp.path}/photo.png');
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawColor(Colors.blue, ui.BlendMode.src);
        final picture = recorder.endRecording();
        final source = await picture.toImage(1200, 600);
        final png = await source.toByteData(format: ui.ImageByteFormat.png);
        source.dispose();
        picture.dispose();
        await file.writeAsBytes(png!.buffer.asUint8List());
      });
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(400, 800),
                devicePixelRatio: 2,
              ),
              child: Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: FilePreview(file, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        );
        final provider = tester.widget<Image>(find.byType(Image)).image;
        // Resolve the actual file decoder, rather than checking only arguments.
        await precacheImage(provider, tester.element(find.byType(FilePreview)));
      });
      await tester.pump();
      final decoded = tester.widget<RawImage>(find.byType(RawImage)).image!;
      expect((decoded.width, decoded.height), (96, 48));
      await tester.pumpWidget(const SizedBox());
      PaintingBinding.instance.imageCache.clear();
    } finally {
      temp.deleteSync(recursive: true);
    }
  });
}
