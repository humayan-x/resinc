import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/compression_options.dart';
import '../utils/constants.dart';
import '../models/compression_result.dart';
import '../models/image_metadata.dart';
import '../models/saved_item.dart';
import '../services/compression_service.dart';
import '../services/crop_service.dart';
import '../models/crop_selection.dart';
import '../services/exif_service.dart';
import '../services/saved_service.dart';

/// State controller for Tab 1 (Workbench).
class WorkbenchController extends ChangeNotifier {
  final ExifService _exifService;
  final CompressionService _compressionService = CompressionService();
  final ImagePicker _picker;
  final CropService _cropService;
  ImageMetadata? _originalImage;
  Rect _cropSelection = CropSelection.full;
  bool _isCropping = false;
  ImageMetadata? get originalImage => _originalImage;
  Rect get cropSelection => _cropSelection;
  bool get isCropping => _isCropping;
  bool get hasCrop =>
      _originalImage != null && _selectedImage?.path != _originalImage?.path;

  void _discardCrop() {
    if (hasCrop) unawaited(CropService.deleteCrop(_selectedImage!.path));
  }

  Future<void> applyCrop(Rect selection) async {
    if (isBusy || _disposed || _originalImage == null) return;
    if (selection == CropSelection.full) {
      restoreOriginal();
      return;
    }
    _isCropping = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cropped = await _cropService.crop(_originalImage!, selection);
      if (_disposed) {
        await CropService.deleteCrop(cropped.path);
        return;
      }
      _discardResult();
      _discardCrop();
      _selectedImage = cropped;
      _cropSelection = selection;
      _isSavedToGallery = false;
    } catch (e) {
      _errorMessage = 'Could not crop image: $e';
    } finally {
      _isCropping = false;
      notifyListeners();
    }
  }

  void restoreOriginal() {
    if (isBusy || _disposed || _originalImage == null) return;
    _discardResult();
    _discardCrop();
    _selectedImage = _originalImage;
    _cropSelection = CropSelection.full;
    _isSavedToGallery = false;
    _errorMessage = null;
    notifyListeners();
  }

  bool _disposed = false;
  bool _isSaving = false;
  bool _isSharing = false;
  bool get isBusy =>
      _isInspecting || _isCompressing || _isSaving || _isSharing || _isCropping;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void _discardResult() {
    final result = _compressionResult;
    _compressionResult = null;
    if (result != null) {
      unawaited(CompressionService.deleteResult(result.compressedPath));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (!_isCompressing) _discardCrop();
    if (!_isSaving && !_isSharing) _discardResult();
    super.dispose();
  }

  ImageMetadata? _selectedImage;
  CompressionOptions _options = const CompressionOptions();
  CompressionResult? _compressionResult;
  List<int> _savedCustomPresets = [];
  bool _isInspecting = false;
  bool _isCompressing = false;
  bool _isSavedToGallery = false;
  String? _errorMessage;

  WorkbenchController({
    ExifService? exifService,
    ImagePicker? picker,
    CropService? cropService,
  }) : _exifService = exifService ?? ExifService(),
       _picker = picker ?? ImagePicker(),
       _cropService = cropService ?? CropService() {
    _loadCustomPresets();
  }

  // Getters
  ImageMetadata? get selectedImage => _selectedImage;
  CompressionOptions get options => _options;
  CompressionResult? get compressionResult => _compressionResult;
  List<int> get savedCustomPresets => _savedCustomPresets;
  bool get isInspecting => _isInspecting;
  bool get isCompressing => _isCompressing;
  bool get isSavedToGallery => _isSavedToGallery;
  String? get errorMessage => _errorMessage;

  bool get hasImage => _selectedImage != null;
  bool get hasResult => _compressionResult != null;

  /// Loads saved custom presets from local app storage (maximum 3)
  Future<void> _loadCustomPresets() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/custom_presets.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _savedCustomPresets = list
            .map((e) => (e as num).toInt())
            .where(
              (e) => CompressionOptions(
                preset: CompressionPreset.customKB,
                customTargetKB: e,
              ).isValid,
            )
            .take(3)
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading custom presets: $e');
    }
  }

  /// Persists custom presets to local storage
  Future<void> _persistCustomPresets() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/custom_presets.json');
      await file.writeAsString(jsonEncode(_savedCustomPresets));
    } catch (e) {
      debugPrint('Error persisting custom presets: $e');
    }
  }

  /// Saves a newly compressed custom KB as a preset (capped at 3 saved custom presets)
  Future<void> _saveCustomPreset(int kb) async {
    if (kb < AppConstants.minimumTargetKB) return;
    _savedCustomPresets.remove(kb);
    _savedCustomPresets.insert(0, kb);
    if (_savedCustomPresets.length > 3) {
      _savedCustomPresets = _savedCustomPresets.sublist(0, 3);
    }
    notifyListeners();
    await _persistCustomPresets();
  }

  /// Selects a saved custom preset
  void selectSavedCustomPreset(int kb) {
    if (kb < AppConstants.minimumTargetKB) return;
    if (isBusy || _disposed) return;
    _options = _options.copyWith(
      preset: CompressionPreset.customKB,
      customTargetKB: kb,
    );
    notifyListeners();
  }

  /// Removes a saved custom preset
  Future<void> removeSavedCustomPreset(int kb) async {
    _savedCustomPresets.remove(kb);
    notifyListeners();
    await _persistCustomPresets();
  }

  /// Launches the system photo gallery picker
  Future<void> pickImage() async {
    if (isBusy || _disposed) return;
    _isInspecting = true;
    notifyListeners();
    try {
      _errorMessage = null;
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      _isInspecting = true;
      _discardResult();
      _isSavedToGallery = false;
      notifyListeners();

      final image = await _exifService.inspectImage(picked.path);
      if (!_disposed) {
        _discardCrop();
        _originalImage = image;
        _selectedImage = image;
        _cropSelection = CropSelection.full;
      }
    } catch (e) {
      _errorMessage = 'Failed to load image: ${e.toString()}';
    } finally {
      _isInspecting = false;
      notifyListeners();
    }
  }

  /// Sets the compression preset
  void setPreset(CompressionPreset preset) {
    if (isBusy || _disposed) return;
    _options = _options.copyWith(preset: preset);
    notifyListeners();
  }

  /// Sets custom target file size in KB
  void setCustomTargetKB(int? kb) {
    if (isBusy || _disposed) return;
    _options = _options.copyWith(
      preset: CompressionPreset.customKB,
      customTargetKB: kb,
    );
    notifyListeners();
  }

  /// Toggles EXIF and GPS stripping
  void setStripExif(bool value) {
    if (isBusy || _disposed) return;
    _options = _options.copyWith(stripExif: value);
    notifyListeners();
  }

  /// Triggers the iterative compression engine
  Future<void> compress() async {
    if (_selectedImage == null || isBusy || _disposed) return;
    if (!_options.isValid) {
      _errorMessage = 'Enter a whole-number target of at least 50 KB.';
      notifyListeners();
      return;
    }
    final jobOptions = _options;
    final jobImage = _selectedImage!;

    _isCompressing = true;
    _errorMessage = null;
    _isSavedToGallery = false;
    notifyListeners();

    try {
      final result = await _compressionService.compressImage(
        metadata: jobImage,
        options: jobOptions,
      );
      if (_disposed) {
        await CompressionService.deleteResult(result.compressedPath);
        return;
      }
      _discardResult();
      _compressionResult = result;

      // If user chose custom KB, save that KB as a preset to display after Custom
      if (_options.preset == CompressionPreset.customKB &&
          _options.customTargetKB != null &&
          _options.isValid) {
        await _saveCustomPreset(_options.customTargetKB!);
      }
    } catch (e) {
      _errorMessage = 'Compression failed: ${e.toString()}';
    } finally {
      _isCompressing = false;
      if (_disposed) _discardCrop();
      notifyListeners();
    }
  }

  /// Saves the active compression result to the gallery and retains a reference
  Future<SavedItem?> saveToGallery(SavedService savedService) async {
    if (_compressionResult == null ||
        _isSavedToGallery ||
        isBusy ||
        _disposed) {
      return null;
    }
    _isSaving = true;
    notifyListeners();
    try {
      // 1. Request access permission from the user
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          _errorMessage = 'Gallery access permission was denied. Please allow gallery access to save images.';
          notifyListeners();
          return null;
        }
      }

      // 2. Save image to gallery & create saved reference
      final item = await savedService.saveToGallery(_compressionResult!);
      _isSavedToGallery = true;
      _errorMessage = null;
      notifyListeners();
      return item;
    } on GalException catch (e) {
      _errorMessage = 'Gallery error: ${e.type.message}';
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to save to gallery: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _isSaving = false;
      if (_disposed) _discardResult();
      notifyListeners();
    }
  }

  /// Shares the compressed file via system share sheet
  Future<void> shareResult() async {
    if (_compressionResult == null || isBusy || _disposed) return;
    _isSharing = true;
    notifyListeners();
    try {
      await _compressionResult!.verifyFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(_compressionResult!.compressedPath)],
          text: 'Optimized with Resinc (${AppConstants.githubRepoUrl})',
        ),
      );
    } catch (e) {
      _errorMessage = 'Share failed: ${e.toString()}';
      notifyListeners();
    } finally {
      _isSharing = false;
      if (_disposed) _discardResult();
      notifyListeners();
    }
  }

  /// Clears active compression result to return to preset selector for current image
  void clearResult() {
    if (isBusy || _disposed) return;
    _discardResult();
    _isSavedToGallery = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Resets the workbench to initial empty state
  void reset() {
    if (isBusy || _disposed) return;
    _discardCrop();
    _originalImage = null;
    _cropSelection = CropSelection.full;
    _selectedImage = null;
    _discardResult();
    _isSavedToGallery = false;
    _errorMessage = null;
    notifyListeners();
  }
}
