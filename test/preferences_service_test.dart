import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/services/preferences_service.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'resinc_preferences_test_',
    );
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'concurrent updates preserve theme and onboarding after restart',
    () async {
      final service = PreferencesService(
        directoryProvider: () async => directory,
      );
      await Future.wait([
        service.setThemeMode(ThemeMode.light),
        service.setHasSeenOnboarding(true),
      ]);

      final restarted = PreferencesService(
        directoryProvider: () async => directory,
      );
      expect(await restarted.getThemeMode(), ThemeMode.light);
      expect(await restarted.hasSeenOnboarding(), isTrue);
    },
  );

  test('reset waits for earlier writes and preserves later updates', () async {
    final ready = Completer<Directory>();
    final service = PreferencesService(directoryProvider: () => ready.future);
    final firstWrite = service.setHasSeenOnboarding(true);
    final reset = service.resetPreferences();
    final lastWrite = service.setThemeMode(ThemeMode.system);
    ready.complete(directory);
    await Future.wait([firstWrite, reset, lastWrite]);

    final restarted = PreferencesService(
      directoryProvider: () async => directory,
    );
    expect(await restarted.hasSeenOnboarding(), isFalse);
    expect(await restarted.getThemeMode(), ThemeMode.system);
  });
}
