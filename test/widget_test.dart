import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/screens/home_navigation_screen.dart';
import 'package:resinc/services/saved_service.dart';
import 'package:resinc/state/theme_controller.dart';
import 'package:resinc/models/compression_options.dart';
import 'package:resinc/models/saved_item.dart';
import 'package:resinc/utils/file_utils.dart';

void main() {
  group('FileUtils unit tests', () {
    test('formatBytes formats bytes correctly', () {
      expect(FileUtils.formatBytes(0), '0 B');
      expect(FileUtils.formatBytes(500), '500.0 B');
      expect(FileUtils.formatBytes(1000), '1.0 KB');
      expect(FileUtils.formatBytes(1000 * 1000 * 3), '3.0 MB');
    });

    test('calculateReductionPercentage computes reduction correctly', () {
      expect(FileUtils.calculateReductionPercentage(1000, 200), 80.0);
      expect(FileUtils.calculateReductionPercentage(100, 100), 0.0);
      expect(FileUtils.calculateReductionPercentage(0, 50), 0.0);
    });
  });

  group('CompressionOptions tests', () {
    test('effectiveTargetKB returns preset values or custom values', () {
      const opt100 = CompressionOptions(preset: CompressionPreset.max100KB);
      expect(opt100.effectiveTargetKB, 100);
      expect(opt100.effectiveTargetBytes, 100 * 1000);

      const optCustom = CompressionOptions(
        preset: CompressionPreset.customKB,
        customTargetKB: 250,
      );
      expect(optCustom.effectiveTargetKB, 250);
      expect(optCustom.effectiveTargetBytes, 250 * 1000);

      const opt1080 = CompressionOptions(preset: CompressionPreset.p1080);
      expect(opt1080.effectiveTargetKB, isNull);
    });
  });

  testWidgets('ResincApp smoke test renders navigation and workbench', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeNavigationScreen(
          themeController: ThemeController(),
          savedService: _EmptySavedService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and navigation icons
    expect(find.text('ReSinc'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('Tap to Select Image'), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });

  testWidgets('Saved Tab navigation displays Saved header and empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeNavigationScreen(
          themeController: ThemeController(),
          savedService: _EmptySavedService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Saved tab (middle item in bottom bar)
    await tester.tap(find.byIcon(Icons.photo_library_outlined));
    await tester.pumpAndSettle();

    // Check for 'Saved' title and empty state text
    expect(find.text('Saved'), findsWidgets);
    expect(find.text('No Saved Images'), findsOneWidget);
    expect(find.textContaining('"Save"'), findsOneWidget);
  });

  testWidgets('swipes synchronize navigation in both directions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeNavigationScreen(
          themeController: ThemeController(),
          savedService: _EmptySavedService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final icon in [Icons.photo_library_rounded, Icons.settings_rounded]) {
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.byIcon(icon), findsOneWidget);
    }
    for (final icon in [Icons.photo_library_rounded, Icons.home_rounded]) {
      await tester.drag(find.byType(PageView), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(find.byIcon(icon), findsOneWidget);
    }
  });

  test(
    'SavedItem model stores location, dimensions and calculates metrics',
    () {
      final item = SavedItem(
        id: 'test_1',
        filePath: '/path/to/test.jpg',
        fileName: 'test.jpg',
        fileSizeBytes: 100 * 1000,
        originalSizeBytes: 500 * 1000,
        createdAt: DateTime(2026, 1, 1),
        width: 1080,
        height: 1920,
        storeLocation: 'Gallery / ReSinc / test.jpg',
      );

      expect(item.fileName, 'test.jpg');
      expect(item.storeLocation, 'Gallery / ReSinc / test.jpg');
      expect(item.resolutionString, '1080x1920 px');
      expect(item.fileSizeFormatted, '100.0 KB');
      expect(item.reductionPercentage, 80.0);
      expect(item.exifStripped, isTrue);
    },
  );
}

class _EmptySavedService extends SavedService {
  @override
  Future<List<SavedItem>> loadSavedItems() async => [];
}
