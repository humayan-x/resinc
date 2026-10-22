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
  int _totalSavedBytes = 0;
  String? _errorMessage;

  SavedController({required this.savedService});

  List<SavedItem> get items => _items;
  bool get isLoading => _isLoading;
  int get totalSavedBytes => _totalSavedBytes;
  int get itemCount => _items.length;
  String? get errorMessage => _errorMessage;

  /// Loads saved items and aggregates storage savings
  Future<void> loadSaved() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await savedService.loadSavedItems();
      _totalSavedBytes = savedService.calculateTotalSavedBytes(_items);
    } catch (e) {
      _errorMessage = 'Failed to load saved items: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Removes an individual item from saved references
  Future<void> deleteItem(SavedItem item) async {
    try {
      await savedService.deleteItem(item);
      _items.removeWhere((i) => i.id == item.id);
      _totalSavedBytes = savedService.calculateTotalSavedBytes(_items);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete item: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Clears all saved references
  Future<void> clearSaved() async {
    try {
      await savedService.clearSaved();
      _items.clear();
      _totalSavedBytes = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear saved items: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Shares a saved item via the system share sheet
  Future<void> shareItem(SavedItem item) async {
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
