import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../models/compression_result.dart';
import '../models/saved_item.dart';
import '../utils/constants.dart';
import '../utils/file_utils.dart';

/// Manages saving images to gallery and maintaining synchronized saved references.
class SavedService {
  final Future<Directory> Function()? directoryProvider;
  final Future<List<String>> Function(List<String> fileNames)? galleryChecker;
  Directory? _savedDir;

  static const MethodChannel _galleryChannel = MethodChannel(
    'io.github.humayanx.resinc/gallery',
  );

  SavedService({this.directoryProvider, this.galleryChecker});

  Future<Directory> _getSavedDirectory() async {
    if (_savedDir != null && await _savedDir!.exists()) {
      return _savedDir!;
    }
    final appDocDir = directoryProvider != null
        ? await directoryProvider!()
        : await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocDir.path}/${AppConstants.savedFolderName}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _savedDir = dir;
    return dir;
  }

  Future<List<String>> _defaultGalleryChecker(List<String> fileNames) async {
    if (kIsWeb || !Platform.isAndroid || fileNames.isEmpty) {
      return fileNames;
    }
    try {
      final result = await _galleryChannel.invokeMethod<List<dynamic>>(
        'getExistingGalleryImages',
        {'fileNames': fileNames},
      );
      return result?.cast<String>() ?? fileNames;
    } catch (e) {
      debugPrint('Error checking gallery images: $e');
      return fileNames;
    }
  }

  /// Saves a compressed image to device gallery and keeps a local reference.
  Future<SavedItem> saveToGallery(CompressionResult result) async {
    await result.verifyFile();
    final savedDir = await _getSavedDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final sizeKb = (result.compressedSizeBytes / 1000).round();
    final fileName = 'resinc_${timestamp}_${sizeKb}kb.jpg';
    final targetPath = '${savedDir.path}/$fileName';

    // Copy compressed file into local reference storage
    final sourceFile = File(result.compressedPath);
    await sourceFile.copy(targetPath);

    // Save image into device Gallery under "ReSinc" album
    try {
      await result.verifyFile(targetPath);
      await Gal.putImage(targetPath, album: 'ReSinc');
    } catch (_) {
      await FileUtils.safeDeleteFile(targetPath);
      rethrow;
    }

    final item = SavedItem(
      id: timestamp.toString(),
      filePath: targetPath,
      fileName: fileName,
      fileSizeBytes: result.compressedSizeBytes,
      originalSizeBytes: result.originalSizeBytes,
      createdAt: DateTime.now(),
      width: result.outputWidth,
      height: result.outputHeight,
      storeLocation: 'Gallery / ReSinc',
      exifStripped: result.exifStripped,
    );

    // Save lightweight sidecar metadata file (.meta) for fast offline indexing
    final metaPath = '${savedDir.path}/$fileName.meta';
    final metaFile = File(metaPath);
    final metaJson = {
      'id': item.id,
      'filePath': item.filePath,
      'fileName': item.fileName,
      'fileSizeBytes': item.fileSizeBytes,
      'originalSizeBytes': item.originalSizeBytes,
      'createdAt': item.createdAt.toIso8601String(),
      'width': item.width,
      'height': item.height,
      'storeLocation': item.storeLocation,
      'exifStripped': item.exifStripped,
    };
    await metaFile.writeAsString(jsonEncode(metaJson));

    return item;
  }

  /// Loads all items from the saved directory, verifying gallery existence.
  /// If the user deleted an image from their gallery, this automatically
  /// purges the local reference and metadata.
  Future<List<SavedItem>> loadSavedItems() async {
    try {
      final savedDir = await _getSavedDirectory();
      final entities = await savedDir.list().toList();
      final List<SavedItem> items = [];

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          final metaFile = File('${entity.path}.meta');
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (await metaFile.exists()) {
            try {
              final content = await metaFile.readAsString();
              final map = jsonDecode(content) as Map<String, dynamic>;
              items.add(
                SavedItem(
                  id: map['id']?.toString() ?? entity.path,
                  filePath: entity.path,
                  fileName: map['fileName']?.toString() ?? fileName,
                  fileSizeBytes: await entity.length(),
                  originalSizeBytes:
                      map['originalSizeBytes'] as int? ?? await entity.length(),
                  createdAt:
                      DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
                      await entity.lastModified(),
                  width: map['width'] as int? ?? 1080,
                  height: map['height'] as int? ?? 1080,
                  storeLocation:
                      map['storeLocation']?.toString() ?? 'Gallery / ReSinc',
                  exifStripped: map['exifStripped'] as bool? ?? true,
                ),
              );
              continue;
            } on FileSystemException {
              rethrow;
            } catch (e) {
              debugPrint('Error parsing saved meta file: $e');
            }
          }

          // Fallback if no meta sidecar exists
          final stat = await entity.stat();
          final length = await entity.length();
          items.add(
            SavedItem(
              id: entity.path,
              filePath: entity.path,
              fileName: fileName,
              fileSizeBytes: length,
              originalSizeBytes: length,
              createdAt: stat.modified,
              width: 1080,
              height: 1080,
              storeLocation: 'Gallery / ReSinc',
              exifStripped: true,
            ),
          );
        }
      }

      if (items.isEmpty) return [];

      // Verify each item against gallery existence
      final fileNames = items.map((i) => i.fileName).toList();
      final checker = galleryChecker ?? _defaultGalleryChecker;
      final Set<String> existingFileNames;
      try {
        // Only a successful, complete check can authorize removing references.
        existingFileNames = (await checker(fileNames)).toSet();
      } catch (e) {
        debugPrint(
          'Gallery verification unavailable; keeping saved history: $e',
        );
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      }

      final List<SavedItem> verifiedItems = [];
      for (final item in items) {
        if (existingFileNames.contains(item.fileName)) {
          verifiedItems.add(item);
        } else {
          // Photo was deleted from gallery: remove local cached copy and metadata
          await deleteItem(item);
        }
      }

      // Sort newest to oldest
      verifiedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return verifiedItems;
    } catch (e) {
      debugPrint('Error loading saved items: $e');
      rethrow;
    }
  }

  /// Deletes an item from saved references and cleans its sidecar metadata.
  Future<void> deleteItem(SavedItem item) async {
    try {
      final file = File(item.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      final metaFile = File('${item.filePath}.meta');
      if (await metaFile.exists()) {
        await metaFile.delete();
      }
    } catch (e) {
      debugPrint('Error deleting saved item: $e');
      rethrow;
    }
  }

  /// Deletes all files stored in the saved references directory.
  Future<void> clearSaved() async {
    try {
      final savedDir = await _getSavedDirectory();
      if (await savedDir.exists()) {
        final files = await savedDir.list().toList();
        for (final entity in files) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing saved items: $e');
      rethrow;
    }
  }

  /// Aggregates file-size reductions, not disk space freed.
  int calculateTotalSavedBytes(List<SavedItem> items) {
    int total = 0;
    for (final item in items) {
      total += item.bytesSaved;
    }
    return total;
  }
}
