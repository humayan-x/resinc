import 'dart:io';
import 'dart:math';

/// Utility methods for file size formatting, dates, and filename helpers.
class FileUtils {
  /// Format byte counts into human-readable strings (B, KB, MB, GB).
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1000)).floor();
    final clampedIndex = i.clamp(0, suffixes.length - 1);
    final size = bytes / pow(1000, clampedIndex);
    return '${size.toStringAsFixed(decimals)} ${suffixes[clampedIndex]}';
  }

  /// Calculates percentage reduction between original and compressed sizes.
  static double calculateReductionPercentage(
    int originalBytes,
    int compressedBytes,
  ) {
    if (originalBytes <= 0) return 0.0;
    final reduction = (1.0 - (compressedBytes / originalBytes)) * 100.0;
    return reduction.clamp(0.0, 100.0);
  }

  /// Formats date for saved history display.
  static String formatDate(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  /// Deletes a file safely without throwing uncaught exceptions.
  static Future<void> safeDeleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }
}
