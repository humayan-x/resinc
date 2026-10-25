import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resinc/models/saved_item.dart';
import 'package:resinc/screens/saved/saved_tab.dart';
import 'package:resinc/screens/settings/widgets/storage_section.dart';
import 'package:resinc/services/saved_service.dart';
import 'package:resinc/state/saved_controller.dart';

final item = SavedItem(
  id: 'one',
  filePath: '/missing.jpg',
  fileName: 'photo.jpg',
  fileSizeBytes: 100,
  originalSizeBytes: 200,
  createdAt: DateTime(2026),
  width: 10,
  height: 10,
);

class FailingService extends SavedService {
  bool failLoad = false;
  bool failDelete = false;
  Completer<void>? clear;
  int clearCalls = 0;
  @override
  Future<List<SavedItem>> loadSavedItems() async {
    if (failLoad) throw const FileSystemException('load denied');
    return [item];
  }

  @override
  Future<void> deleteItem(SavedItem item) async {
    if (failDelete) throw const FileSystemException('delete denied');
  }

  @override
  Future<void> clearSaved() async {
    clearCalls++;
    await clear?.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'service surfaces storage failures instead of returning empty/success',
    () async {
      final service = SavedService(
        directoryProvider: () async {
          throw const FileSystemException('storage unavailable');
        },
      );
      await expectLater(
        service.loadSavedItems(),
        throwsA(isA<FileSystemException>()),
      );
      await expectLater(
        service.clearSaved(),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'failed reload and delete keep items and totals; success clears errors',
    () async {
      final service = FailingService();
      final controller = SavedController(savedService: service);
      addTearDown(controller.dispose);
      await controller.loadSaved();
      service.failLoad = true;
      await controller.loadSaved();
      expect(controller.items, [item]);
      expect(controller.totalSavedBytes, 100);
      expect(controller.errorMessage, contains('Could not load'));
      service.failDelete = true;
      expect(await controller.deleteItem(item), isFalse);
      expect(controller.items, [item]);
      expect(controller.errorMessage, contains('Could not remove'));
      service.failDelete = false;
      expect(await controller.deleteItem(item), isTrue);
      expect(controller.items, isEmpty);
      expect(controller.totalSavedBytes, 0);
      expect(controller.errorMessage, isNull);
    },
  );

  test(
    'clear waits, blocks duplicate mutations and retains history on failure',
    () async {
      final service = FailingService()..clear = Completer<void>();
      final controller = SavedController(savedService: service);
      addTearDown(controller.dispose);
      await controller.loadSaved();
      final pending = controller.clearSaved();
      expect(controller.isBusy, isTrue);
      expect(controller.items, [item]);
      expect(await controller.clearSaved(), isFalse);
      expect(service.clearCalls, 1);
      service.clear!.completeError(const FileSystemException('clear denied'));
      expect(await pending, isFalse);
      expect(controller.isBusy, isFalse);
      expect(controller.items, [item]);
      expect(controller.errorMessage, contains('Could not clear'));
    },
  );

  testWidgets('Saved shows initial load error with a working refresh', (
    tester,
  ) async {
    final service = FailingService()..failLoad = true;
    final controller = SavedController(savedService: service);
    addTearDown(controller.dispose);
    await controller.loadSaved();
    await tester.pumpWidget(
      MaterialApp(home: SavedTab(controller: controller)),
    );
    expect(find.textContaining('Could not load saved history'), findsOneWidget);
    expect(find.text('No Saved Images'), findsNothing);
    service.failLoad = false;
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load saved history'), findsNothing);
    expect(controller.itemCount, 1);
  });

  for (final succeeds in [true, false]) {
    testWidgets('Settings waits for clear; success=$succeeds', (tester) async {
      final service = FailingService()..clear = Completer<void>();
      final controller = SavedController(savedService: service);
      addTearDown(controller.dispose);
      await controller.loadSaved();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StorageSection(savedController: controller)),
        ),
      );
      await tester.tap(find.text('Clear Saved References'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();
      expect(find.text('Saved references cleared.'), findsNothing);
      expect(controller.itemCount, 1);
      if (succeeds) {
        service.clear!.complete();
      } else {
        service.clear!.completeError(const FileSystemException('clear denied'));
      }
      await tester.pumpAndSettle();
      expect(
        find.text('Saved references cleared.'),
        succeeds ? findsOneWidget : findsNothing,
      );
      expect(controller.itemCount, succeeds ? 0 : 1);
      if (!succeeds) {
        expect(
          find.textContaining('Could not clear all saved items'),
          findsOneWidget,
        );
      }
    });
  }
}
