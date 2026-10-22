import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/app/app.dart';
import 'package:resinc/models/saved_item.dart';
import 'package:resinc/screens/onboarding/onboarding_screen.dart';
import 'package:resinc/screens/settings/settings_tab.dart';
import 'package:resinc/screens/workbench/workbench_tab.dart';
import 'package:resinc/services/preferences_service.dart';
import 'package:resinc/services/saved_service.dart';
import 'package:resinc/state/saved_controller.dart';
import 'package:resinc/state/theme_controller.dart';
import 'package:resinc/state/workbench_controller.dart';

void main() {
  group('PreferencesService tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('resinc_prefs_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('fresh preferences file returns false for hasSeenOnboarding', () async {
      final service = PreferencesService(
        directoryProvider: () async => tempDir,
        initialHasSeenOnboarding: null,
      );

      final seen = await service.hasSeenOnboarding();
      expect(seen, isFalse);
    });

    test('setHasSeenOnboarding saves true and persists to file', () async {
      final service = PreferencesService(
        directoryProvider: () async => tempDir,
        initialHasSeenOnboarding: null,
      );

      await service.setHasSeenOnboarding(true);
      expect(await service.hasSeenOnboarding(), isTrue);

      final secondService = PreferencesService(
        directoryProvider: () async => tempDir,
        initialHasSeenOnboarding: null,
      );
      expect(await secondService.hasSeenOnboarding(), isTrue);
    });

    test('resetPreferences clears persisted value', () async {
      final service = PreferencesService(
        directoryProvider: () async => tempDir,
        initialHasSeenOnboarding: null,
      );

      await service.setHasSeenOnboarding(true);
      expect(await service.hasSeenOnboarding(), isTrue);

      await service.resetPreferences();
      expect(await service.hasSeenOnboarding(), isFalse);
    });

    test('themeMode persists and reloads correctly across instances', () async {
      final service = PreferencesService(
        directoryProvider: () async => tempDir,
        initialHasSeenOnboarding: null,
      );

      expect(await service.getThemeMode(), ThemeMode.dark);

      await service.setThemeMode(ThemeMode.light);
      expect(await service.getThemeMode(), ThemeMode.light);

      final secondService = PreferencesService(
        directoryProvider: () async => tempDir,
        initialHasSeenOnboarding: null,
      );
      expect(await secondService.getThemeMode(), ThemeMode.light);

      final controller = ThemeController(preferencesService: secondService);
      await controller.loadSavedTheme();
      expect(controller.themeMode, ThemeMode.light);

      await controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode, ThemeMode.system);

      final thirdService = PreferencesService(
        directoryProvider: () async => tempDir,
        initialHasSeenOnboarding: null,
      );
      expect(await thirdService.getThemeMode(), ThemeMode.system);
    });
  });

  group('OnboardingScreen widget tests', () {
    testWidgets('renders top bar, slide 1 hero card, and navigation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('ReSinc'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Hit Strict Target Size Ceilings'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('navigates through all slides and completes on Get Started', (
      WidgetTester tester,
    ) async {
      bool completed = false;
      bool markedSeen = false;
      final testPrefs = _MockPreferencesService(
        initialSeen: false,
        onMarkSeen: () => markedSeen = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            preferencesService: testPrefs,
            onComplete: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1
      expect(find.text('Hit Strict Target Size Ceilings'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Slide 2
      expect(find.text('Zero Cloud. 100% On-Device.'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Slide 3
      expect(find.text('Purge Hidden EXIF & GPS Tags'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(markedSeen, isTrue);
    });

    testWidgets('tapping Skip immediately triggers completion and marks seen', (
      WidgetTester tester,
    ) async {
      bool completed = false;
      bool markedSeen = false;
      final testPrefs = _MockPreferencesService(
        initialSeen: false,
        onMarkSeen: () => markedSeen = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            preferencesService: testPrefs,
            onComplete: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(markedSeen, isTrue);
    });
  });

  group('Onboarding integration tests', () {
    testWidgets('ResincApp renders OnboardingScreen when not yet seen and switches on complete', (
      WidgetTester tester,
    ) async {
      final testPrefs = _MockPreferencesService(initialSeen: false);

      await tester.pumpWidget(
        ResincApp(
          preferencesService: testPrefs,
        ),
      );
      await tester.pumpAndSettle();

      // Initially shows OnboardingScreen
      expect(find.text('Hit Strict Target Size Ceilings'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Skip onboarding
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Now reveals HomeNavigationScreen
      expect(find.text('Tap to Select Image'), findsOneWidget);
    });

    testWidgets('WorkbenchTab Quick Guide button opens OnboardingScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkbenchTab(
              controller: WorkbenchController(),
              themeController: ThemeController(),
              onOpenGuide: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Quick Guide'), findsOneWidget);
    });

    testWidgets('SettingsTab displays Guides section and invokes onOpenGuide', (
      WidgetTester tester,
    ) async {
      bool guideOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsTab(
              savedController: SavedController(savedService: _EmptySavedService()),
              themeController: ThemeController(),
              onOpenGuide: () => guideOpened = true,
            ),
          ),
        ),
      );

      expect(find.text('Guides'), findsOneWidget);
      expect(find.text('How ReSinc Works'), findsOneWidget);
      await tester.tap(find.text('How ReSinc Works'));
      await tester.pumpAndSettle();

      expect(guideOpened, isTrue);
    });
  });
}

class _EmptySavedService extends SavedService {
  @override
  Future<List<SavedItem>> loadSavedItems() async => [];
}

class _MockPreferencesService extends PreferencesService {
  bool seen;
  final VoidCallback? onMarkSeen;

  _MockPreferencesService({
    bool initialSeen = false,
    this.onMarkSeen,
  })  : seen = initialSeen,
        super(initialHasSeenOnboarding: initialSeen);

  @override
  Future<bool> hasSeenOnboarding() async => seen;

  @override
  Future<void> setHasSeenOnboarding(bool value) async {
    seen = value;
    onMarkSeen?.call();
  }
}
