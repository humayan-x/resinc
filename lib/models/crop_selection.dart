import 'dart:math' as math;
import 'dart:ui';

/// Crop coordinates are normalized against the orientation-corrected image.
class CropSelection {
  static const full = Rect.fromLTWH(0, 0, 1, 1);

  static Rect forRatio(double imageRatio, double? ratio) {
    if (ratio == null) return full;
    final width = math.min(1.0, ratio / imageRatio);
    final height = math.min(1.0, imageRatio / ratio);
    return Rect.fromLTWH((1 - width) / 2, (1 - height) / 2, width, height);
  }

  static Rect move(Rect rect, Offset delta) => Rect.fromLTWH(
    (rect.left + delta.dx).clamp(0.0, 1 - rect.width),
    (rect.top + delta.dy).clamp(0.0, 1 - rect.height),
    rect.width,
    rect.height,
  );

  /// Resize from a corner, with the opposite corner anchored. Ratio is in
  /// normalized coordinates (pixel ratio divided by the image aspect ratio).
  static Rect resize(Rect rect, int corner, Offset point, double? ratio) {
    final left = corner == 0 || corner == 3;
    final top = corner == 0 || corner == 1;
    final anchor = Offset(
      left ? rect.right : rect.left,
      top ? rect.bottom : rect.top,
    );
    final maxW = left ? anchor.dx : 1 - anchor.dx;
    final maxH = top ? anchor.dy : 1 - anchor.dy;
    var width = (left ? anchor.dx - point.dx : point.dx - anchor.dx)
        .clamp(math.min(0.02, maxW), maxW)
        .toDouble();
    var height = (top ? anchor.dy - point.dy : point.dy - anchor.dy)
        .clamp(math.min(0.02, maxH), maxH)
        .toDouble();
    if (ratio != null) {
      width = math.min(
        math.max(width, height * ratio),
        math.min(maxW, maxH * ratio),
      );
      height = width / ratio;
    }
    return Rect.fromLTWH(
      left ? anchor.dx - width : anchor.dx,
      top ? anchor.dy - height : anchor.dy,
      width,
      height,
    );
  }

  static Rect pixelBounds(Rect selection, int width, int height) {
    if (![
          selection.left,
          selection.top,
          selection.right,
          selection.bottom,
        ].every((v) => v.isFinite) ||
        selection.left < -1e-10 ||
        selection.top < -1e-10 ||
        selection.right > 1 + 1e-10 ||
        selection.bottom > 1 + 1e-10 ||
        selection.isEmpty ||
        width < 1 ||
        height < 1) {
      throw ArgumentError('Invalid crop selection.');
    }
    final left = (selection.left * width).floor().clamp(0, width - 1);
    final top = (selection.top * height).floor().clamp(0, height - 1);
    final right = (selection.right * width).ceil().clamp(left + 1, width);
    final bottom = (selection.bottom * height).ceil().clamp(top + 1, height);
    return Rect.fromLTRB(
      left.toDouble(),
      top.toDouble(),
      right.toDouble(),
      bottom.toDouble(),
    );
  }
}
