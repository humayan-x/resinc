import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../models/crop_selection.dart';
import '../../../utils/constants.dart';

class CropImageDialog extends StatefulWidget {
  final String path;
  final Rect initialSelection;
  const CropImageDialog({
    super.key,
    required this.path,
    this.initialSelection = CropSelection.full,
  });

  @override
  State<CropImageDialog> createState() => _CropImageDialogState();
}

class _CropImageDialogState extends State<CropImageDialog> {
  ui.Image? _image;
  String? _error;
  late Rect _selection = widget.initialSelection;
  String _preset = 'Freeform';
  double? _ratio;
  int? _corner;
  Offset? _lastPoint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(widget.path);
      final codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: (w, h) {
          final scale = math.min(1.0, 1600 / math.max(w, h));
          return ui.TargetImageSize(
            width: math.max(1, (w * scale).round()),
            height: math.max(1, (h * scale).round()),
          );
        },
      );
      try {
        final frame = await codec.getNextFrame();
        if (!mounted) {
          frame.image.dispose();
          return;
        }
        setState(() => _image = frame.image);
      } finally {
        codec.dispose();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open this image for cropping.');
      }
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _start(DragStartDetails details, Size size) {
    final point = details.localPosition;
    final corners = [
      _selection.topLeft,
      _selection.topRight,
      _selection.bottomRight,
      _selection.bottomLeft,
    ];
    _corner = null;
    double nearest = 32;
    for (var i = 0; i < corners.length; i++) {
      final distance =
          (Offset(corners[i].dx * size.width, corners[i].dy * size.height) -
                  point)
              .distance;
      if (distance <= nearest) {
        nearest = distance;
        _corner = i;
      }
    }
    final normalized = Offset(point.dx / size.width, point.dy / size.height);
    _lastPoint = _corner != null || _selection.contains(normalized)
        ? normalized
        : null;
  }

  void _update(DragUpdateDetails details, Size size) {
    if (_lastPoint == null) return;
    final point = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    setState(() {
      _selection = _corner == null
          ? CropSelection.move(_selection, point - _lastPoint!)
          : CropSelection.resize(
              _selection,
              _corner!,
              point,
              _ratio == null
                  ? null
                  : _ratio! / (_image!.width / _image!.height),
            );
      _lastPoint = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    final outlineStyle = OutlinedButton.styleFrom(
      foregroundColor: AppConstants.primaryAccent,
      side: const BorderSide(color: AppConstants.primaryAccent),
      shape: buttonShape,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 600,
        height: math.min(720, MediaQuery.sizeOf(context).height * 0.88),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Crop Image', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Drag a corner to resize, or drag inside the grid to move it.',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: image == null
                    ? Center(
                        child: _error == null
                            ? const CircularProgressIndicator()
                            : Text(_error!),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final scale = math.min(
                            constraints.maxWidth / image.width,
                            constraints.maxHeight / image.height,
                          );
                          final size = Size(
                            image.width * scale,
                            image.height * scale,
                          );
                          return Center(
                            child: SizedBox.fromSize(
                              size: size,
                              child: GestureDetector(
                                key: const Key('crop-canvas'),
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (d) => _start(d, size),
                                onPanUpdate: (d) => _update(d, size),
                                onPanEnd: (_) => _lastPoint = null,
                                onPanCancel: () => _lastPoint = null,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    RawImage(image: image, fit: BoxFit.fill),
                                    CustomPaint(
                                      painter: _CropOverlay(_selection),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        <String, double?>{
                              'Freeform': null,
                              '1:1': 1,
                              '4:3': 4 / 3,
                              '3:4': 3 / 4,
                              '16:9': 16 / 9,
                              '9:16': 9 / 16,
                            }.entries
                            .map(
                              (preset) => ChoiceChip(
                                label: Text(preset.key),
                                side: _preset == preset.key
                                    ? BorderSide.none
                                    : const BorderSide(
                                        color: AppConstants.primaryAccent,
                                      ),
                                selected: _preset == preset.key,
                                onSelected: image == null
                                    ? null
                                    : (_) => setState(() {
                                        _preset = preset.key;
                                        _ratio = preset.value;
                                        // Switching to freeform keeps the current framing.
                                        if (_ratio != null) {
                                          _selection = CropSelection.forRatio(
                                            image.width / image.height,
                                            _ratio,
                                          );
                                        }
                                      }),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Tooltip(
                        message: 'Reset crop',
                        child: OutlinedButton(
                          style: outlineStyle,
                          onPressed: image == null
                              ? null
                              : () => setState(() {
                                  _selection = CropSelection.full;
                                  _ratio = null;
                                  _preset = 'Freeform';
                                }),
                          child: const Icon(
                            Icons.restart_alt,
                            semanticLabel: 'Reset crop',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: outlineStyle,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: buttonShape,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          elevation: 0,
                        ),
                        onPressed: image == null
                            ? null
                            : () => Navigator.pop(context, _selection),
                        child: const Text('Apply Crop'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropOverlay extends CustomPainter {
  final Rect selection;
  _CropOverlay(this.selection);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      selection.left * size.width,
      selection.top * size.height,
      selection.right * size.width,
      selection.bottom * size.height,
    );
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(rect);
    canvas.drawPath(shade, Paint()..color = Colors.black54);
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, line);
    for (var i = 1; i < 3; i++) {
      final x = rect.left + rect.width * i / 3;
      final y = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), line);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), line);
    }
    for (final p in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(p, 6, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_CropOverlay oldDelegate) =>
      selection != oldDelegate.selection;
}
