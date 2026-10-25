import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_item.dart';
import '../services/saved_service.dart';

/// State controller for Tab 2 (Saved).
class SavedController extends ChangeNotifier {
  final SavedService savedService;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<SavedItem> _items = [];
  bool _isLoading = false;
  bool _isMutating = false;
  int _totalSavedBytes = 0;
  String? _errorMessage;

  SavedController({required this.savedService});

  List<SavedItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isBusy => _isLoading || _isMutating;
  int get totalSavedBytes => _totalSavedBytes;

  /// Photo bytes held in app storage, excluding sidecars and gallery copies.
  int get localPhotoBytes =>
      _items.fold(0, (total, item) => total + item.fileSizeBytes);
  int get itemCount => _items.length;
  String? get errorMessage => _errorMessage;

  /// Loads saved items and aggregates file-size reductions
  Future<void> loadSaved() async {
    if (_disposed || isBusy) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await savedService.loadSavedItems();
      _totalSavedBytes = savedService.calculateTotalSavedBytes(_items);
    } catch (e) {
      _errorMessage =
          'Could not load saved history. Please refresh to try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Report success only after the files have been removed.
  Future<bool> deleteItem(SavedItem item) =>
      _mutate(() => savedService.deleteItem(item), () {
        _items.removeWhere((i) => i.id == item.id);
        _totalSavedBytes = savedService.calculateTotalSavedBytes(_items);
      }, 'Could not remove this saved item. Refresh the list and try again.');

  Future<bool> clearSaved() => _mutate(
    savedService.clearSaved,
    () {
      _items.clear();
      _totalSavedBytes = 0;
    },
    'Could not clear all saved items. Some files may have been removed. '
    'Refresh the list and try again.',
  );

  Future<bool> _mutate(
    Future<void> Function() operation,
    VoidCallback onSuccess,
    String failureMessage,
  ) async {
    if (_disposed || isBusy) return false;
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await operation();
      if (_disposed) return false;
      onSuccess();
      return true;
    } catch (_) {
      _errorMessage = failureMessage;
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// Shares a saved item via the system share sheet
  Future<void> shareItem(SavedItem item) async {
    if (_disposed || isBusy) return;
    _errorMessage = null;
    notifyListeners();
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(item.filePath)],
          text: 'Optimized with Resinc (${item.fileSizeFormatted})',
        ),
      );
    } catch (e) {
      _errorMessage = 'Share failed: ${e.toString()}';
      notifyListeners();
    }
  }
}
