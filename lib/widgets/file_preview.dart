import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Decode for the viewport rather than keeping camera-sized preview bitmaps.
class FilePreview extends StatelessWidget {
  final File file;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double zoomAllowance;

  const FilePreview(
    this.file, {
    super.key,
    this.fit = BoxFit.contain,
    this.errorBuilder,
    this.zoomAllowance = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context);
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : viewport.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : viewport.height;
        // A square bounding box preserves source proportions and bounds even
        // very tall/wide images. Extra detail is available in the zoomable view.
        final edge =
            (math.max(width, height) *
                    MediaQuery.devicePixelRatioOf(context) *
                    zoomAllowance)
                .ceil()
                .clamp(1, 2048);
        return Image(
          image: ResizeImage(
            FileImage(file),
            width: edge,
            height: edge,
            policy: ResizeImagePolicy.fit,
          ),
          fit: fit,
          errorBuilder: errorBuilder,
        );
      },
    );
  }
}
